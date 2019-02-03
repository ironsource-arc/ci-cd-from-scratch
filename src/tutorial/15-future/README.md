# infra-team-ci-cd

## our CI/CD process using, docker, jenkins, ansible, and much much more.

At ironSource infra team, we are responsible for developing an automation framework to help test our various products.
Deploying hundreds of microservices across different platforms, cloud providers and on-prem solutions can become a cumbersome
task. To alleviate the effort of supporting a growing, auto scalable architecture, we had to develop a flexible ci / cd process. One that is easily reused and one that its building blocks are easily replaced. 
This tutorial will walk you through all the steps we use to create our CI/CD infrastructure. 

## Future work

I covered a lot of topics in this tutorial. I also covered a lot of tools. Some of them are here to stay like aws, terraform, and docker. 
Some of them are currently still relevant but they might not be in the near future (I'm looking at you packer)
and some of them are already deprecated. 
My handling of branches in the Jenkinsfile for example are currently better handled using the multi-branch pipeline package offered by Jenkins.
Also, creating an aws infrastructure for hosting our jenkins servers might be an overkill. 
There are a lot of tutorials and examples online that host jenkins as a docker container inside of a kubernetes cluster or a docker swarm cluster.
If at some point I will write a new tutorial that will definitely be the first thing to improve - hosting all of our services as part of a kubernetes cluster. 


## Closing words

This tutorial took me a lot of time to finish. 
I learned a lot during the creation of this tutorial about terraform, packer, aws and basically all the tools I covered. It has been an amazing journey and I hope that if you are
reading this and you got this far you might feel the same way.

[Previous chapter - 14-webesrver-infra](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/14-webesrver-infra) 
