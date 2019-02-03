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
    depends_on = ["aws_vpc.jenkins"]  

    tags {
        Name = "jenkins"
    }
}

