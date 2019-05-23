# Thunder CMS - Performance Docker Image

**NOTE:** This image requires Database server, Selenium service and Elastic APM server. It's not designed to work independently.

## How to use this image

The basic pattern for starting a Thunder Performance instance is:

`docker run --name thunder-performance -p 8080:8080/tcp -e "DB_HOST=mysql-host" -e "CHROME_HOST=selenium-chrome-host" -e "THUNDER_HOST=thunder-host-for-chrome" -e "ELASTIC_APM_URL=http://elastic-apm-server:8200" thunder-performance:latest`

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
- `ELASTIC_APM_URL` - Elastic APM Server URL (for example: "http://127.0.0.1:8200")
- `ELASTIC_APM_CONTEXT_TAG_BRANCH` - Elastic APM requires branch information to group results

## How to build image

### Prepare Thunder project for Docker image

You should cleanup Thunder project before packaging it to docker image. You can do following steps:

- remove dev dependencies `composer install --no-dev`
- remove all files form `sites/default/files` directory `rm -rf docroot/sites/default/files/*`
- remove `.git` directories `find . -type d -name ".git" | xargs rm -rf` (build script will do this automatically)

After that, you can use `build.sh` script to package that project into docker image

`./build.sh <path to Thunder project>`
