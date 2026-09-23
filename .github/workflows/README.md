# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automating Terraform infrastructure deployment and management.

## Workflows Overview

### terraform-validate.yml
**Trigger:** Pull requests to main/master touching `terraform/` or `terraform-backend/`
**Purpose:** Validates Terraform syntax and formatting in both roots
- Runs `terraform fmt -check -recursive`; a formatting difference fails the job
- Runs `terraform init -lockfile=readonly`; a stale `.terraform.lock.hcl` fails the job
- Runs `terraform validate`
- Writes a per-root summary to the job page

### terraform-plan.yml
**Trigger:** Pull requests to main/master
**Purpose:** Creates and displays Terraform execution plan
- Assumes the OIDC role and selects the `dev` workspace with `environments/dev.tfvars`
- Runs `terraform plan` and prints the plan in the job log
- Writes a status line to the job summary
- Skips the plan (and says so) when `AWS_ROLE_ARN` is not configured

### terraform-apply.yml
**Trigger:** Push to main/master or manual dispatch
**Purpose:** Deploys infrastructure to AWS
- Supports multiple environments (dev, staging, prod), each applied with its committed `terraform/environments/<name>.tfvars`
- Runs `terraform apply` with auto-approve
- Creates a GitHub deployment record pointing at the ALB URL
- Writes non-sensitive outputs to the job summary
- One apply or destroy runs at a time per environment (concurrency group `terraform-<environment>`)

### terraform-destroy.yml
**Trigger:** Manual dispatch only
**Purpose:** Safely destroys infrastructure
- Requires confirmation (type "destroy")
- Environment-specific destruction
- Creates destroy plan before execution
- Logs destruction details

## Environment Variable Files

Each workspace is applied, planned and destroyed with `terraform/environments/<name>.tfvars`, which sets `environment` and the sizing for that environment (task size and count, log retention, database class and Multi-AZ). Without these files every workspace would apply the development defaults from `variables.tf`, including prod.

The files hold no secrets. Account-specific values such as `certificate_arn`, `alarm_email` and `test_listener_cidr_blocks` are commented out in each file; fill them in for the account the workflows deploy to. Production should not be applied until `prod.tfvars` has a certificate and an alarm address.

## Provider Lock Files

Both `terraform/` and `terraform-backend/` commit `.terraform.lock.hcl` with checksums for `linux_amd64`, `darwin_amd64` and `darwin_arm64`. CI runs `terraform init -lockfile=readonly`, so a provider version change must be made deliberately:

```bash
cd terraform
terraform init -upgrade
terraform providers lock -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64
git add .terraform.lock.hcl
```

## Required Secrets

Configure these secrets in your GitHub repository settings:

### AWS Credentials
- `AWS_ROLE_ARN`: ARN of an IAM role that GitHub Actions assumes through OpenID Connect (OIDC). No long-lived access keys are stored in GitHub.

The workflows request an OIDC token (`permissions: id-token: write`) and exchange it for short-lived credentials with `aws-actions/configure-aws-credentials`. To set this up once per AWS account:

1. Create the GitHub OIDC identity provider in IAM if the account does not have one yet. Provider URL `https://token.actions.githubusercontent.com`, audience `sts.amazonaws.com`. The [aws-ecs-cicd-pipeline](https://github.com/sabiut/aws-ecs-cicd-pipeline) repository already creates this provider; reuse it rather than creating a second one.
2. Create an IAM role with this trust policy, replacing the account ID and repository:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:sabiut/terraform-aws-ecs-infra:*"
           }
         }
       }
     ]
   }
   ```

   Tighten the `sub` condition to `repo:sabiut/terraform-aws-ecs-infra:ref:refs/heads/master` or `repo:...:environment:prod` if the role should only be assumable from the default branch or a protected environment.
3. Attach permissions for the resources Terraform manages (VPC, EC2, ELB, ECS, RDS, IAM, Secrets Manager, CloudWatch Logs) plus read/write on the state bucket and the DynamoDB lock table.
4. Save the role ARN as the `AWS_ROLE_ARN` repository secret.

### Terraform State
- `TERRAFORM_STATE_BUCKET`: S3 bucket for state storage
- `TERRAFORM_LOCK_TABLE` (optional): DynamoDB table for state locking; defaults to `terraform-state-locks`, the name the `terraform-backend` project creates

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
3. **Confirm alarm subscriptions** - Click the link in the SNS email after setting `alarm_email`, or alarms will fire silently
4. **Tag resources** - Ensure proper tagging for cost tracking
5. **Use workspaces** - Separate environments using Terraform workspaces

## Troubleshooting

### Workflow Failures

1. **Authentication errors**: Check that `AWS_ROLE_ARN` is set and the role's trust policy allows this repository
2. **State lock errors**: Check S3 bucket and DynamoDB table; a run queued behind another in the same concurrency group is normal
3. **Plan failures**: Review Terraform syntax and dependencies
4. **Lock file errors**: A provider version changed; update `.terraform.lock.hcl` as described under Provider Lock Files

### Common Issues

- **Missing backend bucket**: Create S3 bucket for state storage first
- **IAM permissions**: Ensure AWS credentials have necessary permissions

## Contributing

When modifying workflows:
1. Test in a feature branch first
2. Use workflow dispatch for testing
3. Document any new secrets required
4. Update this README with changes