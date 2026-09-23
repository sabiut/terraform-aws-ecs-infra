# Development. Applied by the Terraform workflows for the dev workspace and
# usable locally with: terraform plan -var-file=environments/dev.tfvars
#
# Account-specific values (certificate ARN, alarm email, allowed test CIDRs)
# are deliberately absent; put them in an ignored terraform.tfvars locally or
# add them here once the account is known.
environment = "dev"

frontend_cpu           = 256
frontend_memory        = 512
backend_cpu            = 256
backend_memory         = 512
frontend_desired_count = 1
backend_desired_count  = 1
log_retention_days     = 7

db_instance_class = "db.t3.micro"
db_multi_az       = false

# test_listener_cidr_blocks = ["203.0.113.0/24"]
