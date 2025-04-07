resource "null_resource" "docker_push" {
  depends_on = [var.ecr_repo_url]

  provisioner "local-exec" {
    command = <<EOT
      ECR_URL=${var.ecr_repo_url}

      # Authenticate with ECR
      aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $ECR_URL

      # Build and push the Docker image
      docker pull --platform=linux/amd64 nginx
      docker tag nginx $ECR_URL:latest
      docker push $ECR_URL:latest
    EOT
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/${var.task_definition_family_name}"
  retention_in_days = var.retention_in_days
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
 depends_on = [null_resource.docker_push]
 family             = var.task_definition_family_name
 requires_compatibilities = ["EC2"]
 runtime_platform {
   operating_system_family = var.operating_system_family
   cpu_architecture        = var.cpu_architecture
 }
 
 network_mode       = var.network_mode
 cpu                = var.cpu
 memory             = var.memory
 task_role_arn        = var.task_role_arn
 execution_role_arn = var.execution_role_arn
 container_definitions = jsonencode([
   {
     name      = var.container_name
     image = "${var.ecr_repo_url}:${var.tag}"
     essential = true
     portMappings = [
       {
         containerPort = var.container_port
         hostPort      = var.host_port
         protocol      = "tcp"
       }
     ]
     logConfiguration = {
        logDriver = "awslogs",
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
   }
 ])
}

resource "aws_ecs_cluster" "ecs_cluster" {
 name = var.ecs_cluster_name
}

resource "aws_ecs_capacity_provider" "capacity_provider" {
  name = var.capacity_provider_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.asg_arn
    managed_termination_protection = "DISABLED"
    
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }

}

resource "aws_ecs_cluster_capacity_providers" "example" {
 cluster_name = aws_ecs_cluster.ecs_cluster.name

 capacity_providers = [aws_ecs_capacity_provider.capacity_provider.name]

 default_capacity_provider_strategy {
   base              = 1
   weight            = 100
   capacity_provider = aws_ecs_capacity_provider.capacity_provider.name
 }
}

resource "aws_ecs_service" "ecs_service" {
 name            = var.service_name
 cluster         = var.ecs_cluster_name
 task_definition = aws_ecs_task_definition.ecs_task_definition.arn
 desired_count   = 1
 force_new_deployment = true

 ordered_placement_strategy {
  type  = "spread"
  field = "attribute:ecs.availability-zone"
}

ordered_placement_strategy {
  type  = "spread"
  field = "instanceId"
}

 placement_constraints {
   type = "memberOf"
   expression = "attribute:role ==  ${var.role}"
 }
 capacity_provider_strategy {
   capacity_provider = aws_ecs_capacity_provider.capacity_provider.name
   weight            = 1
   base              = 0
 }

 load_balancer {
   target_group_arn = var.target_group_arn
   container_name   = var.container_name
   container_port   = var.container_port
}
 depends_on = [
    aws_ecs_task_definition.ecs_task_definition,
    aws_ecs_capacity_provider.capacity_provider,
  ]
}