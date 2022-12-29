## Variables

variable rds_instance_name          {} # Name Prefix and Name Tag value, do not end with hyphen  (required)
variable resource_tags              {} # AWS tags to apply to resources                          (required)
variable rds_security_group_id      {} # RDS Security Group                                      (required)
variable kms_rds_key_by_arn_arn     {} # KMS key to encrypt the db with                          (required)
variable rds_db_subnet_group_name   {} # RDS Subnet group name                                   (required)

variable allocated_storage          { default = 20 }
variable max_allocated_storage      { default = 100 }
variable deletion_protection        { default = true }
variable multi_az                   { default = false }
variable engine_version             { default = "14.1" }
variable rds_family {
  type        = string
  default     = "postgres14"
  description = "Needs to match the engine version"
}
variable instance_class             { default = "db.m5.large" }

################################################################################
# DB randomized creds
################################################################################
# Create Randomized User/Pass for the RDS instance
# NOTE: First character must be a letter
################################################################################
resource "random_string" "master-db-user-name" {
  length = 16
  special = false
}
resource "random_string" "master-db-password" {
  length = 32
  special = false
  min_special = 0
  min_upper = 5
  min_numeric = 5
  min_lower = 5
}

################################################################################
# RDS Postgres 
################################################################################
resource "aws_db_instance" "rds-db-instance" {
  allocated_storage          = var.allocated_storage
  max_allocated_storage      = var.max_allocated_storage
  storage_type               = "gp2" # NOTE: gp3 isn't supported
  engine                     = "postgres"
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  identifier_prefix          = "${var.rds_instance_name}-"
  db_name                    = "master"
  username                   = "u${random_string.master-db-user-name.result}"
  password                   = "p${random_string.master-db-password.result}"
  db_subnet_group_name       = var.rds_db_subnet_group_name
  vpc_security_group_ids     = ["${var.rds_security_group_id}"]
  auto_minor_version_upgrade = true #Required by Sentinel
  deletion_protection        = var.deletion_protection  
  backup_retention_period    = 15   #Required by Sentinel, required to be value=15
  skip_final_snapshot        = true
  kms_key_id                 = var.kms_rds_key_by_arn_arn
  storage_encrypted          = true
  multi_az                   = var.multi_az
  
  # Snapshot configuration
  backup_window = "10:00 - 11:00"

  # Copy tags to backup snapshots and retain backups even after the instance has been deleted.
  copy_tags_to_snapshot     = true
  delete_automated_backups  = false
  
  parameter_group_name      = aws_db_parameter_group.force_ssl.name
  
  lifecycle {
    ignore_changes = [ engine_verison ]
  }
  
  tags                       = merge({Name = "${var.rds_instance_name}"}, var.resource_tags )
}


resource "aws_db_parameter_group" "force_ssl" {
  name        = "${var.rds_instance_name}-force-ssl-parameter-group"
  description = "${var.rds_instance_name} Force SSL Parameter Group"
  family      = var.rds_family
  
  parameter {
    name  = "rds.force_ssl"
    value = 1
  }
}


################################################################################
# Output creds for storing in Vault
################################################################################
output "rds_db_instance_dbuser" {value = random_string.master-db-user-name.result }
output "rds_db_instance_dbpass" {value = random_string.master-db-password.result }
output "rds_db_instance_dbhost" {value = aws_db_instance.rds-db-instance.address }


