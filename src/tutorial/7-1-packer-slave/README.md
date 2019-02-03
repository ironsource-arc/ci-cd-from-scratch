At ironSource infra team, we are responsible for developing an automation framework to help test our various products.

## Setting up jenkins slave - Part 1

So the slave is almost identical to the master. It installs the same basic linux packages with some minor tweaks. I'm just gonna show you the end result without delving into every single package.

```json
{
  "variables": {
    "aws_access_key": "{{env `TF_VAR_access_key`}}",
    "aws_secret_key": "{{env `TF_VAR_secret_key`}}"
    "home": "{{env `YOUR_HOME_FOLDER`}}"
  },
  "builders": [{
    "type": "amazon-ebs",
    "access_key": "{{user `aws_access_key`}}",
    "secret_key": "{{user `aws_secret_key`}}",
    "region": "eu-central-1",
    "source_ami": "ami-XXXXXXXX",
    "instance_type": "t2.micro",
    "ssh_username": "ubuntu",
    "ami_name": "packer-jenkins-slave-test {{timestamp}}"
  }],
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
    ]},
    {
      "type":"shell",
      "inline": [
        "sudo apt-get install -y python-pip aufs-tools software-properties-common ansible python-pycurl linux-image-extra-$(uname -r) apt-transport-https ca-certificates unzip libwww-perl default-jre libdatetime-perl ntp htop iotop ruby",
        "sudo reboot",
        "sleep 60"
      ]
    },
    {
      "type": "shell",
      "inline": [
        "sudo pip install boto docker-py",
        "sudo pip install --upgrade jinja2",
        "sudo ansible-galaxy install angstwad.docker_ubuntu",
        "sudo chown -R ubuntu:ubuntu /home/ubuntu/.ansible"
      ]
    },
    {
      "type": "ansible-local",
      "role_paths": [
        "{{ user `home` }}/ci-cd-from-scratch/packer/roles/common-basic",
        "{{ user `home` }}/ci-cd-from-scratch/packer/roles/jenkins-basic",
        "{{ user `home` }}/ci-cd-from-scratch/packer/roles/jenkins-slave-basic"
      ],
      "playbook_file": "jenkins-slave-provision.yml"
    }]
}
```
If you noticed, we got some unique packages we install only on the slave - like ruby.
We also have the same common-basic role that we used while building the master, and a specific role that is used only by the jenkins slave: jenkins-slave-basic. 
We will view that role later. The ansible playbook we are using is also different. Lets see what `jenkins-slave-provision.yml` looks like
```yml
---
- hosts: 127.0.0.1
  become: yes
  vars:

  tasks:
    - name: Install awscli
      pip: name='awscli'
  roles:
    - role: common-basic
    - role: jenkins-slave-basic
    - { role: jenkins-basic,
        jenkins_home: '/home/jenkins/'
      }
    - role: angstwad.docker_ubuntu
      pip_install_docker_compose: true
      pip_install_docker_py: true
      pip_version_docker_compose: latest
      docker_opts: "--log-driver=json-file --log-opt max-size=10m --log-opt max-file=1"
      docker_group_members: ['ubuntu', 'jenkins']
```
The script installs aws cli, and applies our roles. We got the `common-basic` role that we are well acquainted with, the `jenkins-slave-basic` role that ensures a jenkins user exists or it creates one, 
and a `jenkins-basic` role that copies our ssh keys to allow us to connect via ssh from the master to the slave and vice versa (more on that later).
The role `angstwad.docker_ubuntu` is a role that will install docker on the slave. It requires some variables that we need to pass to it, but we are not going to go over them as they are currently not important
for the understanding of the playbook.
For more information on the angstwad.docker_ubuntu role, go to the documentation on github. Available [here](https://github.com/angstwad/docker.ubuntu).

Lets see it in action. 

```sh
$ cd tutorial/setting-up-packer-slave-part-1/files/packer

$ packer build jenkins-slave.json
```
```
    . . .
    . . .
    amazon-ebs: TASK [angstwad.docker_ubuntu : Set docker HTTP_PROXY if docker_http_proxy defined] ***
    amazon-ebs: skipping: [127.0.0.1]
    amazon-ebs:
    amazon-ebs: TASK [angstwad.docker_ubuntu : Set docker HTTPS_PROXY if docker_https_proxy defined] ***
    amazon-ebs: skipping: [127.0.0.1]
    amazon-ebs:
    amazon-ebs: TASK [angstwad.docker_ubuntu : Start docker] ***********************************
    amazon-ebs: ok: [127.0.0.1]
    amazon-ebs:
    amazon-ebs: TASK [angstwad.docker_ubuntu : Start docker.io] ********************************
    amazon-ebs: skipping: [127.0.0.1]
    amazon-ebs:
    amazon-ebs: TASK [angstwad.docker_ubuntu : Add users to the docker group] ******************
    amazon-ebs: changed: [127.0.0.1] => (item=ubuntu)
    amazon-ebs: changed: [127.0.0.1] => (item=jenkins)
    amazon-ebs:
    amazon-ebs: TASK [angstwad.docker_ubuntu : update facts if docker0 is not defined] *********
    amazon-ebs: ok: [127.0.0.1]
    amazon-ebs:
    amazon-ebs: TASK [Install awscli] **********************************************************
    amazon-ebs: changed: [127.0.0.1]
    amazon-ebs:
    amazon-ebs: PLAY RECAP *********************************************************************
    amazon-ebs: 127.0.0.1                  : ok=34   changed=20   unreachable=0    failed=0
    amazon-ebs:
==> amazon-ebs: Stopping the source instance...
==> amazon-ebs: Waiting for the instance to stop...
==> amazon-ebs: Creating the AMI: packer-jenkins-slave-test 1489783908
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
We need to refresh terraform and change the code to pull the packer image for the slave. 
I added the final terraform file to the files folder and updated the tf config to use the packer image. All we need is to apply.
```sh
$ terraform apply
. . .
. . .
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```
All our roles and tasks were successful. Lets find the ip and connect to the slave via ssh

```sh
$ aws ec2 describe-instances --region eu-central-1 --output json \
    --filter "Name=tag:Name,Values=*jenkins-slave*" \
    --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value, PublicIpAddress]"

[
    [
        [
            "jenkins-slave-test-zigi"
        ],
        "111.112.113.114"
    ]
]
```
Now we need to connect to the machine.
```sh
$ ssh 111.112.113.114

The authenticity of host '111.112.113.114 (111.112.113.114)' can't be established.
ECDSA key fingerprint is SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '111.112.113.114' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 16.04.2 LTS (GNU/Linux 4.4.0-67-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  Get cloud support with Ubuntu Advantage Cloud Guest:
    http://www.ubuntu.com/business/services/cloud

0 packages can be updated.
0 updates are security updates.


_____________________________________________________________________
WARNING! Your environment specifies an invalid locale.
 The unknown environment variables are:
   LC_CTYPE=UTF-8 LC_ALL=
 This can affect your user experience significantly, including the
 ability to manage packages. You may install the locales by running:

   sudo apt-get install language-pack-UTF-8
     or
   sudo locale-gen UTF-8

To see all available language packs, run:
   apt-cache search "^language-pack-[a-z][a-z]$"
To disable this message for all users, run:
   sudo touch /var/lib/cloud/instance/locale-check.skip
_____________________________________________________________________

ubuntu@ip-10-0-1-241:~$
```
Success! 

Next, we will update our master to configure jenkins. We will add all the ansible scripts that we removed to keep things simple.

[Previous chapter: 6-Packer-master](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/6-packer-master) 

[Next chapter: 7-2-Packer](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/7-2-packer) 
