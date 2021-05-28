resource "aws_kms_key" "zk-kmscmk-code" {
  description             = "KMS CMK for pipe and build"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation     = "true"
  tags                    = {
    Name                  = "${var.name_prefix}-kmscmk-code-${random_string.zk-random.result}"
  }
  policy                  = <<EOF
{
  "Id": "zk-kmscmk-code",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable CodeBuild Use",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "${data.aws_caller_identity.zk-aws-account.account_id}",
          "kms:ViaService": "codebuild.${var.aws_region}.amazonaws.com"
        }
      }
    },
    {
      "Sid": "Enable KMS Manager Use",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_iam_user.zk-kmsmanager.arn}"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_kms_alias" "zk-kmscmk-code-alias" {
  name                    = "alias/${var.name_prefix}-kmscmk-code-${random_string.zk-random.result}"
  target_key_id           = aws_kms_key.zk-kmscmk-code.key_id
}
