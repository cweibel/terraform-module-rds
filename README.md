# terraform-module-rds
Terraform Create RDS Databases for All BOSH Directors, CF, and others

Inputs - Required:

 - `rds_instance_name` - Name Prefix and Name Tag value, do not end with hyphen, ex "mgmt-bosh"
 - `resource_tags` - AWS tags to apply to resources
 - `rds_security_group_id` - RDS Security Group created with the name db-access-postgress
 - `kms_rds_key_by_arn_arn` - KMS key to encrypt the db with, uses the */EBS_Default named one
 - `rds_db_subnet_group_name` - Subnets with the tag apps-aws-managed*

Inputs - Optional: 

 - `allocated_storage` - Starting size in GB for the RDS instance
 - `max_allocated_storage` - Maximum size in GB for the RDS instance
 - `engine_version` - db engine version, ex "14.1"
 - `instance_class` - db instance size, ex "db.m5.large"
 - `deletion_protection` - makes it harder to accidentally delete the RDS instance, default is "true"
 - `multi_az` - whether to enable multi AZ support, default is "false"
 - `engine_version` - db engine version, ex "14.1"
 - `rds_family` - Needs to match the engine version, default is "postgres14"


Outputs:
 - `rds_db_instance_dbuser` - Username suffix for the RDS Instance
 - `rds_db_instance_dbpass` - Password suffix for the RDS Instance
 - `rds_db_instance_dbhost` - Host name for the RDS Instance
