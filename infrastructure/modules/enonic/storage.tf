resource "aws_s3_bucket" "app_bucket" {
  bucket_prefix = "cbt-enonic-apps-${var.environment}"
  acl           = "private"

  versioning {
     enabled = true
  }

  tags = {
    Name        = "Enonic Apps for ${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ebs_volume" "storage" {
  for_each          = { for az in var.enabled_azs : az => az }
  availability_zone = each.key
  size              = var.storage_size
  tags = {
    Name  = "enonic-es-volume-${var.environment}"
    Group = "enonic-es-volume-${var.environment}"
  }
}
