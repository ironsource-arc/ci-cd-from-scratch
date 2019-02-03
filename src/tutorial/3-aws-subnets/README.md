At ironSource infra team, we are responsible for developing an automation framework to help test our various products.

## Setting up the Amazon network - Part 2

### Internet gateway
Lets continue working on the AWS infrastructure. We are going to create our own [internet gateway](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Internet_Gateway.html). When creating a new VPC, by default it is configured to only provide a private network. To allow internal access from the internet into our instances we need to create an internet gateway. As always, here is a short description on what an internet gateway is: 

>An Internet gateway is a horizontally scaled, redundant, and highly available VPC component that allows communication between instances in your VPC and the Internet. It therefore imposes no availability risks or bandwidth constraints on your network traffic.
An Internet gateway serves two purposes: to provide a target in your VPC route tables for Internet-routable traffic, and to perform network address translation (NAT) for instances that have been assigned public IPv4 addresses.

Pretty simple. Without an internet gateway our instances will not be able to fill out all those buzzfeed questionnaires that they love so much. 
Heres the terraform setup:

```terraform
resource "aws_internet_gateway" "jenkins" {
    vpc_id = "${aws_vpc.jenkins.id}"

    tags {
        Name = "jenkins"
    }
}

```
The only property we need to define to create the internet gateway is the VPC id we need to create the internet gateway in. Also, we are attaching the same tag that we attached to our VPC.

Go ahead and place the snippet in your file, hit ```terraform apply``` and voila! We've got a connection to the outside world. 
Lets see the output of applying our changes: 

```
aws_vpc.jenkins: Creating...
  cidr_block:                "" => "10.0.0.0/16"
  default_network_acl_id:    "" => "<computed>"
  default_route_table_id:    "" => "<computed>"
  default_security_group_id: "" => "<computed>"
  dhcp_options_id:           "" => "<computed>"
  enable_classiclink:        "" => "<computed>"
  enable_dns_hostnames:      "" => "true"
  enable_dns_support:        "" => "true"
  instance_tenancy:          "" => "<computed>"
  main_route_table_id:       "" => "<computed>"
  tags.%:                    "" => "1"
  tags.Name:                 "" => "jenkins"
aws_vpc.jenkins: Creation complete
aws_internet_gateway.jenkins: Creating...
  tags.%:    "0" => "1"
  tags.Name: "" => "jenkins"
  vpc_id:    "" => "vpc-1c813074"
aws_internet_gateway.jenkins: Creation complete

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```
As you can see, the VPC was created first, because we need the VPC to attach the internet gateway to. We have an implicit dependency between the internet gateway and the VPC. If you would like you can also add a tag for an explicit dependency:
```
resource "aws_internet_gateway" "jenkins" {
    vpc_id = "${aws_vpc.jenkins.id}"
    depends_on = ["aws_vpc.jenkins"]  

    tags {
        Name = "jenkins"
    }
}

```

You can run ```terraform graph``` to see the dependency chain if you want. We will cover terraform graph in a later chapter, but you can always use it now if you are curious..

So now we have an internet gateway but is it enough? The gateway only connects us to the internet, but it doesn't specify how to route incoming and outgoing requests to the different components. For that we will need something else.

### Routing table
>A route table contains a set of rules, called routes, that are used to determine where network traffic is directed.

>Each subnet in your VPC must be associated with a route table; the table controls the routing for the subnet. A subnet can only be associated with one route table at a time, but you can associate multiple subnets with the same route table.


Here is the terraform setup for creating a route table.
```terraform
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
```
Our routing table is simple. All external traffic into our VPC will be processed by the gateway we previously created.

### Subnets

> A subnetwork or subnet is a logical subdivision of an IP network. The practice of dividing a network into two or more networks is called subnetting. Computers that belong to a subnet are addressed with a common, identical, most-significant bit-group in their IP address.

We are going to add a subnet to our terraform setup. A subnet is used to apply similar network restrictions on a small subset of IPs in our VPC. Again, we will be creating a simple subnet. Lets look at the code:

```terraform
resource "aws_subnet" "jenkins" {
    vpc_id = "${aws_vpc.jenkins.id}"
    map_public_ip_on_launch = true
    cidr_block = "10.0.1.0/24"

    tags {
        Name = "jenkins"
    }
}
```
We specify the vpc id. `map_public_ip_on_launch` indicates that instances launched into the subnet should be assigned a public IP address.the cidr block we specified will allow us to assign ~255 instances. We are going to use 4 so that should be enough.

Now we need to connect our subnet to our routing table. By default the subnet uses the default routing table. We already have a routing table that we created so lets associate our subnet with that one.

```terraform
resource "aws_route_table_association" "a" {
    subnet_id = "${aws_subnet.jenkins.id}"
    route_table_id = "${aws_route_table.jenkins.id}"
}
```
This little terraform snippet associates our subnet with our route table. 

### Security Groups

> A security group acts as a virtual firewall that controls the traffic for one or more instances. When you launch an instance, you associate one or more security groups with the instance. You add rules to each security group that allow traffic to or from its associated instances. You can modify the rules for a security group at any time; the new rules are automatically applied to all instances that are associated with the security group. When we decide whether to allow traffic to reach an instance, we evaluate all the rules from all the security groups that are associated with the instance.

Security groups are the last piece of the puzzle we need in order to create a secure network for our jenkins infrastructure.

We will be creating 4 security groups. A security group for your own IP to allow SSH access, An outbound security group to allow our jenkins instances to send data over the network, an internal security group to allow our instances to send and receive data with each other, and a subnet that will allow our jenkins master to send and receive data from port 8080, so we can communicate with it via our browser.

Heres the first SG setup.
```terraform
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
```
We specify the name of the security group, The description, and the VPC id. 
Next, we specify 2 ingress rules. 
Ingress rules let us specify for an IP, what ports our instances can use. For instance, we specify in the first ingress rule, that we allow connection to our instances from port 22 to 
port 22 for your IP. (Get your IP and replace it in the cidr_blocks section. you can get it like this `curl wtfismyip.com/text` and add 
it like this `cidr_blocks = ["111.111.111.111/32"]`). The second ingress rule allows all tcp communication between your IP and the instances under the SG.

```terraform
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
```
This SG enables all outbound traffic from all ports to all ports for every protocol and IP. Our instances will be completely open for sending data. Egress means outbound :) (ZIGI TODO: enter picture of ralph from the simpsons)

```terraform
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
```
I think you can already figure out what the remaining security groups resources are up to. 

That wraps up the networking section of our jenkins infrastructure setup. In the next chapter we will review the final section of our terraform setup. Setting up the amis and the ec2 instances. 

[Previous chapter: 2-AWS](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/2-aws) 

[Next chapter: 4-AWS-AMI-EC2](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/4-aws-ami-ec2) 
