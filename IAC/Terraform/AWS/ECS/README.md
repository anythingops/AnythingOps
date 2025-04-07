# Terraform ECS Infrastructure

This repository contains Terraform modules for deploying a production-ready ECS infrastructure on AWS.

## Architecture Overview

The infrastructure consists of the following components:

1. **Network Layer** (`/modules/network`)
   - VPC with public and private subnets
   - NAT Gateway for private subnet access
   - Security groups for ALB and ECS

2. **Container Registry** (`/modules/ecr`)
   - ECR repository for storing container images
   - Lifecycle policies for image management

3. **Load Balancer** (`/modules/alb`)
   - Application Load Balancer
   - HTTPS listener with SSL/TLS support
   - Target groups for container routing
   - Security groups for ALB

4. **Auto Scaling** (`/modules/asg`)
   - Launch template for EC2 instances
   - Auto Scaling Group for ECS container instances

5. **Container Service** (`/modules/ecs`)
   - ECS cluster
   - Task definitions
   - Service configuration
   - Capacity provider integration

6. **IAM Roles** (`/modules/iam`)
   - ECS task execution roles
   - EC2 instance roles
   - Required policies and profiles

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform v1.0.0 or newer
- Docker installed (for container builds)
- Valid SSL certificate in AWS Certificate Manager (for HTTPS)

## Quick Start

1. Clone the repository:
```bash
git clone <repository-url>
cd terraform-ecs
```

2. Initialize Terraform:
```bash
terraform init
```

3. Configure your variables in `terraform.tfvars`:
```hcl
project_name = "your-project"
environment  = "prod"
region       = "ap-south-1"

vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets    = ["10.0.3.0/24", "10.0.4.0/24"]

domain_name     = "your-domain.com"
certificate_arn = "arn:aws:acm:region:account:certificate/xxx"

instance_type   = "t3.medium"
```

4. Review and apply the configuration:
```bash
terraform plan
terraform apply
```

## Module Dependencies

```
network --> alb
   |
   |--> iam --> asg --> ecs
   |
   |--> ecr ----^
```

## Security Features

- Private subnets for ECS tasks
- HTTPS only on ALB
- IAM roles with least privilege
- Security groups with minimal access
- Immutable ECR tags
- Auto container scanning

## Monitoring & Logging

- CloudWatch Logs for containers
- Container health checks
- ALB access logs
- Auto Scaling metrics

## Cost Optimization

- Auto Scaling based on demand
- NAT Gateway sharing
- ECR image lifecycle policies
- Spot instance support (optional)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.