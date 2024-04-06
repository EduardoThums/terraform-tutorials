terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
  profile = "tccc"
}

resource "aws_cloudwatch_event_rule" "console" {
  name        = "capture-aws-sign-in"
  description = "Capture each AWS Console Sign In"

  schedule_expression = "rate(1 minute)"

  # event_pattern = jsonencode({
  #   detail-type = [
  #     "AWS Console Sign In via CloudTrail"
  #   ]
  # })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule = aws_cloudwatch_event_rule.console.name
  #   target_id = "SendToSNS"
  arn = aws_lambda_function.lambda.arn

  depends_on = [aws_cloudwatch_event_rule.console, aws_lambda_function.lambda]
}

# resource "aws_sns_topic" "aws_logins" {
#   name = "aws-console-logins"
# }

# resource "aws_sns_topic_policy" "default" {
#   arn    = aws_sns_topic.aws_logins.arn
#   policy = data.aws_iam_policy_document.sns_topic_policy.json
# }

# data "aws_iam_policy_document" "sns_topic_policy" {
#   statement {
#     effect  = "Allow"
#     actions = ["SNS:Publish"]

#     principals {
#       type        = "Service"
#       identifiers = ["events.amazonaws.com"]
#     }

#     resources = [aws_sns_topic.aws_logins.arn]
#   }
# }

# resource "aws_api_gateway_rest_api" "example" {
#   name = "example"
# }

# resource "aws_api_gateway_resource" "example" {
#   parent_id   = aws_api_gateway_rest_api.example.root_resource_id
#   path_part   = "{proxy+}"
#   rest_api_id = aws_api_gateway_rest_api.example.id
# }

# resource "aws_api_gateway_method" "any" {
#   rest_api_id   = aws_api_gateway_rest_api.example.id
#   resource_id   = aws_api_gateway_resource.example.id
#   http_method   = "ANY"
#   authorization = "NONE"

#   request_parameters = {
#     "method.request.path.proxy" = true
#   }
# }

# resource "aws_api_gateway_integration" "integration" {
#   rest_api_id             = aws_api_gateway_rest_api.example.id
#   resource_id             = aws_api_gateway_resource.example.id
#   http_method             = aws_api_gateway_method.any.http_method
#   integration_http_method = "ANY"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.lambda.invoke_arn
# }

# # Lambda
# resource "aws_lambda_permission" "apigw_lambda" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda.function_name
#   principal     = "apigateway.amazonaws.com"

#   # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
# #   source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
# #   .
#   source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*/{proxy+}"
# }

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "mylambda"
  role          = aws_iam_role.role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.9"

  source_code_hash = filebase64sha256("lambda.zip")
}

# IAM
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

  # statement {
  #   effect = "Allow"

  #   principals {
  #     type        = "Service"
  #     identifiers = ["events.amazonaws.com"]
  #   }

  #   actions = ["lambda:InvokeFunction"]
  # }
}

resource "aws_iam_role" "role" {
  name               = "myrole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.console.arn
  # qualifier     = aws_lambda_alias.test_alias.name
}

# resource "aws_api_gateway_integration" "example" {
#   http_method = aws_api_gateway_method.example.http_method
#   resource_id = aws_api_gateway_resource.example.id
#   rest_api_id = aws_api_gateway_rest_api.example.id
#   type        = "MOCK"
# }

# resource "aws_api_gateway_resource" "example" {
#   parent_id   = aws_api_gateway_rest_api.example.root_resource_id
#   path_part   = "example"
#   rest_api_id = aws_api_gateway_rest_api.example.id
# }

# resource "aws_api_gateway_method" "example" {
#   authorization = "NONE"
#   http_method   = "GET"
#   resource_id   = aws_api_gateway_resource.example.id
#   rest_api_id   = aws_api_gateway_rest_api.example.id
# }

# resource "aws_api_gateway_integration" "example" {
#   http_method = aws_api_gateway_method.example.http_method
#   resource_id = aws_api_gateway_resource.example.id
#   rest_api_id = aws_api_gateway_rest_api.example.id
#   type        = "MOCK"
# }

# resource "aws_api_gateway_deployment" "example" {
#   rest_api_id = aws_api_gateway_rest_api.example.id

#   triggers = {
#     # NOTE: The configuration below will satisfy ordering considerations,
#     #       but not pick up all future REST API changes. More advanced patterns
#     #       are possible, such as using the filesha1() function against the
#     #       Terraform configuration file(s) or removing the .id references to
#     #       calculate a hash against whole resources. Be aware that using whole
#     #       resources will show a difference after the initial implementation.
#     #       It will stabilize to only change when resources change afterwards.
#     redeployment = sha1(jsonencode([
#       aws_api_gateway_resource.example.id,
#       aws_api_gateway_method.example.id,
#       aws_api_gateway_integration.example.id,
#     ]))
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_api_gateway_stage" "example" {
#   deployment_id = aws_api_gateway_deployment.example.id
#   rest_api_id   = aws_api_gateway_rest_api.example.id
#   stage_name    = "example"
# }