# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automating Terraform infrastructure deployment and management.

## Workflows Overview

### terraform-validate.yml
**Trigger:** Pull requests to main/master
**Purpose:** Validates Terraform syntax and formatting
- Runs `terraform fmt -check`
- Runs `terraform init`
- Runs `terraform validate`
- Comments results on PR

### terraform-plan.yml
**Trigger:** Pull requests to main/master
**Purpose:** Creates and displays Terraform execution plan
- Configures AWS credentials
- Runs `terraform plan`
- Comments plan details on PR
- Shows what resources will be created/modified/destroyed

### terraform-apply.yml
**Trigger:** Push to main/master or manual dispatch
**Purpose:** Deploys infrastructure to AWS
- Supports multiple environments (dev, staging, prod)
- Runs `terraform apply` with auto-approve
- Creates GitHub deployment records
- Outputs deployment results

### security-scan.yml
**Trigger:** Push, PR, or weekly schedule
**Purpose:** Comprehensive security scanning
- **TFSec:** Terraform security scanner
- **Checkov:** Policy-as-code scanner
- **Terrascan:** IaC security scanner
- **Trivy:** Vulnerability scanner
- Uploads results to GitHub Security tab

### terraform-destroy.yml
**Trigger:** Manual dispatch only
**Purpose:** Safely destroys infrastructure
- Requires confirmation (type "destroy")
- Environment-specific destruction
- Creates destroy plan before execution
- Logs destruction details

### cost-estimate.yml
**Trigger:** Pull requests
**Purpose:** Estimates infrastructure costs
- Uses Infracost for cost analysis
- Shows cost diff between base and PR
- Comments cost breakdown on PR
- Helps prevent unexpected AWS bills

## Required Secrets

Configure these secrets in your GitHub repository settings:

### AWS Credentials
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

### Terraform State
- `TERRAFORM_STATE_BUCKET`: S3 bucket for state storage

### Cost Estimation (Optional)
- `INFRACOST_API_KEY`: Infracost API key (get free at infracost.io)

## Environment Protection

For production deployments, configure environment protection rules:

1. Go to Settings  Environments
2. Create environments: `dev`, `staging`, `prod`
3. For `prod` environment:
   - Enable required reviewers
   - Add deployment branch restrictions
   - Set wait timer if needed

## Usage Examples

### Manual Deployment
1. Go to Actions tab
2. Select "Terraform Apply" workflow
3. Click "Run workflow"
4. Select environment
5. Click "Run workflow" button

### Manual Destruction
1. Go to Actions tab
2. Select "Terraform Destroy" workflow
3. Click "Run workflow"
4. Select environment
5. Type "destroy" to confirm
6. Click "Run workflow" button

## Workflow Status Badges

Add these badges to your main README:

```markdown
![Terraform Validate](https://github.com/sabiut/terraform-aws-ecs-infra/workflows/Terraform%20Validate/badge.svg)
![Security Scan](https://github.com/sabiut/terraform-aws-ecs-infra/workflows/Security%20Scan/badge.svg)
![Terraform Apply](https://github.com/sabiut/terraform-aws-ecs-infra/workflows/Terraform%20Apply/badge.svg)
```

## Best Practices

1. **Always run plan before apply** - Review changes in PR before merging
2. **Use environment protection** - Require approvals for production
3. **Monitor costs** - Check Infracost reports on PRs
4. **Review security scans** - Address critical issues before deployment
5. **Tag resources** - Ensure proper tagging for cost tracking
6. **Use workspaces** - Separate environments using Terraform workspaces

## Troubleshooting

### Workflow Failures

1. **Authentication errors**: Check AWS credentials in secrets
2. **State lock errors**: Check S3 bucket and DynamoDB table
3. **Plan failures**: Review Terraform syntax and dependencies
4. **Security scan failures**: Review and fix security issues

### Common Issues

- **Missing backend bucket**: Create S3 bucket for state storage first
- **IAM permissions**: Ensure AWS credentials have necessary permissions
- **Cost API key**: Register at infracost.io for free API key

## Contributing

When modifying workflows:
1. Test in a feature branch first
2. Use workflow dispatch for testing
3. Document any new secrets required
4. Update this README with changes