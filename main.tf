terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 3.0"
        }
    }
    # backend "s3" {
    #     bucket         = "myterraformstatebucket1575"
    #     key            = "terraform/state"
    #     region         = "eu-north-1"
    #     dynamodb_table = "terraform-locks"
      
    # }
}

provider "aws" {
    region = "eu-north-1"
  
}

# Create a VPC and subnets in the eu-north-1 region
resource "aws_vpc" "eu_north_vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "eu-north-vpc"
    }
  
}

# Create 2 subnets in the VPC
resource "aws_subnet" "eu_north_subnet" {
    vpc_id            = aws_vpc.eu_north_vpc.id
    cidr_block        = var.subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    count             = 2
    map_public_ip_on_launch = true
    tags = {
        Name = "eu-north-subnet-${count.index + 1}"
    }
  
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "eu_north_igw" {
    vpc_id = aws_vpc.eu_north_vpc.id
    tags = {
        Name = "eu-north-igw"
    }
  
}

# Create a route table and add a route to the Internet Gateway
resource "aws_route_table" "eu_north_route_table" {
    vpc_id = aws_vpc.eu_north_vpc.id
    tags = {
        Name = "eu-north-route-table"
    }

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.eu_north_igw.id 
    }
}

# Associate the route table with the subnet 1
resource "aws_route_table_association" "eu_north_route_table_assoc_1" {
    subnet_id      = aws_subnet.eu_north_subnet[0].id
    route_table_id = aws_route_table.eu_north_route_table.id
}

# Associate the route table with the subnet 2
resource "aws_route_table_association" "eu_north_route_table_assoc_2" {
    subnet_id      = aws_subnet.eu_north_subnet[1].id
    route_table_id = aws_route_table.eu_north_route_table.id
}

# Create a security group for the VPC
resource "aws_security_group" "eu_north_sg" {
    vpc_id = aws_vpc.eu_north_vpc.id
    name   = "eu-north-sg"
    description = "Security group for the eu-north VPC"
    tags = {
        Name = "eu-north-sg"
    }

    ingress {
        description = "Allow SSH access"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow HTTP access"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow 8080 port access"
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create an ECR repository for the Jenkins pipeline
resource "aws_ecr_repository" "jenkins-pipeline" {
    name                 = "jenkins-pipeline"
    image_tag_mutability = "MUTABLE"
    tags = {
        Name = "jenkins-pipeline-repo"
    }

}

# Create an ECS cluster for node.js application
resource "aws_ecs_cluster" "node-app-cluster" {
    name = "node-app-cluster"
  
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create an ECS task definition for the node.js application
resource "aws_ecs_task_definition" "node-app-task" {
    family                   = "node-app-task"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                      = "1024" # 1 vCPU
    memory                   = "2048" # 2 GB of memory
    execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

    container_definitions = jsonencode([{
        name      = "node-app-container"
        image     = "${aws_ecr_repository.jenkins-pipeline.repository_url}:latest"
        essential = true
        portMappings = [{
            containerPort = 8080
            hostPort      = 8080
            protocol      = "tcp"
        }]
        environment = [
            {
                name  = "NODE_ENV"
                value = "Production"
            }
        ]
    }])
  
}

# Create an ECS service for the node.js application
resource "aws_ecs_service" "node-app-service" {
    name            = "node-app-service"
    cluster         = aws_ecs_cluster.node-app-cluster.id
    task_definition = aws_ecs_task_definition.node-app-task.arn
    desired_count   = 1
    launch_type     = "FARGATE"
    network_configuration {
        subnets          = aws_subnet.eu_north_subnet[*].id
        security_groups  = [aws_security_group.eu_north_sg.id]
        assign_public_ip = true
    }
    load_balancer {
        target_group_arn = aws_lb_target_group.ecs_tg.arn
        container_name   = "node-app-container"
        container_port   = 8080
    }

}

# Create ALB for the ECS service
resource "aws_lb" "ecs_alb" {
  name               = "ecs-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.eu_north_sg.id]
  subnets            = aws_subnet.eu_north_subnet[*].id

  tags = {
    Name = "ecs-app-alb"
  }
}

# Create ALB target group for the ECS service
resource "aws_lb_target_group" "ecs_tg" {
  name        = "ecs-app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.eu_north_vpc.id
  target_type = "ip"

  health_check {
    path = "/"
    port = "8080"
  }

  tags = {
    Name = "ecs-app-tg"
  }
}

# Create ALB listener for the ECS service
resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

# Create dynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform-locks" {
    name         = "terraform-locks"
    billing_mode = "PROVISIONED"
    hash_key     = "LockID"
    read_capacity = 20
    write_capacity = 20
    attribute {
        name = "LockID"
        type = "S"
    }
    tags = {
        Name = "terraform-locks"
    }
}


