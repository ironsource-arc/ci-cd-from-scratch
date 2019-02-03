At ironSource infra team, we are responsible for developing an automation framework to help test our various products.

## Packer - Hands on

Lets see it all in action. In the exercise you will find all the code needed to test our almost complete infrastructure.
We got the terraform setup in place and also all the packer configuration we will need and all the roles. 
Here is the directory structure: 

```sh
$ tree 8-deploy/files

files
├── packer
│   ├── jenkins-master-provision.yml
│   ├── jenkins-master.json
│   ├── jenkins-slave-provision.yml
│   ├── jenkins-slave.json
│   └── roles
│       ├── common-basic
│       │   ├── files
│       │   │   └── authorized_keys
│       │   └── tasks
│       │       └── main.yml
│       ├── jenkins-basic
│       │   ├── defaults
│       │   │   └── main.yml
│       │   ├── files
│       │   │   ├── authorized_keys
│       │   │   ├── jenkins_rsa
│       │   │   └── jenkins_rsa.pub
│       │   └── tasks
│       │       └── main.yml
│       ├── jenkins-jobs
│       │   ├── files
│       │   │   └── jenkins-test-webapp.xml
│       │   └── tasks
│       │       └── main.yml
│       ├── jenkins-plugins
│       │   └── tasks
│       │       └── main.yml
│       └── jenkins-slave-basic
│           ├── files
│           │   ├── authorized_keys
│           │   ├── jenkins_rsa
│           │   └── jenkins_rsa.pub
│           └── tasks
│               └── main.yml
└── terraform
    └── jenkins.tf
    └── variables.tf
```

We will start with building the images for the slave and master.

```sh
$ cd 8-deploy/files/packer
$ packer build jenkins-slave.json
. . .
. . .
==> amazon-ebs: Creating the AMI: packer-jenkins-slave-test 1490451877
    amazon-ebs: AMI: ami-XXXXXXXX
==> amazon-ebs: Waiting for AMI to become ready...
==> amazon-ebs: Terminating the source AWS instance...
==> amazon-ebs: Cleaning up any extra volumes...
==> amazon-ebs: No volumes to clean up, skipping
==> amazon-ebs: Deleting temporary security group...
==> amazon-ebs: Deleting temporary keypair...
Build 'amazon-ebs' finished.

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:

eu-central-1: ami-XXXXXXXX```

```sh
$ packer build \
    jenkins-master.json

. . .
. . .
==> amazon-ebs: Stopping the source instance...
==> amazon-ebs: Waiting for the instance to stop...
==> amazon-ebs: Creating the AMI: packer-jenkins-master-test 1490450591
    amazon-ebs: AMI: ami-XXXXXXXX
==> amazon-ebs: Waiting for AMI to become ready...
==> amazon-ebs: Terminating the source AWS instance...
==> amazon-ebs: Cleaning up any extra volumes...
==> amazon-ebs: No volumes to clean up, skipping
==> amazon-ebs: Deleting temporary security group...
==> amazon-ebs: Deleting temporary keypair...
Build 'amazon-ebs' finished.

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:

eu-central-1: ami-XXXXXXXX
```
Looks good! Lets apply the terraform setup on aws again
```sh
$ cd 8-deploy/files/terraform
$ terraform apply

aws_eip.jenkins-master-test-zigi-ip: Creation complete
aws_eip.jenkins-slave-test-zigi-ip: Creation complete

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```

As always, our resources have been created. 

Now to verify we have an ssh connection between the slave and the master. We need to find the ip of both of our instances. We can do that using aws cli
```sh
$ aws ec2 describe-instances --region eu-central-1 --output json \
    --filter "Name=tag:Name,Values=*jenkins*" \
    --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value, PublicIpAddress]"

[
    [
        [
            "jenkins-master-test-zigi"
        ], 
        "255.254.253.252"
    ], 
    [
        [
            "jenkins-slave-test-zigi"
        ], 
        "111.112.113.114"
    ]
]

```

Starting with the master, lets ssh into the instance
```sh
$ ssh 255.254.253.252

The authenticity of host '255.254.253.252 (255.254.253.252)' can't be established.
ECDSA key fingerprint is SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '255.254.253.252' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 16.04.2 LTS (GNU/Linux 4.4.0-67-generic x86_64)
. . .
. . .
ubuntu@ip-10-0-1-217:~$
```
Now lets check our ssh connection to the slave
```sh
$ ssh 111.112.113.114

The authenticity of host '111.112.113.114 (111.112.113.114)' can't be established.
ECDSA key fingerprint is SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '111.112.113.114' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 16.04.2 LTS (GNU/Linux 4.4.0-67-generic x86_64)
. . .
. . .
ubuntu@ip-10-0-1-205:~$
```
Now lets connect to the slave from our master instance. Remember that communication between the instances is performed under jenkins user and not under the default ubuntu user.
We will use the internal ip of the slave to connect from the master. Both the instances live in the same vpc so they can use internal communication for ssh connections.

```sh
ubuntu@ip-10-0-1-217:~$ sudo su - jenkins
jenkins@ip-10-0-1-217:~$ ssh jenkins@10.0.1.205

The authenticity of host '10.0.1.205 (10.0.1.205)' can't be established.
ECDSA key fingerprint is SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '10.0.1.205' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 16.04.2 LTS (GNU/Linux 4.4.0-66-generic x86_64)
. . .
. . .
jenkins@ip-10-0-1-205:~$
```

And now the other way around
```sh
ubuntu@ip-10-0-1-205:~$ sudo su - jenkins
jenkins@ip-10-0-1-205:~$ ssh jenkins@10.0.1.217

The authenticity of host …
Welcome to Ubuntu 16.04.2 LTS (GNU/Linux 4.4.0-66-generic x86_64)
. . .
. . .
jenkins@ip-10-0-1-217:~$
```

Everything is going according to plan. We can connect from the slave to the master and vice versa. 
Now its time to open up your favorite browser, and observe our glorious creation. 
Open the browser and type in the address of the master: 
`http://<%your jenkins url%>:8080`

In order to login you will need to obtain the initial admin password. The password is located in the file `/var/lib/jenkins/secrets/initialAdminPassword`

Connect to the master again and run the following command to print the password.
```sh
root@ip-10-0-1-205:/home/ubuntu# cat /var/lib/jenkins/secrets/initialAdminPassword
214a5bf711ad404fb860fdb7b08b4280
```

Log in to jenkins using the username `admin` and the password you found
When you log in you will see the following screen: 
![](https://github.com/ironSource/ci-cd-from-scratch/blob/master/src/tutorial/images/newjenkins.png)

Now lets look at the plugins we added. You can view the installed plugins in the following url:

`http://<%your jenkins url%>:8080/pluginManager/installed`

Thats it for this chapter. In the next chapter we will set up the jenkins slave via jenkins UI.

[Previous chapter: 7-2-Packer](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/7-2-packer) 

[Next chapter: 9-UI-Slave](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/9-UI-slave) 
