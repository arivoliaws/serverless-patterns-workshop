locals {
  lambda_name = "${var.workshop_stack_base_name}_users_lambda"
  source_dir  = "${path.module}/../src/functions/users"
}

# --- DynamoDB table data source ---
data "aws_dynamodb_table" "users" {
  name = "${var.workshop_stack_base_name}_users"
}

# --- ZIP packaging ---
resource "null_resource" "pip_install" {
  triggers = {
    requirements = filemd5("${local.source_dir}/requirements.txt")
    handler      = filemd5("${local.source_dir}/handler.py")
  }

  provisioner "local-exec" {
    command = "pip install -r ${local.source_dir}/requirements.txt -t ${local.source_dir}/package --upgrade -q"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_users.zip"

  source {
    content  = file("${local.source_dir}/handler.py")
    filename = "handler.py"
  }

  depends_on = [null_resource.pip_install]
}

# --- IAM role ---
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "users_lambda" {
  name               = "${local.lambda_name}_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.users_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "dynamodb_crud" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
    ]
    resources = [data.aws_dynamodb_table.users.arn]
  }
}

resource "aws_iam_role_policy" "dynamodb_crud" {
  name   = "${local.lambda_name}_dynamodb"
  role   = aws_iam_role.users_lambda.id
  policy = data.aws_iam_policy_document.dynamodb_crud.json
}

# --- Lambda function ---
resource "aws_lambda_function" "users" {
  function_name    = local.lambda_name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.10"
  memory_size      = 256
  timeout          = 30
  role             = aws_iam_role.users_lambda.arn

  reserved_concurrent_executions = 10

  dead_letter_config {
    target_arn = aws_sqs_queue.users_dlq.arn
  }

  environment {
    variables = {
      USERS_TABLE_NAME = data.aws_dynamodb_table.users.name
      LOG_LEVEL        = "INFO"
      POWERTOOLS_SERVICE_NAME = local.lambda_name
    }
  }

  tags = {
    Name        = local.lambda_name
    Environment = var.environment
    Project     = var.project
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.dynamodb_crud,
    aws_iam_role_policy.dlq_send,
  ]
}

# --- Dead letter queue for failed invocations ---
resource "aws_sqs_queue" "users_dlq" {
  name                      = "${local.lambda_name}_dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

data "aws_iam_policy_document" "dlq_send" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.users_dlq.arn]
  }
}

resource "aws_iam_role_policy" "dlq_send" {
  name   = "${local.lambda_name}_dlq"
  role   = aws_iam_role.users_lambda.id
  policy = data.aws_iam_policy_document.dlq_send.json
}

# --- Outputs ---
output "users_lambda_arn" {
  value = aws_lambda_function.users.arn
}

output "users_lambda_function_name" {
  value = aws_lambda_function.users.function_name
}

output "users_lambda_invoke_arn" {
  value = aws_lambda_function.users.invoke_arn
}
