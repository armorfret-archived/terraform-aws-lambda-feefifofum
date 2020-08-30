terraform {
  required_providers {
    aws = {
      version = "3.4.0"
    }
  }
}

module "apigw" {
  source  = "armorfret/apigw-lambda/aws"
  version = "0.1.6"

  source_bucket  = "${var.lambda_bucket}"
  source_version = "${var.lambda_version}"
  function_name  = "feefifofum_${var.config_bucket}"

  environment_variables = {
    S3_BUCKET = "${var.config_bucket}"
    S3_KEY    = "config.yaml"
  }

  access_policy_document = "${data.aws_iam_policy_document.lambda_perms.json}"

  hostname = "${var.hostname}"
}

module "publish_user" {
  source         = "armorfret/s3-publish/aws"
  version        = "0.1.1"
  logging_bucket = "${var.logging_bucket}"
  publish_bucket = "${var.data_bucket}"
}

module "config_user" {
  source         = "armorfret/s3-publish/aws"
  version        = "0.1.1"
  logging_bucket = "${var.logging_bucket}"
  publish_bucket = "${var.config_bucket}"
}

resource "aws_sqs_queue" "data_queue" {
  name   = var.data_queue
  policy = data.aws_iam_policy_document.sqs_perms.json
}

data "aws_iam_policy_document" "lambda_perms" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.config_bucket}/*",
      "arn:aws:s3:::${var.config_bucket}",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "arn:aws:s3:::${var.data_bucket}/*",
      "arn:aws:s3:::${var.data_bucket}",
    ]
  }

  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
    ]

    resources = [
      "${aws_sqs_queue.data_queue.arn}",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}


