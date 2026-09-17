## Project Summary

A simple node js application to generate unique quotes

## Run locally

1. Install Node.js 20+.
2. Start the app:

run: npm start

3. Open: http://localhost:3000


## Run with Docker

```bash
docker build -t basic-node-ui-app .
docker run --rm -p 3000:3000 node-ui-app
```

## Deploy with Terraform and GitHub Actions (AWS ECR and Ubuntu EC2)

1. Open the Terraform folder:

```bash
cd terraform
```

2. Initialize Terraform:

```bash
terraform init
```

3. Copy vars file and update values if needed:

```bash
cp terraform.tfvars.example terraform.tfvars
```

4. Apply infrastructure:

```bash
terraform apply
```

5. Get outputs:

```bash
terraform output
```

The Terraform configuration creates an ECR repository and an Ubuntu EC2 instance in a
new VPC. The instance installs Docker, receives read-only ECR and SSM permissions, and
has a deployment script at `/usr/local/bin/deploy-app`.

Set `key_name` to an existing EC2 key pair and replace `allowed_ssh_cidr` with your
public IP range before enabling SSH access.

The `main` branch GitHub Actions workflow performs the deployment automatically. Add
the AWS IAM role ARN to the repository secret `AWS_DEPLOY_ROLE_ARN`. That role must
trust GitHub's OIDC provider and allow Terraform to manage the infrastructure, ECR
image push operations, and SSM commands. Each push builds an image tagged with its
commit SHA, pushes it to ECR, and uses SSM to pull and restart the container on EC2.