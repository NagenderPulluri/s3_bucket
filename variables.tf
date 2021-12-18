#Module      : LABEL
#Description : Terraform label module variables.
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

/*
variable "repository" {
  type        = string
  default     = ""
  description = "Terraform current module repo"
}
*/

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "label_order" {
  type        = list(any)
  default     = []
  description = "Label order, e.g. `name`,`application`."
}

variable "managedby" {
  type        = string
  default     = "CRISIL cloud automation"
  description = "ManagedBy Cloud Champions."
}

variable "attributes" {
  type        = list(any)
  default     = []
  description = "Additional attributes (e.g. `1`)."
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `organization`, `environment`, `name` and `attributes`."
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`CRISIL`)."
}

# Module      : S3 BUCKET
# Description : Terraform S3 Bucket module variables.
variable "create_bucket" {
  type        = bool
  default     = true
  description = "Conditionally create S3 bucket."
}

variable "bucket_name" {
  type = string
  #default     = true
  description = "Conditionally create S3 bucket."
  default     = ""
}

variable "bucket_ssl_policy" {
  type    = string
  default = ""

}

variable "versioning" {
  type        = bool
  default     = false
  description = "Enable Versioning of S3."
}

variable "acl" {
  type        = string
  default     = "private"
  description = "Canned ACL to apply to the S3 bucket."
}

variable "mfa_delete" {
  type        = bool
  default     = false
  description = "Enable MFA delete for either Change the versioning state of your bucket or Permanently delete an object version."
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "The server-side encryption algorithm to use. Valid values are AES256 and aws:kms."
}

variable "kms_master_key_id" {
  type        = string
  default     = ""
  description = "The AWS KMS master key ID used for the SSE-KMS encryption. This can only be used when you set the value of sse_algorithm as aws:kms. The default aws/s3 AWS KMS master key is used if this element is absent while the sse_algorithm is aws:kms."
}

variable "lifecycle_infrequent_storage_transition_enabled" {
  type        = bool
  default     = false
  description = "Specifies infrequent storage transition lifecycle rule status."
}

variable "lifecycle_infrequent_storage_object_prefix" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Object key prefix identifying one or more objects to which the lifecycle rule applies."
}

variable "lifecycle_days_to_infrequent_storage_transition" {
  type        = number
  default     = 60
  description = "Specifies the number of days after object creation when it will be moved to standard infrequent access storage."
}

variable "lifecycle_glacier_transition_enabled" {
  type        = bool
  default     = false
  description = "Specifies Glacier transition lifecycle rule status."
}

variable "lifecycle_glacier_object_prefix" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Object key prefix identifying one or more objects to which the lifecycle rule applies."
}

variable "lifecycle_days_to_deep_archive_transition" {
  type        = number
  default     = 180
  description = "Specifies the number of days after object creation when it will be moved to DEEP ARCHIVE ."
}

variable "lifecycle_deep_archive_transition_enabled" {
  type        = bool
  default     = false
  description = "Specifies DEEP ARCHIVE transition lifecycle rule status."
}

variable "lifecycle_deep_archive_object_prefix" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Object key prefix identifying one or more objects to which the lifecycle rule applies."
}

variable "lifecycle_days_to_glacier_transition" {
  type        = number
  default     = 180
  description = "Specifies the number of days after object creation when it will be moved to Glacier storage."
}

variable "lifecycle_expiration_enabled" {
  type        = bool
  default     = false
  description = "Specifies expiration lifecycle rule status."
}

variable "lifecycle_expiration_object_prefix" {
  type        = string
  default     = ""
  description = "Object key prefix identifying one or more objects to which the lifecycle rule applies."
}

variable "lifecycle_days_to_expiration" {
  type        = number
  default     = 365
  description = "Specifies the number of days after object creation when the object expires."
}

# Module      : S3 BUCKET POLICY
# Description : Terraform S3 Bucket Policy module variables.
variable "aws_iam_policy_document" {
  type        = string
  default     = ""
  sensitive   = true
  description = "aws iam policy document"
}

variable "bucket_policy" {
  type        = bool
  default     = false
  description = "Conditionally create S3 bucket policy."
}

variable "public_access" {
  type        = bool
  default     = true
  description = "public access."
}

variable "restrict_public_buckets" {
  type        = bool
  default     = true
  description = "restrict public buckets."
}

variable "ignore_public_acls" {
  type        = bool
  default     = true
  description = "ignore public acls."
}

variable "public_policy" {
  type        = bool
  default     = true
  description = "Conditionally create S3 bucket policy."
}

variable "force_destroy" {
  type        = bool
  default     = true
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable."
}

variable "bucket_prefix" {
  type        = string
  default     = null
  description = " (Optional, Forces new resource) Creates a unique bucket name beginning with the specified prefix."
}

variable "grants" {
  type = list(object({
    type        = string
    permissions = list(string)
    uri         = string
  }))
  default     = null
  description = "ACL Policy grant.conflict with acl.set acl null to use this"
}

variable "website" {
  type = map(string)
  default = {
    index_document : "index.html"
    error_document : "error.html"
  }
  description = "Static website configuration"

}

variable "logging" {
  type        = map(string)
  default     = {}
  description = "Logging Object Configuration details"
}

variable "acceleration_status" {
  type        = string
  default     = null
  description = "Sets the accelerate configuration of an existing bucket. Can be Enabled or Suspended"
}

variable "request_payer" {
  type        = string
  default     = null
  description = "Specifies who should bear the cost of Amazon S3 data transfer. Can be either BucketOwner or Requester. By default, the owner of the S3 bucket would incur the costs of any data transfer"
}

variable "object_lock_configuration" {
  type = object({
    mode = string
    #Valid values are GOVERNANCE and COMPLIANCE
    days  = number
    years = number
  })
  default     = null
  description = "With S3 Object Lock, you can store objects using a write-once-read-many (WORM) model. Object Lock can help prevent objects from being deleted or overwritten for a fixed amount of time or indefinitely."

}

variable "cors_rule" {
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default     = null
  description = "CORS Configuration specification for this bucket"
}


variable "replication_destination_bucket" {
  type = string
}


variable "replication_region" {
  type = string
}
