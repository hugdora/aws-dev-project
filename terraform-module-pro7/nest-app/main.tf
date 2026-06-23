#create vpc
module "vpc" {
  source = "git::ssh://git@github.com/hugdora/modules.git//vpc"

  region                       = "eu-west-2"
  project_name                 = "nest"
  environment                  = "dev"
  project_directory            = "nest-app"
  vpc_cidr                     = "10.0.0.0/16"
  public_subnet_az1_cidr       = "10.0.0.0/24"
  public_subnet_az2_cidr       = "10.0.1.0/24"
  private_app_subnet_az1_cidr  = "10.0.2.0/24"
  private_app_subnet_az2_cidr  = "10.0.3.0/24"
  private_data_subnet_az1_cidr = "10.0.4.0/24"
  private_data_subnet_az2_cidr = "10.0.5.0/24"
}

# Create Nat gateway
module "nat_gateway" {
  source                     = "git::ssh://git@github.com/hugdora/modules.git//nat-gateway"
  environment                = module.vpc.environment
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  internet_gateway           = module.vpc.internet_gateway
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id
}

# create security groups
module "security_groups" {
  source       = "git::ssh://git@github.com/hugdora/modules.git//security-groups"
  environment  = module.vpc.environment
  project_name = module.vpc.project_name
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr
}
# Create EC2 instance Connect Endpoint
module "eice" {
  source                    = "git::ssh://git@github.com/hugdora/modules.git//eice"
  environment               = module.vpc.environment
  project_name              = module.vpc.project_name
  private_app_subnet_az2_id = module.vpc.private_app_subnet_az2_id
  eice_security_group_id    = module.security_groups.eice_security_group_id

}

# Get secrets from secrets manager
module "secrets_manager" {
  source      = "git::ssh://git@github.com/hugdora/modules.git//secrets-manager"
  secret_name = "dev-secrets"
}

# Create RDS instance
module "rds" {
  source                     = "git::ssh://git@github.com/hugdora/modules.git//rds"
  environment                = module.vpc.environment
  project_name               = module.vpc.project_name
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id
  database_engine            = "mysql"
  multi_az_deployment        = "false"
  database_instance_class    = "db.t3.micro"
  rds_db_username            = module.secrets_manager.rds_db_username
  rds_db_password            = module.secrets_manager.rds_db_password
  rds_db_name                = module.secrets_manager.rds_db_name
  database_security_group_id = module.security_groups.database_security_group_id
  availability_zone_1        = module.vpc.availability_zone_1
  publicly_accessible        = "false"
}

# Create EC2 instance profile
module "ec2_intance_profile" {
  source       = "git::ssh://git@github.com/hugdora/modules.git//iam/ec2-instance-profile"
  environment  = module.vpc.environment
  project_name = module.vpc.project_name
}

# Create EC2 instance for database migration
module "data_migrate_ec2" {
  source                              = "git::ssh://git@github.com/hugdora/modules.git//data-migrate"
  amazon_linux_ami_id                 = "ami-0725c3768a7eb0fd5"
  ec2_instance_type                   = "t2.micro"
  private_app_subnet_az1_id           = module.vpc.private_app_subnet_az1_id
  db_migrate_server_security_group_id = module.security_groups.database_security_group_id
  ec2_instance_profile_role_name      = module.ec2_intance_profile.ec2_instance_profile_role_name
  flyway_version                      = "12.8.1"
  sql_script_s3_uri                   = "s3://dev-app-dora-webfiles/Project-2-assets/V1__nest.sql"
  rds_endpoint                        = module.rds.rds_endpoint
  rds_db_username                     = module.secrets_manager.rds_db_username
  rds_db_password                     = module.secrets_manager.rds_db_password
  rds_db_name                         = module.secrets_manager.rds_db_name
  environment                         = module.vpc.environment
  project_name                        = module.vpc.project_name
}

# request public SSL certificate from ACM
module "ssl_certificate" {
  source            = "git::ssh://git@github.com/hugdora/modules.git//acm"
  domain_name       = "dorasws.org"
  alternative_names = "*.dorasws.org"
}

# Create application load balancer
module "application_load_balancer" {
  source                = "git::ssh://git@github.com/hugdora/modules.git//alb"
  environment           = module.vpc.environment
  project_name          = module.vpc.project_name
  alb_security_group_id = module.security_groups.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  target_type           = "ip"
  vpc_id                = module.vpc.vpc_id
  health_check_path     = "/index.php"
  certificate_arn       = module.ssl_certificate.certificate_arn
}

# Create ECS role
module "ecs_role" {
  source       = "git::ssh://git@github.com/hugdora/modules.git//iam/ecs-role"
  environment  = module.vpc.environment
  project_name = module.vpc.project_name
}

# Create ECS
module "ecs" {
  source                       = "git::ssh://git@github.com/hugdora/modules.git//ecs"
  environment                  = module.vpc.environment
  project_name                 = module.vpc.project_name
  ecs_task_execution_role_arn  = module.ecs_role.ecs_task_execution_role_arn
  ecs_task_role_arn            = module.ecs_role.ecs_task_role_arn
  architecture                 = "X86_64"
  container_image              = "127486921697.dkr.ecr.eu-west-2.amazonaws.com/nest-app:latest"
  region                       = module.vpc.region
  private_app_subnet_az1_id    = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id    = module.vpc.private_app_subnet_az2_id
  app_server_security_group_id = module.security_groups.app_server_security_group_id
  alb_target_group_arn         = module.application_load_balancer.alb_target_group_arn
  depends_on                   = [module.data_migrate_ec2]
}

# Create A record set for Route53
module "route_53" {
  source                             = "git::ssh://git@github.com/hugdora/modules.git//route-53"
  domain_name                        = module.ssl_certificate.domain_name
  record_name                        = "www"
  application_load_balancer_dns_name = module.application_load_balancer.application_load_balancer_dns_name
  application_load_balancer_zone_id  = module.application_load_balancer.application_load_balancer_zone_id
}

# website URL
output "website_url" {
  value = join("", ["https://", module.route_53.record_name, ".", module.ssl_certificate.domain_name])
}

output "domain_name" {
  value = module.ssl_certificate.domain_name
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "ecs_task_definition_name" {
  value = module.ecs.ecs_task_definition_name
}

output "ecs_cluster_name" {
  value = module.ecs.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.ecs.ecs_service_name
}