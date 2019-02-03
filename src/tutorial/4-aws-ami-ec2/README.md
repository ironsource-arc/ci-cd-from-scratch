At ironSource infra team, we are responsible for developing an automation framework to help test our various products.

## Setting up the EC2 instances

### AMI's
>an amazon machine image (AMI) provides the information required to launch an instance, which is a virtual server in the cloud. you specify an AMI when you launch an instance, and you can launch as many instances from the AMI as you need. you can also launch instances from as many different AMI's as you need.


An [AMI](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) is the image on which we base our instances creation. We base our AMI's on an ubuntu 16.04 images. Lets look at the terraform configuration:
```terraform
data "aws_ami" "jenkins-slave-image" {
  most_recent = true
  name_regex = "^packer-jenkins-slave-test"
}
data "aws_ami" "jenkins-master-image" {
  most_recent = true
  name_regex = "^packer-jenkins-master-test"
}
```

An AMI is defined as a data resource. We give our AMI's the name of the instance they are going to be used by: jenkins-slave-image and jenkins-master-image. 
I mentioned earlier that we are using ubuntu 16.04 as the base image. While that may be true, you will see no reference to the base ubuntu image in the configuration. 
That is because we are using a tool called packer to create a base image that is better suited to our needs. 
I will show you how to use packer in the next chapter so for now you are just going to have to trust me. 
The `most_recent` flag and the `name_regex` flag help terraform select the last successful image we created using packer. More on that in the next chapter. 
We create a separate base image for the slave and master because they will use different tools and services.

### EC2

>Amazon Elastic Compute Cloud (Amazon EC2) provides scalable computing capacity in the Amazon Web Services (AWS) cloud. Using Amazon EC2 eliminates your need to invest in hardware up front, so you can develop and deploy applications faster. You can use Amazon EC2 to launch as many or as few virtual servers as you need, configure security and networking, and manage storage. Amazon EC2 enables you to scale up or down to handle changes in requirements or spikes in popularity, reducing your need to forecast traffic.

We are going to use [EC2](https://aws.amazon.com/ec2/) as the machine that hosts our services. Lets look at the terraform configuration.

```terraform
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
```

This config wraps everything we've learned so far together. We set the AMI to use. The type of instance - t2.micro is eligible for free tier usage, and will be enough for our humble project. 
We specify an explicit dependency between our instances and the internet gateway. We specify the subnet we previously created. The slave will use the office SG, the outbound SG, and the internal SG. 
The master will also use its dedicated SG for enabling internet access over port 8080 to the service. Finally, we add a tag like always so we can easily identify our instances.

One last thing, We need to associate an elastic ip with our instances, for them to support external traffic. Here is the tf configuration: 

```terraform
resource "aws_eip" "jenkins-slave-test-zigi-ip" {
  vpc = true
  instance = "${aws_instance.jenkins-slave-test-zigi.id}"
}

resource "aws_eip" "jenkins-master-test-zigi-ip" {
    instance = "${aws_instance.jenkins-master-test-zigi.id}"
}
```

This snippet will create 2 new public ips and associate them with our instance. 

That's it for our terraform section. Let's see it all in action, but first, we previously showed that we build our base images using an image that was previously created using packer. We don't have that base image yet, so I will replace the AMI's section with the following tf configuration: 


```terraform
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
```

So load it up, hit `terraform apply` and see the fruits of your labour. 

```sh 
data.aws_ami.jenkins-master-image: Refreshing state...
data.aws_ami.jenkins-slave-image: Refreshing state...
aws_vpc.jenkins: Creating...
...
...

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.
```

We talked about terraform graph earlier. Lets see the output of the graph now.
```terraform
digraph {
	compound = "true"
	newrank = "true"
	subgraph "root" {
		"[root] aws_eip.jenkins-master-test-zigi-ip" [label = "aws_eip.jenkins-master-test-zigi-ip", shape = "box"]
		"[root] aws_eip.jenkins-slave-test-zigi-ip" [label = "aws_eip.jenkins-slave-test-zigi-ip", shape = "box"]
		"[root] aws_instance.jenkins-master-test-zigi" [label = "aws_instance.jenkins-master-test-zigi", shape = "box"]
		"[root] aws_instance.jenkins-slave-test-zigi" [label = "aws_instance.jenkins-slave-test-zigi", shape = "box"]
		"[root] aws_internet_gateway.jenkins" [label = "aws_internet_gateway.jenkins", shape = "box"]
		"[root] aws_route_table.jenkins" [label = "aws_route_table.jenkins", shape = "box"]
		"[root] aws_route_table_association.a" [label = "aws_route_table_association.a", shape = "box"]
		"[root] aws_security_group.internal" [label = "aws_security_group.internal", shape = "box"]
		"[root] aws_security_group.jenkins-master-public" [label = "aws_security_group.jenkins-master-public", shape = "box"]
		"[root] aws_security_group.office" [label = "aws_security_group.office", shape = "box"]
		"[root] aws_security_group.outbound" [label = "aws_security_group.outbound", shape = "box"]
		"[root] aws_subnet.jenkins" [label = "aws_subnet.jenkins", shape = "box"]
		"[root] aws_vpc.jenkins" [label = "aws_vpc.jenkins", shape = "box"]
		"[root] data.aws_ami.jenkins-master-image" [label = "data.aws_ami.jenkins-master-image", shape = "box"]
		"[root] data.aws_ami.jenkins-slave-image" [label = "data.aws_ami.jenkins-slave-image", shape = "box"]
		"[root] provider.aws" [label = "provider.aws", shape = "diamond"]
		"[root] aws_eip.jenkins-master-test-zigi-ip" -> "[root] aws_instance.jenkins-master-test-zigi"
		"[root] aws_eip.jenkins-slave-test-zigi-ip" -> "[root] aws_instance.jenkins-slave-test-zigi"
		"[root] aws_instance.jenkins-master-test-zigi" -> "[root] aws_internet_gateway.jenkins"
		"[root] aws_instance.jenkins-master-test-zigi" -> "[root] aws_security_group.internal"
		"[root] aws_instance.jenkins-master-test-zigi" -> "[root] aws_security_group.jenkins-master-public"
		"[root] aws_instance.jenkins-master-test-zigi" -> "[root] aws_security_group.office"
		"[root] aws_instance.jenkins-master-test-zigi" -> "[root] aws_security_group.outbound"
		"[root] aws_instance.jenkins-master-test-zigi" -> "[root] aws_subnet.jenkins"
		"[root] aws_instance.jenkins-master-test-zigi" -> "[root] data.aws_ami.jenkins-master-image"
		"[root] aws_instance.jenkins-slave-test-zigi" -> "[root] aws_internet_gateway.jenkins"
		"[root] aws_instance.jenkins-slave-test-zigi" -> "[root] aws_security_group.internal"
		"[root] aws_instance.jenkins-slave-test-zigi" -> "[root] aws_security_group.office"
		"[root] aws_instance.jenkins-slave-test-zigi" -> "[root] aws_security_group.outbound"
		"[root] aws_instance.jenkins-slave-test-zigi" -> "[root] aws_subnet.jenkins"
		"[root] aws_instance.jenkins-slave-test-zigi" -> "[root] data.aws_ami.jenkins-slave-image"
		"[root] aws_internet_gateway.jenkins" -> "[root] aws_vpc.jenkins"
		"[root] aws_route_table.jenkins" -> "[root] aws_internet_gateway.jenkins"
		"[root] aws_route_table_association.a" -> "[root] aws_route_table.jenkins"
		"[root] aws_route_table_association.a" -> "[root] aws_subnet.jenkins"
		"[root] aws_security_group.internal" -> "[root] aws_vpc.jenkins"
		"[root] aws_security_group.jenkins-master-public" -> "[root] aws_vpc.jenkins"
		"[root] aws_security_group.office" -> "[root] aws_vpc.jenkins"
		"[root] aws_security_group.outbound" -> "[root] aws_vpc.jenkins"
		"[root] aws_subnet.jenkins" -> "[root] aws_vpc.jenkins"
		"[root] aws_vpc.jenkins" -> "[root] provider.aws"
		"[root] data.aws_ami.jenkins-master-image" -> "[root] provider.aws"
		"[root] data.aws_ami.jenkins-slave-image" -> "[root] provider.aws"
		"[root] root" -> "[root] aws_eip.jenkins-master-test-zigi-ip"
		"[root] root" -> "[root] aws_eip.jenkins-slave-test-zigi-ip"
		"[root] root" -> "[root] aws_route_table_association.a"
	}
}
```
We can also paste the graph in the following [site](http://www.webgraphviz.com/) and see a more visual representation of our graph. Heres how it looks like: 
![](https://github.com/ironSource/ci-cd-from-scratch/blob/master/src/tutorial/images/Screenshot%202017-03-12%2017.45.06.png)

Pretty neat!

Next, building our images with packer.

[Previous chapter: 3-AWS-Subnets](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/3-aws-subnets) 

[Next chapter: 5-Packer-master](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/5-packer-master) 
