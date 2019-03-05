> At ironSource infrastructure team, we are responsible for developing an automation framework to help test our various products.

## Creating the Jenkins job - Part 4

In this chapter we will deploy our web server to aws! We will need to create an image for the web server using packer 
and we will need to adjust our terraform file to include the infrastructure needed for the web server. It will give us a 
good opportunity to review all the tools we used one last time.
We will start with the image creation using packer.
We will only look at the final result, as I'm sure you now have enough knowledge to figure everything out by yourself.
Here is the packer file for our sample web server:
```json
{
  "variables": {
    "aws_access_key": "{{env `TF_VAR_access_key`}}",
    "aws_secret_key": "{{env `TF_VAR_secret_key`}}"
  },
  "builders": [{
    "type": "amazon-ebs",
    "access_key": "{{user `aws_access_key`}}",
    "secret_key": "{{user `aws_secret_key`}}",
    "region": "eu-central-1",
    "source_ami": "ami-XXXXXXXX",
    "instance_type": "t2.micro",
    "ssh_username": "ubuntu",
    "ami_name": "jenkins-web-server {{timestamp}}"
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
        "sudo apt-get install -y python-pip aufs-tools software-properties-common ansible python-pycurl linux-image-extra-$(uname -r) apt-transport-https ca-certificates unzip libwww-perl libdatetime-perl ntp htop iotop ruby",
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
        "/Users/daniel.zinger/ci-cd-from-scratch/packer/roles/common-basic"
      ],
      "playbook_file": "jenkins-web-server-provision.yml"
    }]
}
```

Almost identical to the packer files we created for the slave and the master! Now lets take a look at the provision file: 
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
    - role: angstwad.docker_ubuntu
      pip_install_docker_compose: true
      pip_install_docker_py: true
      pip_version_docker_compose: latest
      docker_opts: "--log-driver=json-file --log-opt max-size=10m --log-opt max-file=1"
      docker_group_members: ['ubuntu']
```
Again, almost identical to the provision files we used for creating the slave and the master. Lets see that provision script in action
```
$ cd ci-cd-from-scratch/infra/packer
$ packer build \
    -var 'aws_access_key=XXXXXXXXXXXXXXXXXXX' \
    -var 'aws_secret_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' \
    jenkins-web-server.json

…
    amazon-ebs: TASK [Install awscli] **********************************************************
    amazon-ebs: changed: [127.0.0.1]
    amazon-ebs:
    amazon-ebs: PLAY RECAP *********************************************************************
    amazon-ebs: 127.0.0.1                  : ok=28   changed=15   unreachable=0    failed=0
    amazon-ebs:
==> amazon-ebs: Stopping the source instance...
==> amazon-ebs: Waiting for the instance to stop...
==> amazon-ebs: Creating the AMI: jenkins-web-server 1497104553
    amazon-ebs: AMI: ami-XXXXXXXX
==> amazon-ebs: Waiting for AMI to become ready...
==> amazon-ebs: Terminating the source AWS instance...
==> amazon-ebs: Cleaning up any extra volumes...
==> amazon-ebs: No volumes to clean up, skipping
==> amazon-ebs: Deleting temporary security group...
==> amazon-ebs: Deleting temporary keypair...
Build 'amazon-ebs' finished.
```

Next thing on our list is setting up the terraform infrastructure required to host this web server. 
We will need a new EC2 instance to host our app. We will use the image we just created with packer as our base image, 
It will require an internet connection for it to be accessible via the browser and internal access from our VPC for jenkins to be able
to deploy our app to our new EC2. 
Here is the new parts we added to our terraform file:
```

resource "aws_security_group" "jenkins-web-server-public" {
  name = "jenkins-web-server-public"
  description = "Jenkins web server internet access"
  vpc_id = "${aws_vpc.jenkins.id}"
  ingress {
    from_port = 80
    to_port = 80
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
data "aws_ami" "jenkins-web-server-image" {
  most_recent = true
  name_regex = "^jenkins-web-server"
}

resource "aws_instance" "jenkins-web-server-test-zigi" {
  ami           = "${data.aws_ami.jenkins-web-server-image.id}"
  instance_type = "t2.micro"
  depends_on = ["aws_internet_gateway.jenkins"]  
  subnet_id = "${aws_subnet.jenkins.id}"
  vpc_security_group_ids = [ 
    "${aws_security_group.office.id}", 
    "${aws_security_group.jenkins-web-server-public.id}", 
    "${aws_security_group.outbound.id}",
    "${aws_security_group.internal.id}"
  ]
  tags {
          Name = "jenkins-web-server-test-zigi"
      }
}

resource "aws_eip" "jenkins-web-server-test-zigi-ip" {
    instance = "${aws_instance.jenkins-web-server-test-zigi.id}"
}
```

We need to create a new security group that will enable http access over port 80 to our app, and internal tcp communication from your
development environment IP for all ports so we can connect to the instance over ssh. We specify the aws_ami we want to use, like we did
with the master and slave. We assign a new static IP for our web app. 
The aws instance specifies the ami to use, the instance type, it depends on the previously created internet gateway and on the basic
security groups so jenkins can connect to the machine and deploy our application. We give the instance a tag and that's it. 
Add the code to the global terraform file and hit `$ terraform apply`
Everything was deployed and all of our resources have been added! Hurray!

Okay, now that that is taken care of, lets review the missing piece in the puzzle, the deployment ansible file.
```
---
- hosts: webserver
  remote_user: ubuntu
  vars:
  tasks:
  - debug:
      msg: "deploying to aws"
  - name: Log into DockerHub
    docker_login:
      username: "jenkinsewebservertutorial"
      password: "XXXXXX"
      email: "zigius@mailinator.com"
  - name: pull image
    docker_image:
      name: "{{ image }}"
      tag: "{{ commit }}"
  - name: remove container
    docker_container:
      name: "{{ service }}"
      state: absent
  - name: start container
    docker_container:
      name: "{{ service }}"
      image: "{{ image }}:{{ commit }}"
      ports:
       - "80:8000"
      state: started

```

The file itself is pretty straight forward. The most important thing to notice is the hosts we run the script on. 
The jenkins slave will connect to the host via ssh to run the script on the webserver. 
We need to add the IP of the 
web server to the ansible inventory file. 
Please copy the ip address that was assigned to the web server during the terraform script 
execution (the private ip address), and add it to the ansible hosts configuration file - inventory.ini.

```
$ cat infra/inventory.ini

[webserver]
10.0.1.32

```

To use a custom inventory file we need to add the inventory file we would like to use as an extra variable of the ansible playbook module: 

```
stage ('DEPLOY') {
  steps {
    ansiblePlaybook(
      playbook: 'infra/deploy-playbook.yml',
      inventory: 'infra/inventory.ini', // our new inventory file
      extras: '-v',
      extraVars: [
        commit: env.GIT_COMMIT,
        image:  env.DOCKER_REPO,
        service: env.COMPONENT,
        environment: env.GIT_BRANCH,
        branch: env.GIT_BRANCH])
  }
}
```

So now we can return to the deploy-playbook.yml. As you can see the rest of the deployment is pretty simple. Logging in to docker hub, pulling the latest image, removing the old container, if there is a previous version, and starting the container and mapping port 80 to port 8000 so our application will be accessible under port 80 which is the default port while browsing the internet. 

Lets see it in action. Please run the job again and lets see the results: 

```
[ci-cd-from-scratch-webserver] $ ansible-playbook infra/deploy-playbook.yml -i infra/inventory.ini -e commit=a79ec65610afd758d5bce92a17915b3ff13d8ab4 -e image=jenkinsewebservertutorial/webserver -e service=jenkins-utils-webserver -e environment=staging -e branch=staging -v
Using /etc/ansible/ansible.cfg as config file

PLAY [webserver] ***************************************************************
 [WARNING]: The variable 'environment' appears to be used already, which is
also used internally for environment variables set on the task/block/play. You
should use a different variable name to avoid conflicts with this internal
variable

TASK [setup] *******************************************************************
ok: [222.223.224.225]

TASK [debug] *******************************************************************
ok: [222.223.224.225] => {
    "msg": "deploying to aws"
}
TASK [Log into DockerHub] ******************************************************
ok: [222.223.224.225] => {"actions": ["Logged into https://index.docker.io/v1/"], "changed": false, "login_result": {"email": "zigius@mailinator.com", "password": "VALUE_SPECIFIED_IN_NO_LOG_PARAMETER", "serveraddress": "https://index.docker.io/v1/", "username": "jenkinsewebservertutorial"}}

TASK [pull image] **************************************************************
changed: [222.223.224.225] => {"actions": ["Pulled image jenkinsewebservertutorial/webserver:a79ec65610afd758d5bce92a17915b3ff13d8ab4"], "changed": true, "image": {"Architecture": "amd64", "Author": "", "Comment": "", "Config": {"ArgsEscaped": true, "AttachStderr": false, "AttachStdin": false, "AttachStdout": false, "Cmd": ["npm", "start"], "Domainname": "", "Entrypoint": null, "Env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", "NPM_CONFIG_LOGLEVEL=info", "NODE_VERSION=7.7.3", "YARN_VERSION=0.21.3", "NODE_ENV=staging", "GIT_COMMIT=a79ec65610afd758d5bce92a17915b3ff13d8ab4"], "Healthcheck": {"Interval": 60000000000, "Retries": 3, "Test": ["CMD-SHELL", "curl --fail http://localhost:8000/health || exit 1"], "Timeout": 3000000000}, "Hostname": "ed11f485244a", "Image": "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "Labels": {}, "OnBuild": [], "OpenStdin": false, "StdinOnce": false, "Tty": false, "User": "", "Volumes": null, "WorkingDir": "/usr/src/app"}, "Container": "bcfe4d86d025d07b711cb254a770d3069af870e8fc826711b353360d80a47245", "ContainerConfig": {"ArgsEscaped": true, "AttachStderr": false, "AttachStdin": false, "AttachStdout": false, "Cmd": ["/bin/sh", "-c", "#(nop) ", "HEALTHCHECK &{[\"CMD-SHELL\" \"curl --fail http://localhost:8000/health || exit 1\"] \"1m0s\" \"3s\" '\\x03'}"], "Domainname": "", "Entrypoint": null, "Env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", "NPM_CONFIG_LOGLEVEL=info", "NODE_VERSION=7.7.3", "YARN_VERSION=0.21.3", "NODE_ENV=staging", "GIT_COMMIT=a79ec65610afd758d5bce92a17915b3ff13d8ab4"], "Healthcheck": {"Interval": 60000000000, "Retries": 3, "Test": ["CMD-SHELL", "curl --fail http://localhost:8000/health || exit 1"], "Timeout": 3000000000}, "Hostname": "ed11f485244a", "Image": "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "Labels": {}, "OnBuild": [], "OpenStdin": false, "StdinOnce": false, "Tty": false, "User": "", "Volumes": null, "WorkingDir": "/usr/src/app"}, "Created": "2017-06-03T12:40:11.68663261Z", "DockerVersion": "17.03.0-ce", "GraphDriver": {"Data": null, "Name": "aufs"}, "Id": "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "Os": "linux", "Parent": "", "RepoDigests": ["jenkinsewebservertutorial/webserver@sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"], "RepoTags": ["jenkinsewebservertutorial/webserver:a79ec65610afd758d5bce92a17915b3ff13d8ab4"], "RootFS": {"Layers": ["sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"], "Type": "layers"}, "Size": 685792886, "VirtualSize": 685792886}}

TASK [remove container] ********************************************************
changed: [222.223.224.225] => {"changed": true}

TASK [start container] *********************************************************
changed: [222.223.224.225] => {"ansible_facts": {}, "changed": true}

PLAY RECAP *********************************************************************
222.223.224.225               : ok=6    changed=3    unreachable=0    failed=0   

[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // withEnv
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS
```

Our web server was deployed successfully. Lets see the fruits of our labour: 

```
$ curl http://222.223.224.225/health
{"message":"up","commit":"a79ec65610afd758d5bce92a17915b3ff13d8ab4","branch":"staging"}
```

Amazing! That wraps up our tutorial boys and girls. The next chapter will include some closing words. We will talk about what lies ahead, and what can be improved by you to make the CI\CD process even more awesome.

[Previous chapter: 13-Create-job](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/13-create-job) 
