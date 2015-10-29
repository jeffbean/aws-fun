provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}
/*
  Public Subnet
*/
resource "aws_subnet" "public_subnet" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "us-west-2a"

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags {
        Name = "Public Subnet"
    }
}

resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags {
        Name = "terraform-aws-vpc"
    }
}
resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route_table_association" "default" {
    subnet_id = "${aws_subnet.public_subnet.id}"
    route_table_id = "${aws_route_table.public_route_table.id}"
}


# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name = "terraform_example"
  description = "Used in the terraform"
  vpc_id = "${aws_vpc.default.id}"
  # SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
    # The connection block tells our provisioner how to
    # communicate with the resource (instance)
    connection {
        # The default username for our AMI
        user = "ubuntu"

        # The path to your keyfile
        key_file = "${var.key_path}"
    }
    ami = "${lookup(var.amis, var.aws_region)}"
    instance_type = "t2.micro"
    # The name of our SSH keypair you've created and downloaded
    # from the AWS console.
    #
    # https://console.aws.amazon.com/ec2/v2/home?region=us-west-2#KeyPairs:
    #
    key_name = "${var.key_name}"

    subnet_id = "${aws_subnet.public_subnet.id}"
    associate_public_ip_address = true
    # We run a remote provisioner on the instance after creating it.
    # In this case, we just install nginx and start it. By default,
    # this should be on port 80
    provisioner "remote-exec" {
        inline = [
          "sudo yum -y update",
          "sudo yum -y install nginx",
          "sudo service nginx start"
        ]
    }
}
