At ironSource infra team, we are responsible for developing an automation framework to help test our various products.

## Setting up packer - Part 2

Lets take packer out for a spin.
By the end of this chapter we will deploy our first packer image to aws and connect to it as an ssh user.
But first, We have a small debt that we need to repay from the previous chapter. I mentioned that we are using [Ansible](https://www.ansible.com/) as a provisioning script but I did not explain what Ansible is.  

### Ansible
>Ansible is an open source automation platform. It is very, very simple to setup and yet powerful. Ansible can help you with configuration management, application deployment, task automation. 
>It can also do IT orchestration, where you have to run tasks in sequence and create a chain of events which must happen on several different servers or devices

Using a simple yml format, Ansible can run our provisioning script and ensure idempotency (An operation is idempotent if the result of performing it once is exactly the same as the 
result of performing it repeatedly without any intervening actions).
To keep things simple we will simplify that last Ansible provision script. We will only add the parts that will allow us to ssh into the machine for now. Lets take a look at that script.
```yaml
---
- hosts: 127.0.0.1
  become: yes
  vars:
  roles:
    - role: common-basic
```
Nothing special. `- hosts: 127.0.0.1` tells Ansible it needs to run its provision script on localhost.`become: yes` runs the script as root. 
No vars are currently needed. Lastly we specify which role the script needs to run. Roles are like Ansible modules that can be used by multiple scripts.
We will use the same role - `common-basic` when we provision the slave. Lets look at the role directory tree. 
```sh
$ tree 6-packer-master/files/packer/roles

└── common-basic
    ├── files
    │   └── authorized_keys
    └── tasks
        └── main.yml

3 directories, 2 files
```

So we have an `authorized_keys` file and a `main.yml` file. The `authorized_keys` file contains our ssh key. The `main.yml` file contains the provision script of the role. Here it is: 
```yml
---
  - name: ensures /home/ubuntu/.ssh dir exists
    file: path=/home/ubuntu/.ssh state=directory
  - name: copy public keys
    copy:
        src=authorized_keys
        dest=/home/ubuntu/.ssh/authorized_keys
        owner=ubuntu
        group=ubuntu
        mode=0644
    retries: 5
    delay: 2
    ignore_errors: yes
  - name: Install dependencies
    apt:
        name={{ item }}
        update_cache=yes
    with_items:
        - ntp
```
Each task in the file gets a name and the command to perform. The first task makes sure we have a directory called `.ssh` in the root directory of the ubuntu user.
The second copies our local `authorized_keys` file to the `.ssh` folder and gives it the needed permissions. You can also specify retries and set a delay between each retry.
Last task installs the linux package ntp to synchronize watches between our servers. The `authorized keys` file needs to contain your public ssh key.
If you don't have an ssh public key you can follow [this guide](https://confluence.atlassian.com/bitbucketserver/creating-ssh-keys-776639788.html) and create one, 
or simply use the public and private ssh keys I provided (You will still need to follow the guide if you dont know where to put them).
To use your own key, copy your public key to the authorized keys file like this:
```sh
$ cat id_rsa.pub >> authorized_keys
```
Now that we know what's what, we are really going to enjoy seeing it all in action. Lets run packer!

### Creating an AMI with packer

There is a file called jenkins-master in the following path: `tutorial/6-packer-master/files/packer/jenkins-master.json`
We are going to use it to create our first ami!
```sh
$ cd tutorial/6-packer-master/files/packer

$ packer build jenkins-master.json
```

Replace the xxxx with your access keys and you are ready to go!
Heres a summary of the output: 
```
amazon-ebs output will be in this color.

==> amazon-ebs: Prevalidating AMI Name...
    amazon-ebs: Found Image ID: ami-XXXXXXXX
==> amazon-ebs: Creating temporary keypair: packer_58ca54cf-7ebc-f049-9abb-5f3d666e0bb3
==> amazon-ebs: Creating temporary security group for this instance...
==> amazon-ebs: Authorizing access to port 22 the temporary security group...
==> amazon-ebs: Launching a source AWS instance...
    amazon-ebs: Instance ID: i-03d33848a634248ec
==> amazon-ebs: Waiting for instance (i-03d33848a634248ec) to become ready...
==> amazon-ebs: Waiting for SSH to become available...
==> amazon-ebs: Connected to SSH!
==> amazon-ebs: Provisioning with shell script: /var/folders/rd/z87crhfd0xd8176qtspsyvgc0000gp/T/packer-shell022855247
... 
... 
    amazon-ebs: Calculating upgrade...
    amazon-ebs: The following packages will be REMOVED:
    amazon-ebs: snapd
    amazon-ebs: The following NEW packages will be installed:
    amazon-ebs: linux-headers-4.4.0-67 linux-headers-4.4.0-67-generic
... 
... 
    amazon-ebs: Preparing to unpack .../gcc-5_5.4.0-6ubuntu1~16.04.4_amd64.deb ...
    amazon-ebs: Unpacking gcc-5 (5.4.0-6ubuntu1~16.04.4) ...
    amazon-ebs: Selecting previously unselected package gcc.
    amazon-ebs: Preparing to unpack .../gcc_4%3a5.3.1-1ubuntu1_amd64.deb ...
    amazon-ebs: Unpacking gcc (4:5.3.1-1ubuntu1) ...
    amazon-ebs: Selecting previously unselected package libstdc++-5-dev:amd64.
    amazon-ebs: Preparing to unpack .../libstdc++-5-dev_5.4.0-6ubuntu1~16.04.4_amd64.deb ...
... 
... 
==> amazon-ebs: Provisioning with Ansible...
    amazon-ebs: Creating Ansible staging directory...
    amazon-ebs: Creating directory: /tmp/packer-provisioner-ansible-local
    amazon-ebs: Uploading main Playbook file...
    amazon-ebs: Uploading inventory file...
    amazon-ebs: Uploading role directories...
    amazon-ebs: Creating directory: /tmp/packer-provisioner-ansible-local/roles/common-basic
    amazon-ebs: Executing Ansible: cd /tmp/packer-provisioner-ansible-local && ANSIBLE_FORCE_COLOR=1 PYTHONUNBUFFERED=1 ansible-playbook /tmp/packer-provisioner-ansible-local/jenkins-master-provision.yml -c local -i /tmp/packer-provisioner-ansible-local/packer-provisioner-ansible-local217790869
    amazon-ebs:
    amazon-ebs: PLAY [127.0.0.1] ***************************************************************
    amazon-ebs:
    amazon-ebs: TASK [setup] *******************************************************************
    amazon-ebs: ok: [127.0.0.1]
    amazon-ebs:
    amazon-ebs: TASK [common-basic : ensures /home/ubuntu/.ssh dir exists] *********************
    amazon-ebs: ok: [127.0.0.1]
    amazon-ebs:
    amazon-ebs: TASK [common-basic : copy public keys] *****************************************
    amazon-ebs: changed: [127.0.0.1]
    amazon-ebs:
    amazon-ebs: TASK [common-basic : Install dependencies] *************************************
    amazon-ebs: ok: [127.0.0.1] => (item=[u'ntp'])
    amazon-ebs:
    amazon-ebs: PLAY RECAP *********************************************************************
    amazon-ebs: 127.0.0.1                  : ok=4    changed=1    unreachable=0    failed=0
    amazon-ebs:
==> amazon-ebs: Stopping the source instance...
==> amazon-ebs: Waiting for the instance to stop...
==> amazon-ebs: Creating the AMI: packer-jenkins-master-test 1489657343
    amazon-ebs: AMI: ami-XXXXXXXX
==> amazon-ebs: Waiting for AMI to become ready...
==> amazon-ebs: Creating the AMI: packer-jenkins-master-test 1489657343
    amazon-ebs: AMI: ami-XXXXXXXX
==> amazon-ebs: Waiting for AMI to become ready...
==> amazon-ebs: Terminating the source AWS instance...
==> amazon-ebs: Cleaning up any extra volumes...
==> amazon-ebs: No volumes to clean up, skipping
==> amazon-ebs: Deleting temporary security group...
==> amazon-ebs: Deleting temporary keypair...
Build 'amazon-ebs' finished.
```

So what are we seeing? Packer created an AMI for us. It spun up an instance of the basic Ubuntu AMI image, connected to it using temporary ssh keys, 
and started installing everything we wanted, installing and upgrading all the Ubuntu packages we told it to. 
At the end packer ran our simple Ansible provision script to add our keys to the machine.

We are going to recreate our AWS infrastructure in case you destroyed it. I added the tf file we are going to use to create the entire VPC.
Now we have a packer ami to use as our basic ami so we are going to replace the jenkins-master AMI with the one we created just now, like this: 
```terraform
data "aws_ami" "jenkins-master-image" {
  most_recent = true
  name_regex = "^packer-jenkins-master-test"
}
```

Lets recreate everything:
```sh
$ cd files/terraform
$ terraform apply
```

Now that our infrastructure is ready, lets find our new jenkins instance. You can either use the UI to obtain the IP of the jenkins master that we created, or the aws cli tool to find the IP. 
Here is the command you can run with the aws cli tool(complete installation instructions can be found [here](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)):

```sh
$ pip install --upgrade --user awscli
$ aws configure set aws_access_key_id XXXXXXXXXX
$ aws configure set aws_secret_access_key XXXXXXXXXXXXXXXXXXXX
$ aws ec2 describe-instances --region eu-central-1 --output json \
    --filter "Name=tag:Name,Values=*jenkins-master*" \
    --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value, PublicIpAddress]"

[
    [
        [
            "jenkins-master-test-zigi"
        ],
        "255.254.253.252"
    ]
]
```

Now we need to connect to the machine.
```sh
$ ssh 255.254.253.252

The authenticity of host '255.254.253.252 (255.254.253.252)' can't be established.
ECDSA key fingerprint is SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '255.254.253.252' (ECDSA) to the list of known hosts.
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
Yes! We are inside and ready to roll! We have made some real progress in this chapter. Next, we will take a look at the packer configuration for the slave we are creating.
As a reminder, you can run `$ terraform destroy` for a quick and painless destruction of your infrastructure if you feel like you need a short break and you don't want to keep paying money.
Also, an ami costs around 0.01 cent a month (don't take me up by the word for it) So you can also delete those by yourself if you would like.

[Previous chapter: 5-Packer-master](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/5-packer-master) 

[Next chapter: 7-1-Packer-slave](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/7-1-packer-slave) 
