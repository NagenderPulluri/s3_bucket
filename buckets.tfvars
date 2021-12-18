bucket_name                    = "nagender-bucket-cloud-14122021"
replication_destination_bucket = "replication-14122021"
replication_region             = "eu-central-1"
versioning                     = true
acl                            = "private"
public_access                  = false
public_policy                  = false #Block public access - true= blocks ; false= allows
restrict_public_buckets        = false
ignore_public_acls             = false
mfa_delete                     = false
sse_algorithm                  = "AES256"
kms_master_key_id              = ""
aws_iam_policy_document        = ""
bucket_policy                  = false
force_destroy                  = true
bucket_prefix                  = null
#grants = null
/* grants = [
   {
    type        = "Group"
    permissions = ["READ_ACP", "WRITE"]
    uri         = "http://acs.amazonaws.com/groups/s3/LogDelivery"
  }
  ] */
website = {
  index_document : "index.html"
  error_document : "error.html"
}
logging = {
  target_bucket : "cloud-pratice-final1"
  target_prefix : "logs/"
}
acceleration_status       = null
object_lock_configuration = null
# object_lock_configuration = {
#   mode  = "GOVERNANCE"
#   days  = 366
#   years = null
# }
#cors_rule = null
cors_rule = [
  {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["https://s3-website-test.hashicorp.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
]



