> At ironSource infra team, we are responsible for developing an automation framework to help test our various products.

## Setting up the Amazon network - Part 1

We are going to deploy our jenkins master and server under Amazon Web Services (AWS). AWS has some great tools and features that will allow us to use our servers in a production like environment, using our very own secure network. 
If you don't have an aws account go and [create one now](https://aws.amazon.com). You are going to need the aws access_key and the secret_key to continue with this tutorial. You can find them [here](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html).

We are not going to bother with the Amazon Console. We are going to create all the necessary AWS components using [terraform](https://www.terraform.io/)! If you don't know terraform. Here is a short description

>Terraform enables you to safely and predictably create, change, and improve production infrastructure. It is an open source tool that codifies APIs into declarative configuration files that can be shared amongst team members, treated as code, edited, reviewed, and versioned.

What it means is that we can use a configuration file to setup our aws with code, we can track it under a version control system and deploy or destroy it whenever we want. Lets start by breaking the components down and explaining what each part does.

```terraform
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

```

First we are going to configure our AWS account credentials. You can find your access key here: https://<%your aws console url%>/home?region=eu-central-1#/users/<USER_NAME>. You can choose whatever region you want but the rest of the tutorial will assume we are building our infrastructure under region eu-central-1. You can save the
aws access keys in a separate terraform variables file: `variables.tf` This is how he looks like: 
```
$ cat src/tutorial/2-aws/ex1/variables.tf
variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-east-1"
}
```

Lets start with the hands on part of our tutorial. Please clone this project and cd into the directory of the first exercise. 
``` sh
$ git clone https://github.com/ironSource/ci-cd-from-scratch.git
$ cd ci-cd-from-scratch/src/tutorial/setting-up-amazon-network/ex1
```
Go ahead and fill in your information in the variables file.

Next we will define our vpc, but first, what is a VPC?

>Amazon Virtual Private Cloud (Amazon VPC) enables you to launch Amazon Web Services (AWS) resources into a virtual network that you've defined. This virtual network closely resembles a traditional network that you'd operate in your own data center, with the benefits of using the scalable infrastructure of AWS.

VPC is a virtual private network. It will enable us to create this tutorial in a completely confined environment without having conflicts with other team members or departments sharing the same aws account as us. Usually, every team will have its own VPC as the top level layer it needs to maintain and be responsible for.

Here is the terraform snippet we use to define our VPC
```terraform
resource "aws_vpc" "jenkins" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
      Name = "jenkins"
  }
}
```

The cidr_block defines the network address range that will be assigned to us. In this example we are assigning internal addresses starting with 10.0.0.0 up to 10.0.255.255. The 16 mask means the first 16 bits out of 32 are reserved which gives us an address space of 65,536. Should be enough..

The DNS hostnames flag enables DNS support in our VPC, and the tags section names the VPC. We are gonna call ours jenkins!

Continuing with the hands on part of our tutorial, run the following command: 
``` sh
$ terraform plan
```

Heres the expected output:
```
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but
will not be persisted to local or remote state storage.


The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed. Cyan entries are data sources to be read.

Note: You didn't specify an "-out" parameter to save this plan, so when
"apply" is called, Terraform can't guarantee this is what will execute.

+ aws_vpc.jenkins
    cidr_block:                "10.0.0.0/16"
    default_network_acl_id:    "<computed>"
    default_route_table_id:    "<computed>"
    default_security_group_id: "<computed>"
    dhcp_options_id:           "<computed>"
    enable_classiclink:        "<computed>"
    enable_dns_hostnames:      "true"
    enable_dns_support:        "true"
    instance_tenancy:          "<computed>"
    main_route_table_id:       "<computed>"
    tags.%:                    "1"
    tags.Name:                 "jenkins"


Plan: 1 to add, 0 to change, 0 to destroy. 
```

Terraform plan shows you what is going to be created when you run ```terraform apply```. Now lets create the VPC
``` sh
$ terraform apply
```

Heres the output of the apply command: 
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

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```

As you can see, our VPC has been created. Head over to the amazon web UI if you want to see your new VPC in action.

Notice that after we ran ```terraform apply``` a new file has been created in our directory.
``` sh
$ cd ci-cd-from-scratch/src/tutorial/2-aws/ex1
$ ls -la 

total 32
drwxr-xr-x  6 daniel.zinger  staff   204 Mar 27 23:23 .
drwxr-xr-x  4 daniel.zinger  staff   136 Jun 11 23:36 ..
-rw-r--r--  1 daniel.zinger  staff   416 Mar 27 23:21 jenkins.tf
-rw-r--r--  1 daniel.zinger  staff  2234 Mar  5 23:52 terraform.tfstate
-rw-r--r--  1 daniel.zinger  staff   316 Mar  5 23:52 terraform.tfstate.backup
-rw-r--r--  1 daniel.zinger  staff    96 Jun 12 00:51 variables.tf
```
The terraform.tfstate file is used to preserve the state of our infrastructure. It can be shared and version controlled to enable collaboration between different team members. 

We are not going to use this file for our development process but its a good thing to know its there. 

OK, now that we played around a little bit with our new infrastructure its time to destroy it. Cleaning up all the resources we created using terraform couldn't be easier.
From the ex1 folder run the following command: 
```sh
$ terraform destroy

Do you really want to destroy?
  Terraform will delete all your managed infrastructure.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_vpc.jenkins: Refreshing state... (ID: vpc-c7a514af)
aws_vpc.jenkins: Destroying...
aws_vpc.jenkins: Destruction complete

Destroy complete! Resources: 1 destroyed.
```

That's it! No one will even know we were there..

Now for the sad news.. I'm not going to provide any more exercise files :( 
But have no fear! You can copy and paste all the snippets from the following tutorials to the provided jenkins tf file and gradually build your infrastructure as we go.. 
Now this is important: do not change directories when working on your terraform configuration. If you change the directory from which you 
run your terraform files you might end up with duplicate cloud configurations.

That wraps our first hands on section, lets move on to the next part - setting up amazon network part 2 - subnets

[Previous chapter: 1-Getting-Started](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/1-getting-started) 

[Next chapter: 3-AWS-Subnets](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/3-aws-subnets) 
