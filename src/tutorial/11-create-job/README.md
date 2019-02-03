At ironSource infra team, we are responsible for developing an automation framework to help test our various products.

## Creating the Jenkins job

In the following chapters we will dive deeper into the CI/CD process we are using to deploy our web services. 
Although it might seem strange to start with the jenkins job before creating the infrastructure for our web app deployment, 
the jenkins job is the most simple so I think it is better that we start with it. 
We are going to use the jenkins pipeline plugin to deploy our web service. 

### Jenkins Declarative Pipeline

>Declarative Pipeline is a relatively recent addition to Jenkins Pipeline [1] which presents a more simplified and opinionated syntax on top of the Pipeline sub-systems.

Using the declarative pipeline plugin, we can manage almost all of our deployment process in code! 
Lets dive right in and see what we need to do in jenkins UI to create our first job

Browse to the following url: `http://<%your jenkins url%>:8080/newJob` to create a job. 
We will name our job `hello-world-web-service-deployment` and select to create a "Pipeline" job (if one of the plugins failed to install during the provisioning step you can either run the provisioning script as a local ansible script, or install the plugin manually. To create a job we need the `pipeline` plugin or its alias: `workflow-aggregator`). For now, in the second step we just need to tell the job from where it is going to retrieve the pipeline definition from. We will add the pipeline script to our SCM and jenkins will pull it from there. 
We are going to save the jenkins pipeline script as `infra/Jenkinsfile` so that is the path you will need to supply. 
You also need to provide the repository url. Here is the link to an image with my repository path: 
![](https://github.com/ironSource/ci-cd-from-scratch/blob/master/src/tutorial/images/pipelinesetup.png)

If you are hosting the webserver as a private repository you will need to specify the credentials to use as part of the job configuration. 
You can add your credentials to jenkins in the following url: 
`http://<%your jenkins url%>:8080/credentials/store/system/domain/_/newCredentials`

Just add your username and password and you are done. Here is a link to the image of what you need to do:
![](https://github.com/ironSource/ci-cd-from-scratch/blob/master/src/tutorial/images/githubcredentials.png)

We also need to create a github token in order to be able to create pull requests. Please create a 
github token [here](https://github.com/settings/tokens).
For this tutorial we are going to keep it simple and use a personal token, but for real production use I would 
advise you to generate a token specifically for jenkins.
Here is what you need to fill up: 
![](https://github.com/ironSource/ci-cd-from-scratch/blob/master/src/tutorial/images/create-github-token.png)

Save the token that was generated. Now we are going to add it to jenkins the same way we did with our username and 
password. 
You can add your credentials to jenkins in the following url: 
`http://<%your jenkins url%>:8080/credentials/store/system/domain/_/newCredentials`
Paste the token in the password field and for the username paste your github username.

That should be enough to get us going. Leave all the other options untouched and click on the save button.

Lets take a look at the pipeline script. First, we will look at the entire script, and then we will break it down into smaller pieces.

```groovy
#!groovy?
pipeline {
  agent any
  environment{
    GIT_REPO='<YOUR_REPO_ADDRESS>/scm/iavc/stats.git'
    TIMESTAMP=(new Date()).toTimestamp().getTime()
  }
  stages {
    stage ('PREBUILD') {
      steps {
        deleteDir()
      }
    }
    stage ('CHECKOUT') {
      steps {
        git branch: '**', credentialsId: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', url: "https://${env.GIT_REPO}"
      }
    }
    stage ('SET ENVIRONMENT VARIABLES') {
      steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
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
    stage ('RUN UNIT TESTS ON STAGING IMAGE') {
      when {
        expression {return env.GIT_BRANCH =~ /^(staging|feature|test|bug)/}
      }
      steps {
        echo 'here we will run tests'
      }
    }
    stage ('PUSH IMAGE TO REGISTRY') {
      steps {
        ansiblePlaybook(
          extras: '-c local -v',
          playbook: 'infra/push-to-docker-hub-playbook.yml',
          extraVars: [
            commit: env.GIT_COMMIT,
            image: env.DOCKER_REPO,
            branch: env.GIT_BRANCH
        ])
      }
    }

    stage ('PUSH TO REMOTE STAGING BRANCH') {
      when {
        expression {return env.ORIGINAL_BRANCH=~ /^(feature|test|bug)/}
      }
      steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
          sh '''
            git push https://${GIT_USERNAME}:${GIT_PASSWORD}@${GIT_REPO}
          '''
        }
      }
    }
    stage ('DEPLOY') {
      steps {
        ansiblePlaybook(
          playbook: 'infra/deploy-swarm-playbook.yml',
          extras: '-c local -v',
          extraVars: [
            commit: env.GIT_COMMIT,
            image:  env.DOCKER_REPO,
            service: env.COMPONENT,
            environment: env.GIT_BRANCH,
            branch: env.GIT_BRANCH])
      }
    }
  }

  post {
    always {
      sh 'echo "This will always run"'
    }
    success {
      sh 'echo "This will run only if successful"'
    }
    failure {
      sh 'echo "This will run only if failed"'
    }
    unstable {
      sh 'echo "This will run only if the run was marked as unstable"'
    }
    changed {
      sh 'echo "This will run only if the state of the Pipeline has changed"'
      sh 'echo "For example, the Pipeline was previously failing but is now successful"'
      sh 'echo "... or the other way around :)"'
    }
  }
}
```

So our deployment script is written in a language called groovy. Here is an excerpt on the language: 

>Groovy: A multi-faceted language for the Java platform.
Apache Groovy is a powerful, optionally typed and dynamic language, with static-typing and static compilation capabilities, for the Java platform aimed at improving developer productivity thanks to a concise, familiar and easy to learn syntax. It integrates smoothly with any Java program, and immediately delivers to your application powerful features, including scripting capabilities, Domain-Specific Language authoring, runtime and compile-time meta-programming and functional programming.

Groovy is a scripting language for java programs. 
That is why jenkins, which is written in java, uses groovy as its scripting language for the pipeline jobs. 
As always, we will only go over the parts we need to create our script, but you can read the 
[documentation](http://groovy-lang.org/documentation.html) if you want to know more. 

* As a side note, I must mention that searching the internet for documentation on how to use the jenkins declarative pipeline syntax is not as easy as it seems. That is why we try to keep the jenkins pipeline code as lean as we possibly can. 
We try to offload all of the major development process to tried and tested tools like ansible, shell scripts, and docker compose. 
The jenkins job acts like an orchestrator that is in charge on the synchronization and scheduling of our tasks. I hope that the documentation will improve over time. Until then, I will provide the best resources I found in the resources section.
Lets look at the first part
```groovy
#!groovy?
pipeline {
  agent any
  environment{
    GIT_REPO='<%your git repo url%>'
  }
  . . .
}
```

The first line `#!groovy?` tells IDEs to treat the script as a groovy script, for syntax highlighting. The `pipeline` block is the main block of the script. All of our code will reside inside this block. 
`agent any` tells jenkins it can choose to send the job to any node that is available. We currently only have one node, but we could create a label for our nodes and let jenkins run the job only on our nodes. 
The `environment` block lets us define environment variables that can be used during our script execution.
We must specify the git repo url, that the job will pull the source code from. We specify our hello world app github repo url.

```groovy
#!groovy?
pipeline {
  . . .
  stages {
    stage ('PREBUILD') {
      steps {
        deleteDir()
      }
    }
    . . .
  }
}
```

The stages block is where we specify all the tasks we need to run in order to successfully deploy our web application. 

The first step deletes everything in the workspace folder jenkins assigned for us to run the job, so we can have a clean slate for every run. 

```groovy
    . . .
    stage ('CHECKOUT') {
      steps {
        git branch: '**', url: "https://${env.GIT_REPO}"
      }
    }
    . . .
```

The checkout stage checks out the latest changed branch. We use the GIT_REPO url we defined earlier to reference the repository we would like to checkout. We want to run the job on all branches so we use a regular expression that matches all branches: `branch: '**'`

```groovy
    . . .
    stage ('SET ENVIRONMENT VARIABLES') {
      steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
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
    . . .
```

This stage is a little tricky. 
Now that we checked out the repository and the appropriate branch we create additional env variables that we will use later on. 
We use the [Credentials Binding Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Credentials+Binding+Plugin) 
<!-- TODO: ZIGI: specify what credentials id is all about if we need it when moving to github -->
(installed when installing the work-aggregator plugin) to bind the username and password 
used to check out the repository, to environment variables we can use later. 
At ironSource, we are hosting our services as private repositories in github. If your repository is private as well you will have to add your github or bitbucket credentials 
to jenkins so it can access your repositories. I will show at a later step how to add your github 
credentials to jenkins and how to get the `credentialsId` you need in order to use the withCredentials plugin.

Now we run a small inline shell script that saves all the git data we want to a file. The first thing we do is 
change the shell stdout verbosity options using the `set` command. Specifying `set +x` and `set +e` will make sure our sensitive data is not visible in the jenkins console output.
Now we save the git branch and then latest commit as an environment variable.
We save the password, username, and the original branch that was checked out (In some scenarios we will overwrite the GIT_BRANCH env variable before merging to staging or master, thats why we save the git branch to 2 env variables.)
We will save all those variables to a file called `env.properties` and print it to the jenkins logs to see what was saved, using the `cat` command. 
The output should look something like this: 

```sh
env.GIT_BRANCH=master
<!-- TODO: ZIGI: Copy output of script execution-->
```

The next step wraps the output of the env variables definitions with quotation marks. Like this
`env.GIT_BRANCH=master` ==> `env.GIT_BRANCH="master"`
in case one of the environment variables contains a multi word definition.

Lastly, we append our own environment variables that we defined in the `infra/jenkins-env-variables.groovy` file. 
Lets look at the file contents
```sh
$ cd /Users/$USER/ci-cd-from-scratch/src/app/infra/
$ cat jenkins-env-variables.groovy

env.DOCKER_REPO='<%your image%>'
env.COMPONENT='jenkinswebserver'

```
We got the name of the docker repo on which we host our wep app images, and the component name. In our case its jenkinswebserver.

Finally we load the file containing all of our environment variables: `load ('env.properties')` to apply them as variables that can be used throughout the script.

Thats enough for one chapter. Go do your thang. We will meet again at the next chapter.

[Previous chapter: 10-WebApp](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/10-webapp) 

[Next chapter: 12-Create-job](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/12-create-job) 
