# Infrastructure Team CI/CD

## CI/CD process using: docker, jenkins, ansible, and some other tools.

At ironSource infra team, we are responsible for developing an automation framework to help test our various products.
Deploying hundreds of microservices across different platforms, cloud providers and on-prem solutions can become a cumbersome
task. To alleviate the effort of supporting a growing, auto scalable architecture, we had to develop a flexible ci / cd process. One that is easily reused and one that its building blocks are easily replaced. 
This tutorial will walk you through all the steps we use to create our CI/CD infrastructure. 

Throughout the tutorial we will be using tools like terraform, packer and ansible to provision and deploy our jenkins infrastructure to aws, Docker to package our source code, and jenkins pipeline who will be the one in charge of automating the CI/CD process.
No previous knowledge is needed in any of the afore mentioned tools, the tutorial tries to keep things as basic as possible, but if you want to deepen your knowledge, 
links will be provided at the end of the blog for further reading. The chapters will be divided by the tools used. If you want to skip one or more 
chapters, because you already know the topic, or for any other reason, you can always just download its source code and fiddle with it alone. 

So now, without further ado, lets get started and explore the magical world of CI/CD. We will start with a small introduction of the workflows we are going to deploy. 

## Birds eye view

During this tutorial we are going to set up a jenkins server inside of an aws VPC. 
If you never worked with jenkins before, here is a little excerpt of what jenkins is: 

>Jenkins is a self-contained, open source automation server which can be used to automate all sorts of tasks such as building, testing, and deploying software. Jenkins can be installed through native system packages, Docker, or even run standalone by any machine with the Java Runtime Environment installed.

We are going to use jenkins as our automation server. 
During the tutorial we will create our jenkins server from the ground up, 
along with a designated slave that will be in charge of running our automation scripts. 
We will also create a simple node web server to demonstrate the capabilities of our CI/CD process, and as I mentioned, 
everything will be hosted under aws.

There is a lot to be done before we can start using jenkins. First, we need to create all the infrastructure 
needed to host a production ready jenkins server. 
The following chapters will focus on setting up the aws infrastructure required for hosting our jenkins server. We will 
start with creating a VPC and continue from there.
Also, everything is going to be hands on so you should follow along and try and run everything by yourselves.

[Next chapter: 2-AWS](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/2-aws) 
