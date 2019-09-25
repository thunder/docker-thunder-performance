# Thunder CMS - Performance Docker Image

**NOTE:** This image requires Database server, Selenium service and Elastic APM server. It's not designed to work independently.

## How to use this image

The basic pattern for starting a Thunder Performance instance is:

`docker run --name thunder-performance --publish 8080:8080/tcp --env "DB_HOST=mysql-host" --env "CHROME_HOST=selenium-chrome-host" --env "THUNDER_HOST=thunder-host-for-chrome"--env "ELASTIC_APM_URL=http://elastic-apm-server:8200" thunder-performance:latest`

The container will require some time to install Thunder and after that it will start to serve on port 8080. Also, it will start executing performance tests. Performance tests are sending information to Elastic APM server.

## Available environment variables

### Database setup

- `DB_HOST` - database host
- `DB_NAME` - database name
- `DB_USER` - database username
- `DB_PASS` - database password
- `DB_PORT` - database port
- `DB_DIVER` - database driver. Allowed options are `mysql` and `pgsql` **(not tested)**

### Test related environment variables
- `THUNDER_HOST` - Chrome container requires Thunder host
- `CHROME_HOST` - Thunder test runner require Chrome host

### Elastic APM integration environments variables
- `ELASTIC_APM_URL` - Elastic APM Server URL (for example: `http://127.0.0.1:8200`)
- `ELASTIC_APM_CONTEXT_TAG_BRANCH` - Elastic APM requires branch information to group results

## How to build image

### Prepare Thunder project for Docker image

You should cleanup Thunder project before packaging it to docker image. You can do following steps:

- remove dev dependencies `composer install --no-dev`
- remove all files form `sites/default/files` directory `rm --recursive --force docroot/sites/default/files/*`
- remove `.git` directories `find . -type d -name ".git" | xargs rm --recursive --force` (build script will do this automatically)

After that, you can use `build.sh` script to package that project into docker image

`./build.sh --project-path <path to Thunder project> --tag <Docker image tag>`

## How to test image

### Running image locally

First of all, you have to create an image whenever you change something that could affect docker image content. For example docker scripts, Dockerfile, code in `www` folder, and so on.

1. You can create an image for testing locally with the following command: `./build.sh --tag travis-ci-test:latest`. We are using tag `travis-ci-test:latest`, because we are using the same tag in `test/docker-composer.travis-ci.yml` and we can use existing docker composer file without any changes.
2. After you have built a docker image for local testing, you can start docker-compose with the following command: `docker-compose --file="test/docker-composer.travis-ci.yml" --project-name test up`. The whole stack requires some time to get up and running. If you get a result after executing: `curl "http://localhost:8080/"`, then the stack is up and running.
3. Finally, you can run the same checks local as it would be on Travis CI by executing `./test/travis-ci-run.sh`

### Running image on AWS Fargate

1. If you have everything running locally and you are satisfied with your changes, then you can test built docker image on AWS Fargate too. For that, we first need a publicly available docker image. You can build an image with the following command: `./build.sh --tag burda/thunder-performance:pr-1-test`. You should use `burda/thunder-performance` docker hub repository for it.
2. When docker finishes with the building of the image, you have to push the image to the docker hub. You have to log in to docker hub first with `docker login` and after that, you can use `docker push` command to push the newly created image. For example: `docker push burda/thunder-performance:pr-1-test`. **NOTE:** Be sure that the docker image does not contain any secure data or information packed inside, otherwise it will be publicly available.
3. In AWS console, go to ECS and open `Task Definitions` and then `thunder_performance_runner`. Click on last runner revision and after that click on `Create new revision`.
4. For new revision of `thunder_performance_runner` scroll down to `Container Definitions` and click on `thunder`. In pop-up window change `Image` value to newly published image, for example: `burda/thunder-performance:pr-1-test`. Click on `Update` and then on `Create` to create a new task.
5. Next step is to run the newly created revision of task in AWS Fargate. After the creation of a new revision of task definition, you will land on the page with that task definition revision. Click on `Actions` drop-down and select `Run task`.
6. On new page select following: for `Launch type` select `Fargate`, for `Cluster VPC` select available VPC, for `Subnets` select `eu-central-1c` and for `Security groups` select existing group with name `thunder_performance_runner_security_group` and click `Save`
7. **OPTIONAL** If you want to have your task displayed differently on the Grafana dashboard, you can change tag name for it but clicking on `Advanced Options`, then expand `thunder` and change value for `ELASTIC_APM_CONTEXT_TAG_BRANCH` to value you that would describe your test.
8. By clicking on `Run Task`, you will create a new task on AWS Fargate. You will see `Created tasks successfully` message with the ID of your newly created task.

To check logs for your newly created task or any other task. You can click on task ID in the list and on the new page, you can expand a relevant container name. For every container, you can find a link with the name `View logs in CloudWatch` and if you click on that link, you will land on AWS CloudWatch with system log of that docker container.
