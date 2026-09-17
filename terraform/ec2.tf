data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "ec2" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.app_name}-vpc"
  }
}

resource "aws_subnet" "ec2_public" {
  vpc_id                  = aws_vpc.ec2.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.app_name}-public-subnet"
  }
}

resource "aws_internet_gateway" "ec2" {
  vpc_id = aws_vpc.ec2.id

  tags = {
    Name = "${local.app_name}-igw"
  }
}

resource "aws_route_table" "ec2_public" {
  vpc_id = aws_vpc.ec2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ec2.id
  }

  tags = {
    Name = "${local.app_name}-public-rt"
  }
}

resource "aws_route_table_association" "ec2_public" {
  subnet_id      = aws_subnet.ec2_public.id
  route_table_id = aws_route_table.ec2_public.id
}

resource "aws_security_group" "ec2" {
  name        = "${local.app_name}-ec2-sg"
  description = "Allow SSH and application traffic to the Ubuntu EC2 instance"
  vpc_id      = aws_vpc.ec2.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
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
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_deployment" {
  name               = "${local.app_name}-ec2-deployment-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_read_only" {
  role       = aws_iam_role.ec2_deployment.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_instance" {
  role       = aws_iam_role.ec2_deployment.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_deployment" {
  name = "${local.app_name}-ec2-deployment-profile"
  role = aws_iam_role.ec2_deployment.name
}

resource "aws_instance" "ubuntu" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.ec2_public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null
  iam_instance_profile        = aws_iam_instance_profile.ec2_deployment.name

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    apt-get update -y
    apt-get install -y docker.io awscli snapd
    systemctl enable --now docker
    snap install amazon-ssm-agent --classic || true
    systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true

    cat >/usr/local/bin/deploy-app <<'DEPLOY_SCRIPT'
    #!/bin/bash
    set -euo pipefail

    IMAGE_URI="$${1:?image URI is required}"
    AWS_REGION="${var.aws_region}"
    CONTAINER_NAME="${local.app_name}"

    aws ecr get-login-password --region "$AWS_REGION" |
      docker login --username AWS --password-stdin "$${IMAGE_URI%%/*}"
    docker pull "$IMAGE_URI"
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    docker run -d \
      --name "$CONTAINER_NAME" \
      --restart unless-stopped \
      -p 80:3000 \
      "$IMAGE_URI"
    DEPLOY_SCRIPT
    chmod +x /usr/local/bin/deploy-app
  EOF

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
  }

  tags = {
    Name = "${local.app_name}-ubuntu"
    OS   = "Ubuntu"
  }
}
