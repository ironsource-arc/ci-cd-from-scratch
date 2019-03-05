> At ironSource infrastructure team, we are responsible for developing an automation framework to help test our various products.

## Setting up packer

## What is packer?

> Packer is a tool for creating machine and container images for multiple platforms from a single source configuration.

We use [packer](https://www.packer.io) to create pre-configured AMI's. We will create 2 AMI's. One for the slave, and one for our master. 
It's a pretty simple tool, and like always we are gonna try and keep it as simple as we can. Packer uses json format configuration files to create images. 
It's got a `variables` section to set up our aws access keys, It's got a `builders` section to define the base AMI we are going to use and some general image configuration, 
and the most interesting section is the `provisioners` section which will install everything we want on our pre baked machine.

Go ahead and install packer and once you return we can continue with our tutorial.

Good to have you back.

We are going to dive head first into the world of packer and view every part of the configuration file.
```json
{
  "variables": {
    "aws_access_key": "{{env `TF_VAR_access_key`}}",
    "aws_secret_key": "{{env `TF_VAR_secret_key`}}",
    "home": "{{env `YOUR_HOME_FOLDER`}}"
  }
}
```
First part is specifying the aws access variables. We will use the same environment variables we created for working 
with terraform as the environment variables to pass to packer. I also created an environment variable for my home folder
home. You can replace YOUR_HOME_FOLDER with your home directory or set an absolute path without an env variable

Moving on to the builders section.
```json
{
  "builders": [{
    "type": "amazon-ebs",
    "access_key": "{{user `aws_access_key`}}",
    "secret_key": "{{user `aws_secret_key`}}",
    "region": "eu-central-1",
    "source_ami": "ami-XXXXXXXX",
    "instance_type": "t2.micro",
    "ssh_username": "ubuntu",
    "ami_name": "packer-jenkins-slave-test {{timestamp}}"
  }]
}
```
Real easy. First we specify the type of image we are creating. We are using the basic aws elastic block storage, or in short [EBS](https://aws.amazon.com/ebs/).

>Amazon EBS allows you to create storage volumes and attach them to Amazon EC2 instances. Once attached, you can create a file system on top of these volumes, run a database, or use them in any other way you would use block storage. Amazon EBS volumes are placed in a specific Availability Zone, where they are automatically replicated to protect you from the failure of a single component. All EBS volume types offer durable snapshot capabilities and are designed for 99.999% availability.

The access keys and secrets are taken from the variables we previously defined. Provide the region we are working on, same as we did in terraform. 
The source ami we are going to use is just a basic ubuntu 16.04 image. Same one we used in the previous chapter. Instance type is t2.micro which is eligible for free tier pricing.
The user for ssh connections and the name of the ami - packer-jenkins-slave-test plus a timestamp.
In case we need to build packer more than once, adding a timestamp will allow us to create multiple instances with a unique name. Terraform will just pick up the last successfully built image.

Now moving on to the provisioners section. This is where packer shines. Lets look at the first part. 
```json
"provisioners": [{
  "type": "shell",
  "inline": [
    "sleep 240",
    "sudo apt-add-repository -y ppa:ansible/ansible",
    "sudo apt-get update",
    "sudo apt-get -y dist-upgrade",
    "sudo apt-get install -y unattended-upgrades",
    "sudo unattended-upgrades",
    "sudo reboot",
    "sleep 60"
  ]}]
```
We can use multiple types of provisioning tool. For every provisioning section we specify the type, in this case a shell, and the actual provisioning script to run.
We use an inline shell provisioning script that waits until the machine boots up, installs the ansible repository, updates apt-get and installs some linux packages and then 
reboots and goes to sleep for a minute. Lets look at the next provision script: 
```json
"provisioners": [{
    "type":"shell",
    "inline": [
      "sudo apt-get install -y python-pip aufs-tools software-properties-common ansible python-pycurl linux-image-extra-$(uname -r) apt-transport-https ca-certificates unzip libwww-perl default-jre libdatetime-perl ntp htop iotop ruby",
      "sudo reboot",
      "sleep 60"
    ]
    }]
```

You guessed it. Installing some more linux stuff. We got ansible installed, as
well as java, python, ruby, and some other packages we are going to use later (You are more than welcomed to dig deeper and check what all of those packages are about). 
Rebooting again to let the changes take affect, and then sleeping until the vm boots up again.

Next!
```json
"provisioners": [{
      "type": "shell",
      "inline": [
        "sudo pip install boto docker-py",
        "sudo pip install --upgrade jinja2",
        "sudo ansible-galaxy install angstwad.docker_ubuntu",
        "sudo chown -R ubuntu:ubuntu /home/ubuntu/.ansible"
      ]
    }]
```
Lets review the packages this provisioners script installs:
We install boto and docker-py using the python package manager, pip. Boto is a
python package that provides an interface to the aws cli. Docker-py is python
library for the docker engine api. Upgrading jinja tools which is a templating
engine for ansible. Ansible galaxy is the package manager for ansible and we
also install an ansible package that will provide an easy docker installation.
Changing the ownership of the ansible folder is needed to run our ansible
provisioning script using user ubuntu.

We are down to the last provisioning script in the provisioners section but as always, we saved the best for last. Lets take a look:

```json
"provisioners": [{
      "type": "ansible-local",
      "role_paths": [
        "{{ user `home` }}/ci-cd-from-scratch/packer/roles/common-basic",
        "{{ user `home` }}/ci-cd-from-scratch/packer/roles/jenkins-slave-basic"
      ],
      "playbook_file": "jenkins-slave-provision.yml"
    }]
```

This is an ansible provision script. It will run the ansible script `jenkins-slave-provision.yml` from the vm itself and install the jenkins server, ssh keys, jenkins plugins and a whole lot more. Lets take a step back and see what happens when we run this thing.

[Previous chapter: 4-AWS-AMI-EC2](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/4-aws-ami-ec2) 

[Next chapter: 6-Packer-master](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/6-packer-master) 
