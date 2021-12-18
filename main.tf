provider "aws" {
  alias = "central"
  #region = "eu-central-1"
  region = var.replication_region
}

resource "aws_s3_bucket" "s3_default" {
  count = var.create_bucket == true ? 1 : 0

  bucket              = var.bucket_name
  bucket_prefix       = var.bucket_prefix
  force_destroy       = var.force_destroy
  acl                 = var.acl
  acceleration_status = var.acceleration_status
  request_payer       = var.request_payer

  versioning {
    enabled    = var.versioning
    mfa_delete = var.mfa_delete
  }

  # replication_configuration {
  #   role = aws_iam_role.replication_role.arn

  #   rules {
  #     id     = "logs"
  #     prefix = "log"
  #     status = "Enabled"

  #     destination {
  #       bucket = aws_s3_bucket.destination.arn
  #       #storage_class = "STANDARD"
  #       storage_class = "GLACIER"
  #     }
  #   }
  # }
  replication_configuration {
    role = aws_iam_role.replication.arn

    rules {
      id     = "foobar"
      status = "Enabled"

      filter {
        tags = {}
      }
      destination {
        bucket        = aws_s3_bucket.destination.arn
        storage_class = "GLACIER"

        replication_time {
          status  = "Enabled"
          minutes = 15
        }

        metrics {
          status  = "Enabled"
          minutes = 15
        }
      }
    }
  }

  dynamic "website" {
    for_each = length(keys(var.website)) == 0 ? [] : [var.website]

    content {
      index_document = lookup(website.value, "index_document", null)
      error_document = lookup(website.value, "error_document", null)
    }
  }

  dynamic "logging" {
    for_each = length(keys(var.logging)) == 0 ? [] : [var.logging]

    content {
      target_bucket = logging.value.target_bucket
      target_prefix = lookup(logging.value, "target_prefix", null)
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.sse_algorithm
        kms_master_key_id = var.kms_master_key_id
      }
    }
  }

  dynamic "grant" {
    for_each = try(length(var.grants), 0) == 0 || try(length(var.acl), 0) > 0 ? [] : var.grants
    content {
      id          = grant.value.id
      type        = grant.value.type
      permissions = grant.value.permissions
      uri         = grant.value.uri
    }
  }

  dynamic "object_lock_configuration" {
    for_each = var.object_lock_configuration != null ? [1] : []

    content {
      object_lock_enabled = "Enabled"
      rule {
        default_retention {
          mode  = var.object_lock_configuration.mode
          days  = var.object_lock_configuration.days
          years = var.object_lock_configuration.years
        }
      }
    }
  }

  dynamic "cors_rule" {
    for_each = var.cors_rule == null ? [] : var.cors_rule

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }

  lifecycle_rule {
    id      = "transition-to-infrequent-access-storage"
    enabled = var.lifecycle_infrequent_storage_transition_enabled
    prefix  = var.lifecycle_infrequent_storage_object_prefix
    #tags    = module.labels.tags

    transition {
      days          = var.lifecycle_days_to_infrequent_storage_transition
      storage_class = "STANDARD_IA"
    }
  }

  lifecycle_rule {
    id      = "transition-to-glacier"
    enabled = var.lifecycle_glacier_transition_enabled
    prefix  = var.lifecycle_glacier_object_prefix
    #tags    = module.labels.tags


    transition {
      days          = var.lifecycle_days_to_glacier_transition
      storage_class = "GLACIER"
    }
  }

  lifecycle_rule {
    id      = "transition-to-deep-archive"
    enabled = var.lifecycle_deep_archive_transition_enabled
    prefix  = var.lifecycle_deep_archive_object_prefix
    #tags    = module.labels.tags


    transition {
      days          = var.lifecycle_days_to_deep_archive_transition
      storage_class = "DEEP_ARCHIVE"
    }
  }

  lifecycle_rule {
    id      = "expire-objects"
    enabled = var.lifecycle_expiration_enabled
    prefix  = var.lifecycle_expiration_object_prefix
    #tags    = module.labels.tags


    expiration {
      days = var.lifecycle_days_to_expiration
    }
  }

  #tags = module.labels.tags

}

# Module      : S3 BUCKET POLICY
# Description : Terraform module which creates policy for S3 bucket on AWS
resource "aws_s3_bucket_policy" "s3_default" {
  # count = var.create_bucket && var.bucket_policy && var.bucket_enabled == true ? 1 : 0
  count  = var.bucket_policy == true ? 1 : 0
  bucket = join("", aws_s3_bucket.s3_default.*.id)
  policy = var.aws_iam_policy_document

  depends_on = [aws_s3_bucket.s3_default]
}


resource "aws_s3_bucket_public_access_block" "example" {
  bucket = join("", aws_s3_bucket.s3_default.*.id)

  block_public_acls       = var.public_access
  block_public_policy     = var.public_policy
  restrict_public_buckets = var.restrict_public_buckets
  ignore_public_acls      = var.ignore_public_acls

  depends_on = [aws_s3_bucket.s3_default, aws_s3_bucket_policy.s3_policy]
}


resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = join("", aws_s3_bucket.s3_default.*.id)

  depends_on = [aws_s3_bucket.s3_default]

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "MYBUCKETPOLICY"
    Statement = [
      {
        Sid       = "IPAllow"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        "Resource" = [
          #           aws_s3_bucket.s3_default.arn,
          #          "${aws_s3_bucket.s3_default[count.index].arn}/*",
          "${join("", aws_s3_bucket.s3_default.*.arn)}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        "Sid" : "SourceIP",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          #        aws_s3_bucket.s3_default.arn,
          #          "${aws_s3_bucket.s3_default[count.index].id}/*",
          "${join("", aws_s3_bucket.s3_default.*.arn)}/*",
        ],
        "Condition" : {
          "NotIpAddress" : {
            "aws:SourceIp" : [
              "11.11.11.11/32",
              "117.248.69.171/32",
              "117.248.67.2/32",
              "117.202.96.123/32",
              "22.22.22.22/32"
            ]
          }
        },
        "Principal" : "*"
      }
    ]
  })

  # other required fields here
}


# IAM role for replication

# resource "aws_iam_role" "replication_role" {
#   name = "s3-replicationrole-crisil1poc"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "s3.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# POLICY
# }

# # IAM replication policy 

# resource "aws_iam_policy" "replication_policy" {
#   name = "s3-replicationpolicy-crisil1poc"

#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Action" : [
#           "s3:GetReplicationConfiguration",
#           "s3:ListBucket"
#         ],
#         "Effect" : "Allow",
#         "Resource" : [
#           "${join("", aws_s3_bucket.s3_default.*.arn)}/*"
#         ]
#       },
#       {
#         "Action" : [
#           "s3:GetObjectVersionForReplication",
#           "s3:GetObjectVersionAcl",
#           "s3:GetObjectVersionTagging"
#         ],
#         "Effect" : "Allow",
#         "Resource" : [
#           "${join("", aws_s3_bucket.s3_default.*.arn)}/*",
#         ]
#       },
#       {
#         "Action" : [
#           "s3:ReplicateObject",
#           "s3:ReplicateDelete",
#           "s3:ReplicateTags"
#         ],
#         "Effect" : "Allow",
#         "Resource" : "${join("", aws_s3_bucket.s3_default.*.arn)}/*"
#       }
#     ]
#   })
# }

# # POlicy attachemnt

# resource "aws_iam_role_policy_attachment" "replication" {
#   role       = aws_iam_role.replication_role.name
#   policy_arn = aws_iam_policy.replication_policy.arn

#   depends_on = [aws_iam_role.replication_role, aws_iam_policy.replication_policy]
# }
resource "aws_iam_role" "replication" {
  name = "tf-iam-role-replication-141221"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  name = "tf-iam-role-policy-replication-141221"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${join("", aws_s3_bucket.s3_default.*.arn)}/*"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${join("", aws_s3_bucket.s3_default.*.arn)}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.destination.arn}/*"
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}
# replication destination bucket

resource "aws_s3_bucket" "destination" {
  provider      = aws.central
  bucket        = var.replication_destination_bucket
  acl           = "private"
  force_destroy = true
  versioning {
    enabled = true
  }
}
