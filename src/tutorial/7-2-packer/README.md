> At ironSource infrastructure team, we are responsible for developing an automation framework to help test our various products.

## Setting up packer master - Missing pieces

The last time we were working on the master I mentioned we left some things out so we can keep things simple. 
Now we are ready to continue and see the scripts that are in charge of installing jenkins and its plugins.

```sh
$ tail -10 ~/jenkins-utils/packer/jenkins-master.json
. . .
. . .
{
  "type": "ansible-local",
  "role_paths": [
    "{{ user `home` }}/ci-cd-from-scratch/packer/roles/common-basic",
    "{{ user `home` }}/ci-cd-from-scratch/packer/roles/jenkins-plugins",
    "{{ user `home` }}/ci-cd-from-scratch/packer/roles/jenkins-jobs"
  ],
  "playbook_file": "jenkins-master-provision.yml"
}]

```
This is the last piece in the jenkins master packer file. 

Lets look at the full `jenkins-master-provision.yml` file: 
```yml
---
- hosts: 127.0.0.1
  become: yes
  vars:
  tasks:
    - name: Install awscli
      pip: name='awscli'
  roles:
    - role: geerlingguy.jenkins
    - role: angstwad.docker_ubuntu
      pip_install_docker_compose: true
      pip_install_docker_py: true
      pip_version_docker_compose: latest
      docker_opts: "--log-driver=json-file --log-opt max-size=10m --log-opt max-file=1"
      docker_group_members: ['ubuntu']
    - role: common-basic
    - { role: jenkins-basic,
        jenkins_home: '/var/lib/jenkins/'
      }
    - role: jenkins-plugins

  post_tasks:
    - block:
        - name: Restart Jenkins to make the plugin data available
          service: name=jenkins state=restarted

        - name: Wait untils Jenkins web API is available
          shell: curl --head --silent http://localhost:8080/cli/
          register: result
          until: result.stdout.find("403") != -1
          retries: 12
          delay: 5

        - name: Install jenkins plugins
          include_role:
            name: geerlingguy.jenkins
          vars:
            jenkins_plugins: ['swarm', 'git', 'workflow-aggregator', 'ssh-slaves', 'credentials']
          retries: 3

      rescue:
        - debug: msg='I caught an error'
    - block:
        - name: Install jenkins jobs
          include_role:
            name: jenkins-jobs
      rescue:
        - debug: msg='I caught an error'
```

Last time we were here, we only reviewed the parts needed for connecting via ssh to the machine. Now this provisioning script does a whole lot more.
Lets break it down
- It installs aws cli, jenkins and docker. 
- It adds our ssh keys using the common-basic role 
- Runs the jenkins role which installs jenkins (more on that later)
- Runs the jenkins plugins role which sets up the password to be used later when we are installing the plugins
- Executes post-tasks which restart jenkins, wait for it to restart, install jenkins plugins, and installs jenkins jobs. 
For more information on post tasks you can follow [ this link ](http://docs.ansible.com/ansible/playbooks_roles.html)

### Installing Jenkins

Nothing really fancy in here. We can install Ansible using an existing Ansible galaxy role. 
[Here is the link](https://github.com/geerlingguy/ansible-role-jenkins) to the github repo of the role.

### Installing Docker
Same goes for docker. Just grab the ansible galaxy role and apply your wanted configuration. [link](https://github.com/angstwad/docker.ubuntu) to the docker role.

### Enabling ssh connection between master and slave
the `jenkins-basic` role copies ssh keys to both the slave and master. When we install jenkins on the master, it creates a new user for our instance with the name jenkins.
The home directory of the jenkins user is `/var/lib/jenkins/`. We copy ssh keys to the ssh directory in the home folder of the jenkins user, and set all the needed folders and files permissions.
Here is the task:

```sh 
---
  - name: ensures jenkins ssh folder exists under jenkins home dir
    file: 
      path='{{ jenkins_home }}.ssh' 
      state=directory 
      owner=jenkins
      group=jenkins
      mode=0700

  - name: copy authorized keys
    copy:
        src=authorized_keys
        dest='{{ jenkins_home }}.ssh/authorized_keys'
        owner=jenkins
        group=jenkins
        mode=0644
    retries: 5
    delay: 2
    ignore_errors: yes

  - name: copy private rsa key
    copy:
        src=jenkins_rsa
        dest='{{ jenkins_home }}.ssh/id_rsa'
        owner=jenkins
        group=jenkins
        mode=0700
    retries: 5
    delay: 2
    ignore_errors: yes

  - name: copy public rsa key
    copy:
        src=jenkins_rsa.pub
        dest='{{ jenkins_home }}.ssh/id_rsa.pub'
        owner=jenkins
        group=jenkins
        mode=0744
    retries: 5
    delay: 2
    ignore_errors: yes

```


### Copying password for plugins tasks 
When we install jenkins, it saves the initial password to log in to jenkins in the following folder: `/var/lib/jenkins/secrets/initialAdminPassword` We need that password 
to install our plugins via the provisioning script so we copy it and save it as an ansible variable named: `jenkins_admin_password`.

### Post task - Install plugins

Again with the jenkins ansible galaxy role. Unfortunately to install jenkins with plugins we have to use the same role twice.
Luckily ansible is idempotent and will not reinstall jenkins if it is already installed. 
We specify the plugins we want to install and we place all the plugin installation block inside of a block to enable retries and to not fail the entire provisioning script 
if we experience some networking issue or any other error. If all fails, we will just install all the plugins manually.

### Installing jenkins jobs

We will take a look at the job later, After all, that is what we are all here for.. For now, we are just adding it to jenkins.
I previously created a jenkins job to deploy our web app and simply copied the xml file that was created. 
The role uses jenkins REST API to add the jobs to jenkins. We wrap this post task in a block to prevent it from failing the provisioning as well.
Here is how it looks: 
```yml
---
  - name: Get admin password
    shell: cat '/var/lib/jenkins/secrets/initialAdminPassword'
    register: initialAdminPassword

  - name: Restart Jenkins to make the plugin data available
    service: name=jenkins state=restarted

  - name: Wait untils Jenkins web API is available
    shell: curl --head --silent http://localhost:8080/cli/
    register: result
    until: result.stdout.find("403") != -1
    retries: 12
    delay: 5

  - name: Install jobs
    jenkins_job:
      config: "{{ lookup('file', 'files/jenkins-test-webapp.xml') }}"
      name: jenkins-test-webapp
      password: "{{ initialAdminPassword.stdout }}"
      url: http://localhost:8080
      user: admin

```

That's it. We took care of all of our loose ends. Next, we will deploy everything we did to AWS and leave the provisioning and infrastructure configuration for 
a while (We will make sure our jenkins master can communicate with the slave and that we can browse our jenkins master Web UI)

[Previous chapter: 7-1-Packer-slave](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/7-1-packer-slave) 

[Next chapter: 8-Deploy](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/8-deploy) 
