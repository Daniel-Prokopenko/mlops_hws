terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  validate_zip    = "${path.module}/lambda/validate.zip"
  log_metrics_zip = "${path.module}/lambda/log_metrics.zip"
}

# IAM for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda functions
resource "aws_lambda_function" "validate" {
  function_name = "${var.project_name}-validate"
  role          = aws_iam_role.lambda_role.arn
  handler       = "validate.lambda_handler"
  runtime       = "python3.11"

  filename         = local.validate_zip
  source_code_hash = filebase64sha256(local.validate_zip)
}

resource "aws_lambda_function" "log_metrics" {
  function_name = "${var.project_name}-log-metrics"
  role          = aws_iam_role.lambda_role.arn
  handler       = "log_metrics.lambda_handler"
  runtime       = "python3.11"

  filename         = local.log_metrics_zip
  source_code_hash = filebase64sha256(local.log_metrics_zip)
}

# IAM for Step Functions
resource "aws_iam_role" "sfn_role" {
  name = "${var.project_name}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "sfn_invoke_lambda" {
  name = "${var.project_name}-sfn-invoke-lambda"
  role = aws_iam_role.sfn_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = [
        aws_lambda_function.validate.arn,
        aws_lambda_function.log_metrics.arn
      ]
    }]
  })
}

# Step Function: Validate -> LogMetrics
resource "aws_sfn_state_machine" "train_pipeline" {
  name     = "${var.project_name}-train-pipeline"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    Comment = "Training pipeline (validate -> log metrics)"
    StartAt = "ValidateData"
    States = {
      ValidateData = {
        Type     = "Task"
        Resource = aws_lambda_function.validate.arn
        Next     = "LogMetrics"
      }
      LogMetrics = {
        Type     = "Task"
        Resource = aws_lambda_function.log_metrics.arn
        End      = true
      }
    }
  })
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.train_pipeline.arn
}
