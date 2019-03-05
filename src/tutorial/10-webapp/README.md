> At ironSource infrastructure team, we are responsible for developing an automation framework to help test our various products.

## Creating the web server

I already created a "Hello world" web server app that we can deploy to test our CI/CD process. 
The app is located in the following path: `$ cd /Users/$USER/ci-cd-from-scratch-webserver/src/`
I added a health route to my koa web server that will return our latest commit and node environment. 
You don't need to be fluent in node to understand the app, It's as simple as its going to get. The only route we have in our
little api is the health route. Here is the index file of our web server: 

```sh
$ cat index.js
```

```js
'use strict';


import './config';
import { name } from '../package.json';
import Koa from 'koa';
import Router from 'koa-router';
const app = new Koa();
const router = new Router();
const GIT_COMMIT = process.env.GIT_COMMIT || 'no git commit';
const NODE_ENV = process.env.NODE_ENV || 'no branch';


// app configuration
app.name = pjson.name

app.use(router.routes());

async function health(ctx, next) {
  ctx.body = {
    message: 'up',
    commit: GIT_COMMIT,
    branch: NODE_ENV
  };
  ctx.status = 200;
}

router.get('/health', health);

app.listen(8000);
```

Also, I created a simple test file just to get us started. The test doesn't do much. Just asserts that 16 is equal to 16, but we add 
it for completeness and to demonstrate our capabilities of running our unit tests as part of the CI/CD process.
Here is the test file: 
```sh
$ cat ../test/spec/test.spec.js
```

```js
'use strict';

import { expect } from 'chai'

describe('this is a simple function test', function() {

  it('should equal', function() {

    expect(16).to.equal(16);

  });

});
```

That's all there is to it. If you want to run the app locally, you can start the service in one terminal window.
```sh
$ cd /Users/daniel.zinger/ci-cd-from-scratch-webserver/src/app
npm start
```

Once the app loads, you can curl the health route: 
```sh
$ curl localhost:8000/health

{"message":"up","commit":"no git commit","branch":"no branch"}
```

Thats everything we need to know about the app itself. The interesting stuff is the deployment process. We will continue to work on the deployment in the next chapter.

[Previous chapter: 9-UI-slave](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/9-UI-slave) 

[Next chapter: 11-Create-job](https://github.com/ironSource/ci-cd-from-scratch/tree/master/src/tutorial/11-create-job) 
