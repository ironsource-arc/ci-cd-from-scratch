At ironSource infra team, we are responsible for developing an automation framework to help test our various products.

## Creating the Jenkins job - Part 2

We were in the middle of breaking the job to smaller pieces. 
But now we have reached the stage where we can actually see the fruits of our labor.
I created a separate repository for our web server. 
Please clone the following repository:
`https://yourdomain.name.com/scm/ci-cd-from-scratch-webserver.git`

Its just the hello world application with all the boilerplate we need for deploying our application using Jenkins. 
Please go and update the Jenkins job we created to deploy this application instead.


This chapter will be hands on. 

This time we will update the final files of our new repository and use them as our playground.
If you destroyed your architecture go and reapply everything we did in the previous chapters. 

Lets review where we stopped in the previous chapter. This is our current Jenkinsfile:
```groovy
#!groovy?
pipeline {
  agent {label 'slave'}
  environment{
    GIT_REPO='<%your git repo url%>/jenkins-utils-webserver.git'
    // TIMESTAMP=(new Date()).toTimestamp().getTime()
  }
  stages {
    stage ('PREBUILD') {

      steps {
        step([$class: 'WsCleanup'])
      }
    }
    stage ('CHECKOUT') {
      steps {
        git branch: '**', credentialsId: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', url: "https://${env.GIT_REPO}"
      }
    }
    stage ('SET ENVIRONMENT VARIABLES') {
      steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
          sh '''
            set +e
            set +x
            echo env.GIT_USERNAME=${GIT_USERNAME} > env.properties
            echo env.GIT_PASSWORD=${GIT_PASSWORD} >> env.properties
            echo env.GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) >> env.properties
            echo env.ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD) >> env.properties
            echo env.GIT_COMMIT=$(git rev-parse HEAD) >> env.properties
            cat env.properties
          '''
        }

        sh '''
          sed 's/$/"/g' -i env.properties
          sed 's/=/="/g' -i env.properties
        '''

        sh 'cat infra/jenkins-env-variables.groovy >> env.properties'

        load ('env.properties')
      }
    }
  }
}


```

<!-- ZIGI Note: Fetch credentials id from the following url: -->
<!-- http://<%your aws account url%>:8080/credentials/store/system/domain/_/credential/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/ -->

The Jenkinsfile in the repository currently contains the final version of our pipeline. Go ahead and paste our current version of the pipeline file. You will have to fork my repository to be able to follow along with the hands on section of this tutorial. 

Now that you updated the Jenkinsfile and pushed it to your repository lets build the job. 
Go to the job url: `http://<%your jenkins url%>:8080/job/jenkins-utils-webserver/` and press build now.
Here is the output: 
```
Started by user anonymous
Obtained infra/Jenkinsfile from git https://<%your git repo url%>/jenkins-utils-webserver.git
[Pipeline] node
Running on master in /var/lib/jenkins/workspace/jenkins-utils-webserver
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Declarative: Checkout SCM)
[Pipeline] checkout
 > git rev-parse --is-inside-work-tree # timeout=10
Fetching changes from the remote Git repository
 > git config remote.origin.url https://<%your git repo url%>/jenkins-utils-webserver.git # timeout=10
Fetching upstream changes from https://<%your git repo url%>/jenkins-utils-webserver.git
 > git --version # timeout=10
using GIT_ASKPASS to set credentials 
 > git fetch --tags --progress https://<%your git repo url%>/jenkins-utils-webserver.git +refs/heads/*:refs/remotes/origin/*
 > git rev-parse refs/remotes/origin/master^{commit} # timeout=10
 > git rev-parse refs/remotes/origin/origin/master^{commit} # timeout=10
Checking out Revision 0eac8dcb84a3807f675e1d9fde3a5280acbccf61 (refs/remotes/origin/master)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 0eac8dcb84a3807f675e1d9fde3a5280acbccf61
 > git rev-list 9888bc29a7e7c92fa12e6695d071e609480b909c # timeout=10
[Pipeline] }
[Pipeline] // stage
[Pipeline] withEnv
[Pipeline] {
[Pipeline] stage
[Pipeline] { (PREBUILD)
[Pipeline] deleteDir
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (CHECKOUT)
[Pipeline] git
Cloning the remote Git repository
Cloning repository https://<%your git repo url%>/jenkins-utils-webserver.git
 > git init /var/lib/jenkins/workspace/jenkins-utils-webserver # timeout=10
Fetching upstream changes from https://<%your git repo url%>/jenkins-utils-webserver.git
 > git --version # timeout=10
using GIT_ASKPASS to set credentials 
 > git fetch --tags --progress https://<%your git repo url%>/jenkins-utils-webserver.git +refs/heads/*:refs/remotes/origin/*
 > git config remote.origin.url https://<%your git repo url%>/jenkins-utils-webserver.git # timeout=10
 > git config --add remote.origin.fetch +refs/heads/*:refs/remotes/origin/* # timeout=10
 > git config remote.origin.url https://<%your git repo url%>/jenkins-utils-webserver.git # timeout=10
Fetching upstream changes from https://<%your git repo url%>/jenkins-utils-webserver.git
using GIT_ASKPASS to set credentials 
 > git fetch --tags --progress https://<%your git repo url%>/jenkins-utils-webserver.git +refs/heads/*:refs/remotes/origin/*
Seen branch in repository origin/master
Seen 1 remote branch
Checking out Revision 0eac8dcb84a3807f675e1d9fde3a5280acbccf61 (origin/master)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 0eac8dcb84a3807f675e1d9fde3a5280acbccf61
 > git branch -a -v --no-abbrev # timeout=10
 > git checkout -b master 0eac8dcb84a3807f675e1d9fde3a5280acbccf61
First time build. Skipping changelog.
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (SET ENVIRONMENT VARIABLES)
[Pipeline] withCredentials
[Pipeline] {
[Pipeline] sh
[jenkins-utils-webserver] Running shell script
+ set +e
+ set +x
env.GIT_USERNAME=****
env.GIT_PASSWORD=****
env.GIT_BRANCH=master
env.ORIGINAL_BRANCH=master
env.GIT_COMMIT=0eac8dcb84a3807f675e1d9fde3a5280acbccf61
[Pipeline] }
[Pipeline] // withCredentials
[Pipeline] sh
[jenkins-utils-webserver] Running shell script
+ sed s/$/"/g -i env.properties
+ sed s/=/="/g -i env.properties
[Pipeline] sh
[jenkins-utils-webserver] Running shell script
+ cat infra/jenkins-env-variables.groovy
[Pipeline] load
[Pipeline] { (env.properties)
[Pipeline] }
[Pipeline] // load
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // withEnv
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS
```

We can see the job ran on our slave, fetched the repository, checked out the master branch and populated all of our env. Variables. 
Neat!

Lets review the next stage.
Add the following stage to your Jenkinsfile and push it.

```groovy
. . .
stage ('VALIDATE BRANCH') {
  when {
    expression {
      return !['staging', 'feature', 'test', 'bug', 'master'].contains(env.GIT_BRANCH)
    }
  }
  steps {
    echo env.GIT_BRANCH 
    echo 'branch is not supported'
    sh 'exit 1'
  }
}
. . .
```


The branch validation step will only let predefined branches to be run. If the branch does not meet the requirement we will exit the script with a shell script that exits with the value 1. 
As you can see, the syntax is pretty self explanatory. 
Lets see the output: 

```
. . .
Stage 'VALIDATE BRANCH' skipped due to when conditional
. . .
[Pipeline] End of Pipeline
Finished: SUCCESS
```
Nice! master is allowed just like we wanted. 
Next step: (Add to your Jenkinsfile)

```groovy
. . .
    stage ('MERGE TO STAGING') {
      when {
        expression {return env.GIT_BRANCH =~ /^(feature|test|bug)/}
      }
      steps {
        sh '''
          git config user.name 'youruser.name'
          git config user.email 'useremail@yourdomain.com'
          git checkout staging
          git merge ${GIT_BRANCH}
          echo env.GIT_COMMIT=$(git rev-parse HEAD) > merge.properties
          echo env.GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD) >> merge.properties
          sed 's/$/"/g' -i merge.properties
          sed 's/=/="/g' -i merge.properties
        '''
        load ('merge.properties')
      }
    }
. . .
```

This snippet is in charge of merging our code to staging, but before we explain the stage I think it will be beneficial to
go over the git branching model we use at ironSource. 
Git is an extremely flexible SVN tool. You can do pretty much everything you want with it. There are two main approaches for managing your git repositories.
[The first](http://nvie.com/posts/a-successful-git-branching-model/) is called - A successful Git branching model 
[The second](https://barro.github.io/2016/02/a-succesful-git-branching-model-considered-harmful/) is called - The cactus model.
I encourage you to read both of the articles I provided. Open source projects tend to follow the git cactus model, but for our repositories 
at ironSource we use the first git model. It has a nice integration with bitbucket, where we host some of our services, 
and our workflows automate all the complex parts of merging the code.

So now that we got that covered, we can continue with our merge to staging. Each git repository has a staging branch. 
We use the staging environment to test our new features and run our integration tests. 
If the branch that triggered the build contains the words feature, test, or bug, we merge it to the local staging branch to run 
all our tests. The git config command sets up the username and email for git. 
We then checkout staging branch, merge our feature branch into staging, update GIT_COMMIT 
with the latest commit SHA and update GIT_BRANCH to equal 'staging'. 
Then we load the updated env variables like we did in the last step.
Lets create a feature branch and staging branch to test this new addition. We create the staging branch from master and then create the feature branch from staging. 
We will call it - feature/1mergetostaging. Please create the branches now ,push from the feature branch and build now.
Lets take a look at the output: 

```
. . .
Seen branch in repository origin/feature/1mergetostaging
Seen branch in repository origin/master
Seen branch in repository origin/staging
Seen 3 remote branches
Checking out Revision 897828eadbbded5906d75a477b65e372547fd17e (origin/feature/1mergetostaging)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 897828eadbbded5906d75a477b65e372547fd17e
 > git rev-list 69482d00a54e6a1cdf57c42e6f49b0eb457e92a6 # timeout=10
...
Seen branch in repository origin/feature/1mergetostaging
Seen branch in repository origin/master
Seen branch in repository origin/staging
Seen 3 remote branches
Checking out Revision 897828eadbbded5906d75a477b65e372547fd17e (origin/feature/1mergetostaging)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 897828eadbbded5906d75a477b65e372547fd17e
...
Checking out Revision 897828eadbbded5906d75a477b65e372547fd17e (origin/feature/1mergetostaging)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 897828eadbbded5906d75a477b65e372547fd17e
 > git branch -a -v --no-abbrev # timeout=10
 > git checkout -b feature/1mergetostaging 897828eadbbded5906d75a477b65e372547fd17e
...
env.GIT_BRANCH=feature/1mergetostaging
env.ORIGINAL_BRANCH=feature/1mergetostaging
env.GIT_COMMIT=897828eadbbded5906d75a477b65e372547fd17e
...
[Pipeline] stage
[Pipeline] { (MERGE TO STAGING)
[Pipeline] sh
[jenkins-utils-webserver] Running shell script
+ git config user.name youruser.name
+ git config user.email useremail@yourdomain.com
+ git checkout staging
Switched to a new branch 'staging'
Branch staging set up to track remote branch staging from origin.
+ git merge feature/1mergetostaging
Updating 8318810..897828e
Fast-forward
 infra/Jenkinsfile | 36 +++++++++++++++++++++++++++++++-----
 1 file changed, 31 insertions(+), 5 deletions(-)
+ git rev-parse HEAD
+ echo env.GIT_COMMIT=897828eadbbded5906d75a477b65e372547fd17e
+ git rev-parse --abbrev-ref HEAD
+ echo env.GIT_BRANCH=staging
+ sed s/$/"/g -i merge.properties
+ sed s/=/="/g -i merge.properties
...
Finished: SUCCESS
```
As you can see, we are building the feature branch and merging it into staging in the local working directory that was assigned to the job on our slave. Nothing has been pushed to the remote repository yet. 

```groovy
. . .

    stage ('BUILDING IMAGE') {
      steps {
        ansiblePlaybook(
          extras: '-c local -v',
          playbook: 'infra/build-playbook.yml',
          extraVars: [
            commit: env.GIT_COMMIT,
            image: env.DOCKER_REPO,
            branch: env.GIT_BRANCH
          ])
      }
    }
. . .
```


The next stage will build our docker image. As I mentioned before, we are offloading every task we can to be performed by more uniformed tools. This time we leverage ansible built in docker support to build the docker image. `ansiblePlaybook` is a function that runs a playbook inside of a Jenkins pipeline. We specify the playbook we would like to run, the variables to pass to the playbook, and some extra flags like verbosity level and the type of ansible connection to use - local.
Here is the playbook we are going to run: 

```yml

---
- hosts: localhost
  vars:
  tasks:
  - name: building image
    docker_image:
      path: ../
      name: "{{ image }}"
      tag: "{{ commit }}"
      buildargs:
        GIT_COMMIT: "{{ commit }}"
        NODE_ENV: "{{ branch }}"
  - name: building image
    shell: docker tag {{image}}:{{commit}} {{image}}:{{branch}}
```

It uses [docker image](http://docs.ansible.com/ansible/docker_image_module.html) ansible module to create the image. By supplying the build path we are telling the module to only build the image on the docker host (our jenkins slave) and not push it to a remote repository. We use the env variables that we defined in the jenkins file to add a tag, a name, and to specify the build args for docker to use when it is building the image. Finally, we tag our container with two tags, one contains the image name and the commit SHA while the other is comprised of the image name and the branch. In our case, the tags will be: 
jenkins-utils-webserver/897828eadbbded5906d75a477b65e372547fd17e and jenkins-utils-webserver/staging
Before we move on to the next build step lets see the docker file that will be built during this build step: 

```yml
$ cat jenkins-utils-webserver/Dockerfile
FROM node:7.7.3-onbuild
ARG GIT_COMMIT
ENV GIT_COMMIT ${GIT_COMMIT}
HEALTHCHECK --interval=1m --timeout=3s --retries=3 CMD curl --fail http://localhost:8000/health || exit 1
```

We are using the simplest docker file there is! We are using a base image named node:onbuild. Almost everything was already done for us by the guys maintaining the node onbuild images. [link](https://github.com/nodejs/docker-node/blob/a82c9dcd3f85ff8055f56c53e6d8f31c5ae28ed7/7.9/onbuild/Dockerfile) Just to keep everyone on the same level, lets start by looking at the onbuild base image: 
```yml
FROM node:7.9.0

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ONBUILD ARG NODE_ENV
ONBUILD ENV NODE_ENV $NODE_ENV
ONBUILD COPY package.json /usr/src/app/
ONBUILD RUN npm install && npm cache clean
ONBUILD COPY . /usr/src/app

CMD [ "npm", "start" ]
```

So as you can see, every image in docker can have a base image. The onbuild image uses the node image as its base image, but 
I'm not gonna show you every base image in the docker hierarchy.. Suffice it to say that we are building node on an ubuntu
image and installing at least node and npm on that ubuntu machine :).
Back to the docker file. The docker file uses the node onbuild base image to create the working directory for 
our app - /usr/src/app, copies our package.json file to the working directory and then it npm installs 
all of our node modules. After it has done all of that, it copies our staging branch source code to the working
directory inside of the docker container and executes the npm start command, in our case it is just a simple `node src`.
<!-- ZIGI: Note: check and see if we can remove the arg node env from our file as it is present in the onbuild image -->
We also add a health check so the container knows to kill itself when the health route is not responding, and the git 
commit that will be returned by the health check so we can easily trace back what commit is currently live on our environment.

One last step before we see it all in action. We will use the container we just built to generate a unit tests report for us. To do that we need to take a look at the scripts section in the package.json file: 
```json
$ cat package.json
. . .
  "scripts": {
    "test": "NODE_PATH=src NODE_ENV=test mocha test/**/* --timeout 10000",
    "test-with-cover": "NODE_PATH=src NODE_ENV=test jenkins-mocha --cobertura test/**/*",
    "start": "node src"
  },
  "keywords": [],
. . .
```

Npm lets us run scripts in the package.json file with a simple cli command `npm run <SCRIPT_NAME>`. We use an npm package called jenkins-mocha to generate a report that is compliant with jenkins UI and will display nicely on our job web UI. Unfortunately, as of writing this tutorial, this report is not supported in pipeline jobs. That is why we will only view the generated xml as part job output. I hope support will be added soon. 

So lets look at the section in the Jenkinsfile running the unit tests: 
```groovy
stage ('RUN UNIT TESTS') {
  steps {
    ansiblePlaybook(
      extras: '-c local -v',
      playbook: 'infra/unit-test-playbook.yml',
      extraVars: [
        commit: env.GIT_COMMIT,
        image: env.DOCKER_REPO,
        name: env.COMPONEN
      ])
  }
}
```
As always, the good stuff is in the playbook, so lets take a look at that as well.
```sh
$ cat infra/unit-test-playbook.yml
```
```yml
---
- hosts: localhost
  vars:
  tasks:
  - debug:
      msg: "executing tests on {{ image }}:{{ commit }} "
  - name: running unit tests
    docker_container:
      name: "{{ name }}"
      state: present
      image: "{{image}}:{{commit}}"
      command: npm run test-with-cover
  - name: copy artifacts folder
    command: docker cp "{{name}}":/usr/src/app/ ~/
  - name: cat cobertura file
    command: cat ~/artifacts/coverage/cobertura-coverage.xml
```
We execute a command on the container we just built with the docker_container module. 
We create our unit test report file simply by running 
the npm command on the container we just created. 
After we run the job we copy the contents of the app folder in the container to our working directory and then 
we cat the contents of the report file. 
<!-- zigi: check what happens if build fails -->

Enough talk! Lets commit all of our changes to the branch we created for this hands on exercise and view the fruits of our labor. 
Run the jenkins build after you checked in all the code to the Jenkinsfile. Here is the output: 

```sh
[Pipeline] { (BUILDING IMAGE)
[Pipeline] ansiblePlaybook
[jenkins-utils-webserver] $ ansible-playbook infra/build-playbook.yml -e commit=875be0adeb0a25f09cdbc9dedff803e22e8be4d5 -e image=<%your image%> -e branch=staging -c local -v
Using /etc/ansible/ansible.cfg as config file
 [WARNING]: provided hosts list is empty, only localhost is available

PLAY [localhost] ***************************************************************

TASK [setup] *******************************************************************
ok: [localhost]

TASK [debug] *******************************************************************
ok: [localhost] => {
    "msg": "building <%your image%>:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx "
}

TASK [building image] **********************************************************
changed: [localhost] => {"actions": ["Built image <%your image%>:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx from ../"], "changed": true, "image": {"Architecture": "amd64", "Author": "", "Comment": "", "Config": {"ArgsEscaped": true, "AttachStderr": false, "AttachStdin": false, "AttachStdout": false, "Cmd": ["npm", "start"], "Domainname": "", "Entrypoint": null, "Env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", "NPM_CONFIG_LOGLEVEL=info", "NODE_VERSION=7.7.3", "YARN_VERSION=0.21.3", "NODE_ENV=staging", "GIT_COMMIT=875be0adeb0a25f09cdbc9dedff803e22e8be4d5"], "Healthcheck": {"Interval": 60000000000, "Retries": 3, "Test": ["CMD-SHELL", "curl --fail http://localhost:8000/health || exit 1"], "Timeout": 3000000000}, "Hostname": "ed11f485244a", "Image": "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "Labels": {}, "OnBuild": [], "OpenStdin": false, "StdinOnce": false, "Tty": false, "User": "", "Volumes": null, "WorkingDir": "/usr/src/app"}, "Container": "23db93c2de080c70b2b2e725c646c9ac9f35802ca190012a63577a93c8ee1102", "ContainerConfig": {"ArgsEscaped": true, "AttachStderr": false, "AttachStdin": false, "AttachStdout": false, "Cmd": ["/bin/sh", "-c", "#(nop) ", "HEALTHCHECK &{[\"CMD-SHELL\" \"curl --fail http://localhost:8000/health || exit 1\"] \"1m0s\" \"3s\" '\\x03'}"], "Domainname": "", "Entrypoint": null, "Env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", "NPM_CONFIG_LOGLEVEL=info", "NODE_VERSION=7.7.3", "YARN_VERSION=0.21.3", "NODE_ENV=staging", "GIT_COMMIT=875be0adeb0a25f09cdbc9dedff803e22e8be4d5"], "Healthcheck": {"Interval": 60000000000, "Retries": 3, "Test": ["CMD-SHELL", "curl --fail http://localhost:8000/health || exit 1"], "Timeout": 3000000000}, "Hostname": "ed11f485244aasync ", "Image": "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "Labels": {}, "OnBuild": [], "OpenStdin": false, "StdinOnce": false, "Tty": false, "User": "", "Volumes": null, "WorkingDir": "/usr/src/app"}, "Created": "2017-05-06T15:26:29.47760428Z", "DockerVersion": "17.03.0-ce", "GraphDriver": {"Data": null, "Name": "aufs"}, "Id": "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "Os": "linux", "Parent": "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "RepoDigests": [], "RepoTags": ["<%your image%>:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"], "RootFS": {"Layers": ["sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", "sha256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"], "Type": "layers"}, "Size": 685779969, "VirtualSize": 685779969}}

TASK [building image] **********************************************************
changed: [localhost] => {"changed": true, "cmd": "docker tag <%your image%>:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx <%your image%>:staging", "delta": "0:00:00.079864", "end": "2017-05-06 15:26:29.818967", "rc": 0, "start": "2017-05-06 15:26:29.739103", "stderr": "", "stdout": "", "stdout_lines": [], "warnings": []}

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=2    unreachable=0    failed=0   

[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (RUN UNIT TESTS)
[Pipeline] ansiblePlaybook
[jenkins-utils-webserver] $ ansible-playbook infra/unit-test-playbook.yml -e commit=875be0adeb0a25f09cdbc9dedff803e22e8be4d5 -e image=<%your image%> -e name=jenkins-utils-webserver -e branch=staging -c local -vv
Using /etc/ansible/ansible.cfg as config file
 [WARNING]: provided hosts list is empty, only localhost is available

PLAYBOOK: unit-test-playbook.yml ***********************************************
1 plays in infra/unit-test-playbook.yml

PLAY [localhost] ***************************************************************

TASK [setup] *******************************************************************
ok: [localhost]

TASK [debug] *******************************************************************
task path: /home/jenkins/workspace/jenkins-utils-webserver/infra/unit-test-playbook.yml:5
ok: [localhost] => {
    "msg": "executing tests on <%your image%>:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx "
}

TASK [running unit tests] ******************************************************
task path: /home/jenkins/workspace/jenkins-utils-webserver/infra/unit-test-playbook.yml:7
changed: [localhost] => {"ansible_facts": {}, "changed": true}

TASK [copy artifacts folder] ***************************************************
task path: /home/jenkins/workspace/jenkins-utils-webserver/infra/unit-test-playbook.yml:13
changed: [localhost] => {"changed": true, "cmd": ["docker", "cp", "jenkins-utils-webserver:/usr/src/app/", "~/"], "delta": "0:00:04.500489", "end": "2017-05-06 15:26:36.321292", "rc": 0, "start": "2017-05-06 15:26:31.820803", "stderr": "", "stdout": "", "stdout_lines": [], "warnings": []}

TASK [cat cobertura file] ******************************************************
task path: /home/jenkins/workspace/jenkins-utils-webserver/infra/unit-test-playbook.yml:15
changed: [localhost] => {"changed": true, "cmd": ["cat", "~/artifacts/coverage/cobertura-coverage.xml"], "delta": "0:00:00.007522", "end": "2017-05-06 15:26:36.499761", "rc": 0, "start": "2017-05-06 15:26:36.492239", "stderr": "", "stdout": "<?xml version=\"1.0\" ?>\n<!DOCTYPE coverage SYSTEM \"http://cobertura.sourceforge.net/xml/coverage-04.dtd\">\n<coverage lines-valid=\"0\" lines-covered=\"0\" line-rate=\"NaN\" branches-valid=\"0\" branches-covered=\"0\" branch-rate=\"NaN\" timestamp=\"1494080412689\" complexity=\"0\" version=\"0.1\">\n  <sources>\n    <source>/usr/src/app</source>\n  </sources>\n  <packages>\n  </packages>\n</coverage>", "stdout_lines": ["<?xml version=\"1.0\" ?>", "<!DOCTYPE coverage SYSTEM \"http://cobertura.sourceforge.net/xml/coverage-04.dtd\">", "<coverage lines-valid=\"0\" lines-covered=\"0\" line-rate=\"NaN\" branches-valid=\"0\" branches-covered=\"0\" branch-rate=\"NaN\" timestamp=\"1494080412689\" complexity=\"0\" version=\"0.1\">", "  <sources>", "    <source>/usr/src/app</source>", "  </sources>", "  <packages>", "  </packages>", "</coverage>"], "warnings": []}

PLAY RECAP *********************************************************************
localhost                  : ok=5    changed=3    unreachable=0    failed=0   

[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // withEnv
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
Finished: SUCCESS
```

Browse through the output and you will see everything we discussed in action. 
Most notably, you can see the cobertura report generated at the end. 
You can see the line coverage (currently zero) and a bunch of other statistics that are currently all marked as zero at best.. :)

This chapter was my longest one yet. I'm starting to feel a bit like George r.r Martin, but we must not quit now, winter is coming,
and our CI/CD process must be ready before the winds of winter arrive. So take a 5 minute break and meet me at the next chapter.
<!-- zigi: I need to add a check for when the unit test fails -->

[Previous chapter: 11-Create-job](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/11-create-job) 

[Next chapter: 13-Create-job](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/13-create-job) 
