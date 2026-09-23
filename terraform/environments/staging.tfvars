# Staging. Production task size on a single task per tier and a single-AZ
# database, so a release is exercised at production shape without the cost.
environment = "staging"

frontend_cpu           = 512
frontend_memory        = 1024
backend_cpu            = 512
backend_memory         = 1024
frontend_desired_count = 1
backend_desired_count  = 1
log_retention_days     = 30

db_instance_class = "db.t3.small"
db_multi_az       = false

# certificate_arn           = "arn:aws:acm:ap-southeast-2:123456789012:certificate/..."
# alarm_email               = "ops@example.com"
# test_listener_cidr_blocks = ["203.0.113.0/24"]
