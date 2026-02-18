variable "region" {
  type = string
}

variable "install_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = string
}

variable "node_security_group_id" {
  type = string
}

variable "db_name" {
  type    = string
  default = "gitea"
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

locals {
  subnet_ids = split(",", var.private_subnet_ids)
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.install_id}-gitea"
  subnet_ids = local.subnet_ids

  tags = {
    Name      = "${var.install_id}-gitea"
    ManagedBy = "nuon"
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.install_id}-gitea-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.install_id}-gitea-rds"
    ManagedBy = "nuon"
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.install_id}-gitea"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.instance_class

  db_name  = var.db_name
  username = "admin"
  manage_master_user_password = true

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name      = "${var.install_id}-gitea"
    ManagedBy = "nuon"
  }
}

output "address" {
  value = aws_db_instance.this.address
}

output "db_instance_port" {
  value = tostring(aws_db_instance.this.port)
}

output "db_instance_master_user_secret_arn" {
  value = aws_db_instance.this.master_user_secret[0].secret_arn
}