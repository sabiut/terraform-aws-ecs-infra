# Production. Setting environment = "prod" also turns on RDS deletion
# protection and a final snapshot on destroy.
#
# Fill in the certificate and alarm address before the first production apply:
# without them the site serves plain HTTP and alarms notify nobody.
environment = "prod"

frontend_cpu           = 512
frontend_memory        = 1024
backend_cpu            = 512
backend_memory         = 1024
frontend_desired_count = 2
backend_desired_count  = 2
log_retention_days     = 90

db_instance_class = "db.t3.small"
db_multi_az       = true

# certificate_arn           = "arn:aws:acm:ap-southeast-2:123456789012:certificate/..."
# alarm_email               = "ops@example.com"
# test_listener_cidr_blocks = ["203.0.113.0/24"]
