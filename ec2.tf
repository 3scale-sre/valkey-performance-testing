module "ec2_labels" {
  source      = "git@github.com:3scale-sre/tf-aws-label.git?ref=tags/0.1.2"
  environment = local.environment
  project     = local.project
  workload    = local.workload
  type        = "ec2"
  tf_config   = local.tf_config
}

data "aws_ami" "rhel_9_2" {
  most_recent = true
  owners      = ["309956199498"] // Red Hat's Account ID
  filter {
    name   = "name"
    values = ["RHEL-9.2*"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 3.0"
  name                = module.ec2_labels.id
  description         = "Security group for valkey perf test"
  vpc_id              = var.vpc_id
  egress_rules        = ["all-all"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp", "redis-tcp"]
  ingress_with_self = [
    {
      rule = "all-all"
    },
  ]
}

resource "aws_iam_role" "instance_role" {
  name = module.ec2_labels.id

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    module.ec2_labels.tags,
    tomap({ "Name" = format("%s", module.ec2_labels.id) })
  )
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = module.ec2_labels.id
  role = aws_iam_role.instance_role.name
}

resource "aws_instance" "valkey_instance" {
  ami           = data.aws_ami.rhel_9_2.id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_ssh_key_name

  iam_instance_profile = aws_iam_instance_profile.instance_profile.id
  subnet_id            = var.vpc_private_subnet_id[0]
  vpc_security_group_ids = [
    module.sg.this_security_group_id
  ]

  user_data = file("valkey.userdata")

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    tags = merge(
      module.ec2_labels.tags,
      tomap({ "Name" = format("%s-%s-%s-root", module.ec2_labels.environment, module.ec2_labels.project, "valkey") })
    )
  }

  tags = merge(
    module.ec2_labels.tags,
    tomap({ "Name" = format("%s-%s-%s", module.ec2_labels.environment, module.ec2_labels.project, "valkey") })
  )
}

resource "aws_instance" "valkey_benchmark_instance" {
  ami           = data.aws_ami.rhel_9_2.id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_ssh_key_name

  iam_instance_profile = aws_iam_instance_profile.instance_profile.id
  subnet_id            = var.vpc_private_subnet_id[0]
  vpc_security_group_ids = [
    module.sg.this_security_group_id
  ]

  user_data = file("valkey.userdata")

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    tags = merge(
      module.ec2_labels.tags,
      tomap({ "Name" = format("%s-%s-%s-root", module.ec2_labels.environment, module.ec2_labels.project, "valkey-benchmark") })
    )
  }

  tags = merge(
    module.ec2_labels.tags,
    tomap({ "Name" = format("%s-%s-%s", module.ec2_labels.environment, module.ec2_labels.project, "valkey-benchmark") })
  )
}
