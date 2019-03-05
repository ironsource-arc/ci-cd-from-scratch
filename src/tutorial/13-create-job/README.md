> At ironSource infrastructure team, we are responsible for developing an automation framework to help test our various products.

## Creating the Jenkins job - Part 3

Moving on to the next step - pushing the image to our docker registry. Lets take a look at the code snippet: 
```
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

```

Like always, running a playbook. This is starting to get a little boring..
Here is the playbook itself: 
```
---
- hosts: localhost
  vars:
  tasks:
  - debug:
      msg: "pushing {{ image }}:{{ commit }} "
  - name: Log into DockerHub
    docker_login:
      username: jenkinsewebservertutorial
      password: xxxxxxx.
      email: zigius@mailinator.com
  - name: pushing image
    docker_image:
      push: yes
      name: "{{ image }}"
      tag: "{{ commit }}"
  - name: pushing image
    docker_image:
      push: yes
      name: "{{ image }}"
      tag: "{{ branch }}"

```
The playbook, as is implied by its name, will push the image we created to docker hub. 
Docker hub is an images repository created by docker so users can store and share their images. 
This is by far my least favorite product that was produced by the docker team, but nonetheless, we will use it.. 
We login to docker hub and create 2 separate tags for our image. 
One will contain the commit id for version tracking and the other will contain the current branch being built. 
We merged everything to staging before pushing the image so the branch will be staging.
If you want to follow along with the tutorial please [create your own docker hub account](https://hub.docker.com/), and use your email, username and password.

This next step is so simple we don't even need a playbook! Pushing the code to staging branch. 
```
stage ('PUSH TO REMOTE STAGING BRANCH') {
  when {
    expression {return env.ORIGINAL_BRANCH=~ /^(feature|test|bug)/}
  }
  steps {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
      sh '''
        git push https://${GIT_USERNAME}:${GIT_PASSWORD}@${GIT_REPO}
      '''
    }
  }
}

```

You remember the `with credentials` jenkins plugin from before right? Now we use it again. 
This time instead of checking out our code we are checking it in, or pushing it in git terms. 
A simple git push will update our remote repository with the new code changes under the staging branch. 

Here is the next playbook in the chain: 

```
stage ('CREATE PULL REQUEST') {
  when {
    expression {return env.GIT_BRANCH == 'staging'}
  }
  steps {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_TOKEN']]) {
      createGithubPullRequest("tests jenkins pull request", env.PROJECT, env.GIT_BRANCH, env.GIT_TOKEN)
    }
  }
}

```

The playbook creates a pull request from staging to master that we will have to approve manually. 
It is one of the only steps in the process that require human interaction. 
To create a pull request we are using the token credentials we previously created. 
We are gonna call a function called `createGithubPullRequest` and we will pass to 
it the title of the pull request, the project we are working on (ci-cd-from-scratch) and the 
token to use when creating the pull request.

Here is the function that actually creates the pull request(Located at the top of the jenkins file):
```
def createGithubPullRequest(String message, String project, String branch, String token) {
    try {
        def body = """
        {
          "title": "${message}",
          "head": "${branch}",
          "base": "master"
        }
        """
        echo "sending body: ${body}\n"
        def response = httpRequest acceptType: 'APPLICATION_JSON', contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: body, customHeaders: [[name: "Authorization", value: "Bearer ${token}"]], url: "https://api.github.com/repos/${project}/pulls"

        echo "responce status: ${response}"
        return response

    } catch (err) {
        error "ERROR  ${err}"
    }
}
```
Lets break this function down: 
We create the body of the message we are going to send to github which includes the title, head and base branch of the pull request.
We are using the jenkins plugin 'HTTP Request Plugin' that sends a post request to github api to create the pull request. 
Finally we print the responseStatus to the screen and return it.

If you are using bitbucket as your SVN you can use the createBitbucketPullRequest function that basically does the 
same thing but uses curl instead. 

Here are the env variables relevant for this step in case you choose to use bitbucket:

```
env.PUSHREQUEST_URL='https://<%your git repo url%>/<%your project%>/pull-requests'
env.PUSHREQUEST_TEXT='{ "title": "jenkinsPullRequest","description":"Pull request created by jenkins CI/CD process","state":"OPEN","open":true,"closed":false,"fromRef":{"id":"refs/heads/staging","repository":{"slug":"proxy","name":null,"project":{"key":"iavc"}}},"toRef":{"id":"refs/heads/master","repository":{"slug":"proxy","name":null,"project":{"key":"iavc"}}},"locked":false}'
```
I will not bother you with the detail of creating a pull request in bitbucket via the cli. Just know that
a simple curl script that posts our pull request to the bitbucket servers is enough. Look at the `PUSHREQUEST_TEXT` variable more closely
if you want to better understand the structure needed to create a pull request in bitbucket.


And here we are, at the last playbook in our Jenkinsfile. All the dirty work has been done and now its time we deploy our app to our staging environment for manual testing. Here is the code snippet:

```
stage ('DEPLOY') {
  steps {
    ansiblePlaybook(
      playbook: 'infra/deploy-playbook.yml',
      extras: '-c local -v',
      extraVars: [
        commit: env.GIT_COMMIT,
        image:  env.DOCKER_REPO,
        service: env.COMPONENT,
        environment: env.GIT_BRANCH,
        branch: env.GIT_BRANCH])
  }
}

```

Thats it for this chapter. In the next chapter we will test all of our new playbooks and script snippets in action. We will also deploy our web server to an aws instance, which will give us another chance to review all the tools we used during this tutorial. Stick around.

[Previous chapter: 12-create-job](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/12-create-job) 

[Next chapter: 14-Webesrver-Infra](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/14-webesrver-infra) 
