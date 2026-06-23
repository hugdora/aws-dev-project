# 🌐 Host a Dynamic Web Application on AWS with Terraform & EC2

> **Live site:** [https://www.dorasws.org](https://www.dorasws.org)  
> **GitHub:** [hugdora/aws-dev-project](https://github.com/hugdora/aws-dev-project)

A fully automated infrastructure-as-code project that provisions and deploys a dynamic Laravel/PHP web application on AWS using Terraform. The infrastructure includes a custom VPC, Auto Scaling Group, Application Load Balancer, RDS MySQL database, ACM SSL certificate, Route 53 DNS, and AWS Secrets Manager, all managed through Terraform.

---

## 📐 Architecture Overview

```
Internet
    │
    ▼
Route 53 (DNS)
    │
    ▼
ACM Certificate (HTTPS)
    │
    ▼
Application Load Balancer (ALB)
    │  ┌─────────────────────────────────┐
    │  │         Public Subnets          │
    │  │   AZ1              AZ2          │
    │  └─────────────────────────────────┘
    │
    ▼
Auto Scaling Group (EC2 instances)
    │  ┌─────────────────────────────────┐
    │  │        Private App Subnets      │
    │  │   AZ1              AZ2          │
    │  └─────────────────────────────────┘
    │
    ▼
RDS MySQL (Private DB Subnet)
    │
NAT Gateway → Internet (outbound only)
```

---

## 🏗️ Infrastructure Components

| Resource | Description |
|---|---|
| **VPC** | Custom VPC with public, private app, and private DB subnets across 2 AZs |
| **NAT Gateway** | Allows private instances to reach the internet for updates/installs |
| **Security Groups** | Separate SGs for ALB, EC2, RDS, EICE, and DB migration server |
| **EC2 Instance Connect Endpoint (EICE)** | Secure SSH access to private EC2 instances without a bastion host |
| **ACM Certificate** | SSL/TLS certificate for HTTPS with DNS validation |
| **Application Load Balancer** | HTTP → HTTPS redirect, forwards to target group |
| **Auto Scaling Group** | Maintains desired EC2 capacity, replaces unhealthy instances |
| **RDS MySQL** | Managed relational database in private subnet |
| **AWS Secrets Manager** | Stores database credentials securely |
| **IAM Role & Instance Profile** | Grants EC2 instances access to S3 and Secrets Manager |
| **Route 53** | DNS A record pointing domain to ALB |
| **SNS** | Notifications for ASG scaling events |
| **S3 + DynamoDB** | Remote Terraform state storage and state locking |

---

## 📁 Project Structure

```
terraform-folder/nest-app/
├── acm.tf                        # ACM SSL certificate
├── alb.tf                        # Load balancer, target group, listeners
├── asg.tf                        # Launch template & Auto Scaling Group
├── backend.tf                    # Remote state (S3 + DynamoDB)
├── db-migrate-server.tf          # EC2 instance for DB migrations
├── ec2-profile-role.tf           # IAM role and instance profile
├── eice.tf                       # EC2 Instance Connect Endpoint
├── nat-gateway.tf                # NAT Gateway and Elastic IP
├── outputs.tf                    # Output values (VPC ID, website URL)
├── providers.tf                  # AWS provider configuration
├── rds.tf                        # RDS MySQL instance
├── route-53.tf                   # DNS record
├── secrets_manager.tf            # Secrets Manager configuration
├── security-group.tf             # All security groups
├── sns.tf                        # SNS topic for ASG notifications
├── variables.tf                  # Variable declarations
├── vpc.tf                        # VPC, subnets, IGW, route tables
├── terraform.tfvars              # Variable values (gitignored)
├── deployment-script.sh.tpl      # EC2 user data deployment script
└── db-migrate-script.sh.tpl      # Database migration script
```

---

## 🚀 Deployment

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- AWS CLI configured with appropriate permissions
- An S3 bucket and DynamoDB table for remote state
- A registered domain in Route 53

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/hugdora/aws-dev-project.git
cd aws-dev-project/terraform-folder/nest-app
```

**2. Create a `terraform.tfvars` file** (not committed — see `.gitignore`)
```hcl
region                       = "eu-west-2"
project_name                 = "nest"
environment                  = "dev"
vpc_cidr                     = "10.0.0.0/16"
domain_name                  = "dorasws.org"
record_name                  = "www"
alternative_names            = ["*.dorasws.org"]
ec2_instance_type            = "t2.micro"
health_check_path            = "/"
# ... other variables
```

**3. Initialise and apply**
```bash
terraform init
terraform validate
terraform plan
terraform apply
```

---

## 🔒 Security

- All EC2 instances are in **private subnets** - no public IP
- SSH access only via **EC2 Instance Connect Endpoint** (no bastion host needed)
- Database credentials stored in **AWS Secrets Manager**, not in code
- ALB enforces **HTTPS** : HTTP requests are redirected (301)
- Security groups follow **least privilege**: each resource only allows traffic from its expected source
- `terraform.tfvars` and `*.tfstate` are excluded from version control via `.gitignore`

---

## ⚠️ Issues Encountered & Fixes

| Issue | Fix |
|---|---|
| `subject_alternative_names` expected `set(string)`, received `string` | Changed variable type to `set(string)` and value to `["*.dorasws.org"]` |
| VPC ID and IAM role name passed as quoted strings | Removed quotes so Terraform resolves them as references |
| RDS password contained invalid characters (`/`, `@`) | Updated password to use only printable ASCII excluding those characters |
| SSL policy name typo `EBSecurityPolicy` | Corrected to `ELBSecurityPolicy-TLS13-1-2-2021-06` |
| EC2 instances in ASG had ALB security group instead of app server SG | Fixed `vpc_security_group_ids` in launch template |
| `templatefile()` path referenced `deployment-script.sh` | Corrected to `deployment-script.sh.tpl` to match actual filename |
| `outputs` block typo (with `s` and colon) | Corrected to `output "name" {}` |

---

## 📋 Terraform Best Practices Applied

- **Remote state** stored in S3, shared and not lost if local machine is lost
- **State locking** via DynamoDB prevents corruption from concurrent runs
- **Secrets** managed via AWS Secrets Manager, never hardcoded
- **State file excluded from Git** via `.gitignore`
- **Variables** used throughout: no hardcoded values in resource files
- **Lifecycle rules** on ASG to prevent downtime during updates

---

## 📤 Outputs

| Output | Value |
|---|---|
| `vpc_id` | ID of the created VPC |
| `website_url` | `https://www.dorasws.org` |
