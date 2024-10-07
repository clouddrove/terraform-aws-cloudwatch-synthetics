# Managed By : CloudDrove
# Description : This Script is used to create Cloudwatch Alarms.
# Copyright @ CloudDrove. All Right Reserved.

#Module      : Label
#Description : This terraform module is designed to generate consistent label names and tags
#              for resources. You can use terraform-labels to implement a strict naming
#              convention.
module "labels" {
  source  = "clouddrove/labels/aws"
  version = "1.3.0"

  name        = var.name
  environment = var.environment
  repository  = var.repository
  managedby   = var.managedby
  label_order = var.label_order
}

#Module      : CLOUDWATCH SYNTHETIC CANARY
#Description : Terraform module creates Cloudwatch Synthetic canaries on AWS for monitoriing Websites.

locals {
  file_content = { for k, v in var.endpoints :
    k => templatefile("${path.module}/canary-lambda.js.tpl", {
      endpoint = v.url
    })
  }
}

data "archive_file" "canary_archive_file" {
  for_each    = var.endpoints
  type        = "zip"
  output_path = "/tmp/${each.key}-${md5(local.file_content[each.key])}.zip"

  source {
    content  = local.file_content[each.key]
    filename = "nodejs/node_modules/pageLoadBlueprint.js"
  }
}

resource "aws_synthetics_canary" "canary" {
  for_each             = var.endpoints
  name                 = each.key
  artifact_s3_location = "s3://${var.s3_artifact_bucket}/${each.key}"
  execution_role_arn   = aws_iam_role.canary_role.arn
  handler              = "pageLoadBlueprint.handler"
  zip_file             = "/tmp/${each.key}-${md5(local.file_content[each.key])}.zip"
  runtime_version      = "syn-nodejs-puppeteer-6.1"
  start_canary         = true
  tags                 = module.labels.tags

  schedule {
    expression = var.schedule_expression
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  depends_on = [data.archive_file.canary_archive_file, aws_iam_role_policy_attachment.canary_role_policy]
}

#Module      : IAM ROLE FOR AWS SYNTHETIC CANARY
#Description : Terraform module creates IAM Role for Cloudwatch Synthetic canaries on AWS for monitoriing Websites.

resource "aws_iam_policy" "canary_policy" {
  name        = "canary-policy"
  description = "Policy for canary"
  policy      = data.aws_iam_policy_document.canary_permissions.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "canary_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_artifact_bucket}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_artifact_bucket}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/cwsyn-*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "xray:PutTraceSegments"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "cloudwatch:PutMetricData"
    ]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values = [
        "CloudWatchSynthetics"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "canary_role" {
  name               = "CloudWatchSyntheticsRole"
  assume_role_policy = data.aws_iam_policy_document.canary_assume_role.json
}

data "aws_iam_policy_document" "canary_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "canary_role_policy" {
  role       = aws_iam_role.canary_role.name
  policy_arn = aws_iam_policy.canary_policy.arn
}

#Module      : CLOUDWATCH ALARM FOR AWS SYNTHETIC CANARY
#Description : Terraform module creates Cloudwatch Alarm for Cloudwatch Synthetic canaries on AWS for monitoriing Websites.

resource "aws_cloudwatch_metric_alarm" "canary_alarm" {
  for_each = var.endpoints

  alarm_name          = "${each.key}-canary-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Failed"
  namespace           = "CloudWatchSynthetics"
  period              = "60" # 1 minute
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"

  dimensions = {
    CanaryName = aws_synthetics_canary.canary[each.key].name
  }

  alarm_description = "Canary alarm for ${each.key}"

  alarm_actions = [
    aws_sns_topic.canary_alarm.arn
  ]
}

resource "aws_sns_topic" "canary_alarm" {
  name = "dev-xcheck-api-canary-alarm"
}

resource "aws_sns_topic_subscription" "canary_alarm" {
  topic_arn = aws_sns_topic.canary_alarm.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
