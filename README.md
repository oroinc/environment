# Introduction

A [Dockerized](https://www.docker.com) development environment for applications based on [OroPlatform](https://oroinc.com).

## Installation
- [Installation on Linux based distribution](doc/INSTALL.md)
- [Installation on macOS (OSX)](doc/OSX.md)

## Additional Information
- [Advanced Usage](doc/ADVANCED_USAGE.md)
- [Run tests in Docker environment](doc/TESTING.md)
- [Run tests like CI server](ci/README.md)
- [Switch database, php and other services version](doc/VARIABLES.md)
- [Use Cases](doc/USECASES.md)

## Quick Start

1. Clone repository to your local machine  
    ```
    git clone git@github.com:laboro/dev.git ~/orodev
    ```
  
2. Configure GitHub token for current project. To retrieve new token [follow by this link](https://github.com/settings/tokens/new?scopes=repo&description=Composer+OroEnv).
    ```
    docker run -v $(realpath ~/orodev)/environment/.composer/auth/:/usr/local/composer/auth oroinc/composer:1.4 config -g github-oauth.github.com <YOUR_GITHUB_AUTH_TOKEN>
    ```

3. Define environment variable with absolute path to the application root directory
    ```
    export ORO_APP=$(realpath ~/orodev)/application/commerce-crm-ee
    ```

4. Define environment variable with application env mode (prod or dev, prod by default)
    ```
    export SYMFONY_ENV=prod
    ```
    > This variable is required

5. Run docker compose
    ```
    docker-compose -p oro -f environment/php71_nginx_pgsql_full_ee.yml up
    ```
    > This variable is optional (will be in prod mode if not defined)

6. Wait until composer vendors installation. Proceed once you see next message
    
    > oro_composer_1 exited with code 0

7. Then open in your web-browser <http://webserver.oro.docker> and continue via web installation wizard.  

## Environment Credentials For Install

### Database  connection
Driver: `PostgreSQL`  
Host: `database`  
Port: `empty`  
Name: `oro_db`  
User: `oro_db_user`  
Password: `oro_db_pass`  
Drop database: `None`  

### Mail Settings:  
Transport: `SMTP`  
Host: `mail`  
Port: `1025`  
Encryption: `None`  
user: `empty`  
password: `empty`  

### Websocket connection:  
Service bind address: `0.0.0.0`  
Service bind port: `8080`  
WS Backend host: `*`  
WS Backend port: `8080`  
WS Frontend host: `*`  
WS Frontend port: `8080`  

## Mail and RabbitMQ Web-GUIs

### MailHog
All emails what be sent from application will be catched by [MailHog](https://github.com/mailhog/MailHog).  
Web-GUI available by url: `http://mail.{project_name}.docker:1080` (for example: <http://mail.oro.docker:1080>)

### RabbitMq (available only if you use EE setup)

UI: `http://mq.{project_name}.docker:15672` (for example: <http://mq.oro.docker:15672>)  
User: `oro_mq_user`  
Password: `oro_mq_pass`  

## Shutdown environment
If you want to stop environment for future just press `ctrl + c`, in detached mode run: 
  ```
  docker-compose -p oro -f environment/php71_nginx_pgsql_full_ee.yml stop
  ```
  
## Restore after shutdown
  ```
  docker-compose -p oro -f environment/php71_nginx_pgsql_full_ee.yml up
  ```

## Reinstall application
  1. Destroy docker containers with volumes
      ```
      docker-compose -p oro -f environment/php71_nginx_pgsql_full_ee.yml down -v
      ```
      > Warning it is destroy all persistent data (database, search, mq, etc..)
  2. Delete application cache  
      ```
      rm -rf "${ORO_APP}/app/cache/*"
      ```
  3. Delete application config  
      ```
      rm -rf "${ORO_APP}/app/config/parameters.yml"
      ```
  4. Run new containers
      ```
      docker-compose -p oro -f environment/php71_nginx_pgsql_full_ee.yml up
      ```

## Troubleshooting

Run commands one by one to clean up your environment
```
docker ps -aq | xargs docker rm -fv
docker volume ls -q | xargs docker volume rm -f
docker network ls -q | xargs docker network rm
docker images -q | xargs docker rmi -f
```
