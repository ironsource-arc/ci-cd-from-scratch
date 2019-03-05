> At ironSource infrastructure team, we are responsible for developing an automation framework to help test our various products.

## Configuring slave via jenkins UI and adding credentials to jenkins

Adding the slave instance we created as an actual jenkins slave will be pretty easy. 
We already went over everything we need to enable ssh connection between the instances. 
Now its just a matter of registering the machine as a slave via jenkins UI. 
For a full guide you are welcome to go over 
[this article](https://support.cloudbees.com/hc/en-us/articles/222978868-How-to-Connect-to-Remote-SSH-Slaves). 
I'm just gonna go over the important pieces of information that are missing.

But first we need to add our slave credentials to jenkins. 
We will give the first credentials we are creating a simple name - jenkins
Go to the following url: `http://<%your jenkins url%>:8080/credentials/store/system/domain/_/newCredentials` and add the following details (No need to explicitly specify the ID, it will be created for you) 
![](https://github.com/ironSource/ci-cd-from-scratch/blob/master/src/tutorial/images/jenkins-slave-credentials.png)
Whenever we trigger our jenkins pipeline job the master will use those credentials to connect to the slave
via ssh.


Now we need to configure the node. Go to the following url: 
`http://<%your jenkins url%>:8080/computer/new` and name your 
node `jenkins` and make him a Permanent agent.
After that you will need to copy the details from the following image:

![](https://github.com/ironSource/ci-cd-from-scratch/blob/master/src/tutorial/images/new-jenkins-slave-agent.png)

This was a short chapter, but don't worry, there is much more to do ahead of us. Next chapter we will create our first job using the jenkins pipeline model.

[Previous chapter: 8-Deploy](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/8-deploy) 

[Next chapter: 10-WebApp](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/10-webapp) 
