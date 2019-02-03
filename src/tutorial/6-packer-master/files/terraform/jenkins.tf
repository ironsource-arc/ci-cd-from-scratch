provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "jenkins" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
      Name = "jenkins"
  }
}

resource "aws_internet_gateway" "jenkins" {
    vpc_id = "${aws_vpc.jenkins.id}"

    tags {
        Name = "jenkins"
    }
}

resource "aws_route_table" "jenkins" {
    vpc_id = "${aws_vpc.jenkins.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.jenkins.id}"
    }

    tags {
        Name = "jenkins"
    }
}

resource "aws_route_table_association" "a" {
    subnet_id = "${aws_subnet.jenkins.id}"
    route_table_id = "${aws_route_table.jenkins.id}"
}

resource "aws_subnet" "jenkins" {
    vpc_id = "${aws_vpc.jenkins.id}"
    map_public_ip_on_launch = true
    cidr_block = "10.0.1.0/24"

    tags {
        Name = "jenkins"
    }
}

resource "aws_security_group" "office" {
  name = "office"
  description = "Access from office ips"
  vpc_id = "${aws_vpc.jenkins.id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["111.111.11.11/27"]
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["111.111.11.11/27"]
  }
}

resource "aws_security_group" "outbound" {
  name = "outbound"
  description = "Jenkins internet access"
  vpc_id = "${aws_vpc.jenkins.id}"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "internal" {
  name = "internal"
  description = "Jenkins internal access"
  vpc_id = "${aws_vpc.jenkins.id}"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }
}
resource "aws_security_group" "jenkins-master-public" {
  name = "jenkins-master-public"
  description = "Jenkins master internet access"
  vpc_id = "${aws_vpc.jenkins.id}"
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["111.111.11.11/27"]
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["111.111.11.11/27"]
  }
}

data "aws_ami" "jenkins-slave-image" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}
data "aws_ami" "jenkins-master-image" {
  most_recent = true
  name_regex = "^packer-jenkins-master-test"
}

resource "aws_instance" "jenkins-slave-test-zigi" {
  ami           = "${data.aws_ami.jenkins-slave-image.id}"
  instance_type = "t2.micro"
  depends_on = ["aws_internet_gateway.jenkins"]  
  subnet_id = "${aws_subnet.jenkins.id}"
  vpc_security_group_ids = [ 
    "${aws_security_group.office.id}", 
    "${aws_security_group.outbound.id}",
    "${aws_security_group.internal.id}"
  ]
  tags {
    Name = "jenkins-slave-test-zigi"
  }
}

resource "aws_eip" "jenkins-slave-test-zigi-ip" {
  vpc = true
  instance = "${aws_instance.jenkins-slave-test-zigi.id}"
}

resource "aws_instance" "jenkins-master-test-zigi" {
  ami           = "${data.aws_ami.jenkins-master-image.id}"
  instance_type = "t2.micro"
  depends_on = ["aws_internet_gateway.jenkins"]  
  subnet_id = "${aws_subnet.jenkins.id}"
  vpc_security_group_ids = [ 
    "${aws_security_group.office.id}", 
    "${aws_security_group.jenkins-master-public.id}", 
    "${aws_security_group.outbound.id}",
    "${aws_security_group.internal.id}"
  ]
  tags {
          Name = "jenkins-master-test-zigi"
      }
}

resource "aws_eip" "jenkins-master-test-zigi-ip" {
    instance = "${aws_instance.jenkins-master-test-zigi.id}"
}
