# vim: et sr sw=2 ts=2 smartindent:

terraform {
  required_version = "~> 0.11"

  bucket = "101waystest"

  region = "eu-west-1"
  key    = "/tfstate/jin.tfstate"

}

provider aws {
  region = "eu-west-1"
}

data "aws_ami" "coreos_stable" {
  most_recent      = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["CoreOS-stable-*"]
  }

  filter {
    name   = "owner-id"
    values = ["595879546273"]
  }
}

# ++++++++++++++++++++
# ... security groups
# ++++++++++++++++++++
resource "aws_security_group" "web-tier" {
  name        = "${var.object_name}"
  description = "... ssh, http, ping for web-tier nodes"
  vpc_id      = "${var.vpc_id}"

  # ... ssh - uncomment to troubleshoot during dev
  # ingress {
  #  from_port   = 22
  #  to_port     = 22
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  # ... http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ... elb traffic
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  # ... outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name          = "${var.object_name}-web-tier"
    product       = "${var.object_name}"
    stack_name    = "int"
  }
}

resource "aws_security_group" "elb" {
  name        = "${var.object_name}-elb"
  description = "... http from anywhere and outbound"
  vpc_id      = "${var.vpc_id}"

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

  tags {
    Name          = "${var.object_name}-elb"
    product       = "${var.product}"
    stack_name    = "${var.stack_name}"
  }
}


# ++++++++++++++++++++
# ... elb
# ++++++++++++++++++++
resource "aws_elb" "web-elb" {
  name         = "int-101ways-nginx-elb"
  idle_timeout = 120

  cross_zone_load_balancing = true

  connection_draining = true
  connection_draining_timeout = 30

  # The same availability zone as our instances
  subnets  = "${var.subnet_ids_public}"

  listener {
    instance_port      = 80
    instance_protocol  = "HTTP"
    lb_port            = 80
    lb_protocol        = "HTTP"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/version.txt"
    interval            = 30
  }

  security_groups  = ["${aws_security_group.elb.id}"]

  tags {
    Name          = "${var.object_name}"
    product       = "${var.product}"
    stack_name    = "${var.stack_name}"
  }
}

# ++++++++++++++++++++
# ... asg
# ++++++++++++++++++++
resource "aws_autoscaling_group" "web-asg" {
  name                      = "${var.object_name}-${var.deploy_id}"
  max_size                  = "2"
  min_size                  = "2"
  desired_capacity          = "2"
  default_cooldown          = 120
  force_delete              = true
  health_check_grace_period = 240
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.web-lc.name}"
  load_balancers            = ["${aws_elb.web-elb.name}"]
  min_elb_capacity          = 1
  termination_policies      = ["OldestInstance"]
  vpc_zone_identifier       = "${var.subnet_ids_public}"

  tag {
    key                 = "Name"
    value               = "${var.object_name}-${var.deploy_id}"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "product"
    value               = "${var.product}"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "stack_name"
    value               = "${var.stack_name}"
    propagate_at_launch = "true"
  }

}

resource "aws_launch_configuration" "web-lc" {
  name_prefix          = "${var.object_name}"
  image_id             = "${data.aws_ami.coreos_stable.id}"
  instance_type        = "t2.micro"
  key_name             = "101WaysInfraTest"
  user_data            = "${base64gzip(file("cloud-config.web-tier-asg"))}"

  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }

  security_groups = ["${aws_security_group.web-tier.id}"]

}

output "ami_id" {
    value = "${data.aws_ami.coreos_stable.id}"
}

output "elb_name" {
    value = "${aws_elb.web-elb.dns_name}"
}
