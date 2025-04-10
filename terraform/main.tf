provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.cluster_name}-public-${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.cluster_name}-private-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

# Associate Public Subnets to Route Table
resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "${var.cluster_name}-nat-gateway"
  }
}

# Private Route Table with NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

# Associate Private Subnets to Route Table
resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}


resource "aws_key_pair" "default" {
  key_name   = var.key_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/ssh-key/${var.key_name}.pem"
  file_permission = "0600"
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "demo" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = concat(
      aws_subnet.public[*].id,
      aws_subnet.private[*].id
    )
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

# IAM Role for EKS Nodes
resource "aws_iam_role" "node_group_role" {
  name = "${var.cluster_name}-eks-nodegroup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nodegroup_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ])
  role       = aws_iam_role.node_group_role.name
  policy_arn = each.value
}

# EKS Node Group
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = aws_subnet.private[*].id
  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.desired_capacity + 1
    min_size     = 1
  }
  instance_types = [var.instance_type]
  depends_on = [aws_iam_role_policy_attachment.nodegroup_policies]
}

resource "aws_security_group" "public_sg" {
  name        = "${var.cluster_name}-public-sg"
  description = "Allow SSH and HTTP access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr] # e.g., "0.0.0.0/0" or your IP
  }

  ingress {
    description = "SonarQube HTTP"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Jenkins HTTP"
    from_port   = 8080
    to_port     = 8080
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
    Name = "${var.cluster_name}-sg"
  }
}


# EC2 for Jenkins
resource "aws_instance" "jenkins" {
  ami           = var.ami_id
  instance_type = var.instance_type_ext
  subnet_id     = aws_subnet.public[0].id
  key_name      = aws_key_pair.default.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  tags = {
    Name = "${var.cluster_name}-jenkins"
  }
  user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y

            # Install Java (Jenkins requirement)
            sudo amazon-linux-extras install java-openjdk11 -y

            # Add Jenkins repo and import key
            sudo wget -O /etc/yum.repos.d/jenkins.repo \
              https://pkg.jenkins.io/redhat-stable/jenkins.repo
            sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

            # Install Jenkins
            sudo yum install -y jenkins git

            # Start and enable Jenkins
            sudo systemctl daemon-reexec
            sudo systemctl start jenkins
            sudo systemctl enable jenkins

            # Install Docker
            sudo yum install -y docker
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker ec2-user
            sudo usermod -aG docker jenkins  # Set firewall rules if needed (Amazon Linux disables by default)
            # Install Trivy
            sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.51.1_Linux-64bit.rpm
            EOF
}

# EC2 for SonarQube
resource "aws_instance" "sonarqube" {
  ami           = var.ami_id
  instance_type = var.instance_type_ext
  subnet_id     = aws_subnet.public[1].id
  key_name      = aws_key_pair.default.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  tags = {
    Name = "${var.cluster_name}-sonarqube"
  }
  user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y

            # Install Java (required for SonarQube)
            sudo amazon-linux-extras install java-openjdk11 -y

            # Create SonarQube user
            sudo useradd sonar
            sudo mkdir /opt/sonarqube
            sudo chown sonar:sonar /opt/sonarqube

            # Download and extract SonarQube
            cd /opt/sonarqube
            sudo curl -O https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.4.87374.zip
            sudo yum install -y unzip
            sudo unzip sonarqube-9.9.4.87374.zip
            sudo mv sonarqube-9.9.4.87374 sonarqube
            sudo chown -R sonar:sonar /opt/sonarqube

            # Setup SonarQube as a systemd service
            sudo bash -c 'cat > /etc/systemd/system/sonarqube.service' << EOL
            [Unit]
            Description=SonarQube service
            After=syslog.target network.target

            [Service]
            Type=simple
            User=sonar
            Group=sonar
            PermissionsStartOnly=true
            ExecStart=/opt/sonarqube/sonarqube/bin/linux-x86-64/sonar.sh start
            ExecStop=/opt/sonarqube/sonarqube/bin/linux-x86-64/sonar.sh stop
            Restart=always

            [Install]
            WantedBy=multi-user.target
            EOL

            # Reload and start the service
            sudo systemctl daemon-reexec
            sudo systemctl daemon-reload
            sudo systemctl enable sonarqube
            sudo systemctl start sonarqube
            EOF

}
