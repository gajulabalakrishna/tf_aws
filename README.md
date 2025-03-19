# tf_aws

To configure an Amazon Elastic Kubernetes Service (EKS) cluster using Terraform, follow these steps:

Prerequisites
AWS Account – Ensure you have an AWS account.
IAM User with Permissions – You need an IAM user with permissions to create EKS, VPC, EC2, IAM roles, and security groups.
Terraform Installed – Install Terraform on your local machine.
kubectl Installed – Install kubectl to interact with the EKS cluster.
AWS CLI Installed – Configure AWS credentials using aws configure.
Step 1: Create a Terraform Configuration File
Create a directory for your Terraform files and define the required resources.

bash
Copy
Edit
mkdir terraform-eks
cd terraform-eks
Now, create Terraform configuration files:

1. providers.tf (Define Providers)
This file configures Terraform to use AWS as the provider.

hcl
Copy
Edit
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-west-2"
}
2. vpc.tf (Create VPC and Subnets)
EKS requires a VPC with at least two subnets in different Availability Zones.

hcl
Copy
Edit
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "eks-vpc"
  }
}

resource "aws_subnet" "eks_subnet_1" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "eks-subnet-1"
  }
}

resource "aws_subnet" "eks_subnet_2" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "eks-subnet-2"
  }
}
3. eks.tf (Create the EKS Cluster)
Define the EKS cluster using Terraform.

hcl
Copy
Edit
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}
4. nodegroup.tf (Create a Node Group)
Define the EKS worker nodes.

h
Copy
Edit
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  node_group_name = "my-node-group"
  node_role_arn = aws_iam_role.eks_node_role.arn
  subnet_ids    = [aws_subnet.eks_subnet_1.id, aws_subnet.eks_subnet_2.id]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only_policy
  ]
}
5. outputs.tf (Define Outputs)
Outputs help retrieve information about the created resources.

h
Copy
Edit
output "cluster_id" {
  value = aws_eks_cluster.eks_cluster.id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.eks_cluster.arn
}
Step 2: Initialize Terraform
Run the following commands in the Terraform directory:

bash
Copy
Edit
terraform init
This downloads the required provider plugins.

Step 3: Plan the Deployment
Run:

bash
Copy
Edit
terraform plan
Terraform will generate an execution plan showing what will be created.

Step 4: Apply the Configuration
To create the resources:

bash
Copy
Edit
terraform apply -auto-approve
This deploys the EKS cluster and node group.

Step 5: Configure kubectl to Access the Cluster
Once Terraform completes, retrieve the cluster credentials:

bash
Copy
Edit
aws eks --region us-west-2 update-kubeconfig --name my-eks-cluster
Now, check if your cluster is running:

bash
Copy
Edit
kubectl get nodes
This should list the worker nodes.

Step 6: Deploy a Test Application
Deploy a simple Nginx application:

yaml
Copy
Edit
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
Save this as nginx-deployment.yaml, then apply it:

bash
Copy
Edit
kubectl apply -f nginx-deployment.yaml
kubectl get pods
Step 7: Clean Up
To destroy the resources:

bash
Copy
Edit
terraform destroy -auto-approve
To create a Load Balancer using Terraform, we will use AWS Application Load Balancer (ALB) with an Auto Scaling Group (ASG). Below is a complete Terraform setup.

Prerequisites
AWS Account – Ensure you have an AWS account.
Terraform Installed – Install Terraform.
AWS CLI Installed – Configure AWS credentials using aws configure.
Step 1: Create Terraform Configuration Files
Create a directory for your Terraform files:

bash
Copy
Edit
mkdir terraform-lb
cd terraform-lb
Now, create the necessary Terraform configuration files.

1. provider.tf (Define AWS Provider)
This file sets up Terraform to use AWS.

hcl
Copy
Edit
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-west-2"
}
2. vpc.tf (Create VPC and Subnets)
We need a VPC and subnets to launch instances.

hcl
Copy
Edit
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "subnet-2"
  }
}
3. security_groups.tf (Define Security Groups)
We need security groups for the Load Balancer and EC2 instances.

hcl
Copy
Edit
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "load-balancer-sg"
  }
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}
4. load_balancer.tf (Create Load Balancer)
Now, create the ALB and target group.

hcl
Copy
Edit
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets           = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  tags = {
    Name = "my-load-balancer"
  }
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}
5. ec2.tf (Launch EC2 Instances)
We launch instances in an Auto Scaling Group.

h
Copy
Edit
resource "aws_launch_template" "my_template" {
  name_prefix   = "my-template"
  image_id      = "ami-0c55b159cbfafe1f0" # Update with a valid AMI ID
  instance_type = "t2.micro"

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "my-ec2-instance"
    }
  }
}

resource "aws_autoscaling_group" "my_asg" {
  vpc_zone_identifier = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  desired_capacity    = 2
  min_size           = 1
  max_size           = 3

  launch_template {
    id      = aws_launch_template.my_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.my_target_group.arn]
}
6. outputs.tf (Define Outputs)
Retrieve important values.

h
Copy
Edit
output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name
}
Step 2: Initialize Terraform
Run:

bash
Copy
Edit
terraform init
Step 3: Plan the Deployment
Run:

bash
Copy
Edit
terraform plan
Step 4: Apply the Configuration
Run:

bash
Copy
Edit
terraform apply -auto-approve
After a few minutes, Terraform will complete, and you will see the Load Balancer DNS name in the outputs.

Step 5: Test the Load Balancer
Run:

bash
Copy
Edit
terraform output alb_dns_name
Copy the DNS name and open it in a browser. You should see your web server running.

Step 6: Clean Up Resources
To destroy everything:

bash
Copy
Edit
terraform destroy -auto-approve
Conclusion
This Terraform setup:

Creates a VPC with subnets.
Sets up security groups.
Deploys an Application Load Balancer (ALB).
Creates an Auto Scaling Group (ASG) with EC2 instances.
Configures an ALB Listener and Target Group.
