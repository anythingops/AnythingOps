module "ecr" {
  source = "./modules/ecr"
  repo_name = ""
  image_count = 10
}

module "network"{
    source = "./modules/network"
    vpc_cidr_block = ""
    availability_zones = ["ap-south-1a", "ap-south-1b"]
    public_subnets_cidr  = [ ""]
    private_subnets_cidr = [""]
    project_name = var.project_name 
    environment = var.environment
    ecs_sg_name = ""
    alb_sg_name = ""
    alb_sg_description = ""
    ecs_sg_description = ""
    vpc_id = module.network.vpc_id
}

module "iam"{
    source = "./modules/iam"
}

module "asg"{
    source = "./modules/asg"
    project_name = var.project_name
    environment = var.environment     
    launch_template_name = ""
    launch_template_description = ""
    instance_type = ""  
    autoscaling_max_size = 2
    autoscaling_min_size = 1
    autoscaling_desired_capacity = 1
    ami_id = ""  
    vpc_security_group_ids = module.network.vpc_security_group_ids
    private_subnet_ids = module.network.private_subnet_ids
    ec2_instance_profile_name = module.iam.ec2_instance_profile_name
    ecs_cluster_name = ""
    role = ""
}

module "alb" {
    source = "./modules/alb"
    project_name = var.project_name
    environment = var.environment
    security_groups = [module.network.alb_security_group_id]
    subnets = module.network.public_subnet_ids
    vpc_id = module.network.vpc_id
    healthcheck_endpoint = ""
    certificate_arn = ""
    domain_name = ""
}


module "ecs" {
  source = "./modules/ecs"
  task_definition_family_name = ""
  operating_system_family = ""
  cpu_architecture = ""
  network_mode = ""
  cpu = ""
  memory = ""
  container_name = ""
  tag = ""
  container_port = 80
  host_port = 80 
  retention_in_days = 7
  aws_region = var.aws_region
  task_role_arn = module.iam.task_role_arn
  execution_role_arn = module.iam.task_role_arn
  role = ""
  service_name = ""
  ecs_cluster_name = ""
  capacity_provider_name = ""
  target_group_arn = module.alb.alb_target_group_arn
  asg_arn = module.asg.asg_arn
  ecr_repo_url = module.ecr.ecr_repo_url
}