data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "ansible_controller" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ci_cd_sg.id]
  key_name               = var.key_name

  tags = {
    Name        = "${var.environment}-ansible-controller"
    Environment = var.environment
  }
}

resource "aws_instance" "jenkins_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ci_cd_sg.id]
  key_name               = var.key_name

  tags = {
    Name        = "${var.environment}-jenkins-master"
    Environment = var.environment
  }
}

resource "aws_instance" "jenkins_agent" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ci_cd_sg.id]
  key_name               = var.key_name

  tags = {
    Name        = "${var.environment}-jenkins-agent"
    Environment = var.environment
  }
}   