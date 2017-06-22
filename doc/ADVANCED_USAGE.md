# Advanced Usage

First, we recommended to read the [official documentation](https://docs.docker.com/compose/overview/). 

### Available docker-compose configs
* **php71_nginx_pgsql_full_ee.yml** - PHP (7.1), Nginx, PostgreSQL, ElasticSearch (2.x) as Search engine, RabbitMQ as message queue engine  
  > Compatible only with enterprise edition of application

* **php71_nginx_mysql_full_ee.yml** - PHP (7.1), Nginx, MySQL, ElasticSearch (2.x) as search engine, RabbitMQ as message queue engine  
  > Compatible only with enterprise edition of application
* **php71_nginx_mysql_full_ce.yml** - PHP (7.1), Nginx, MySQL, ORM as search engine, DBAL as  message queue engine  
  > Compatible with enterprise and community edition of application
* **docker-compose.yml** - An alias for **php71_nginx_mysql_full_ce.yml** to simplify commands to standard `docker-compose up` in environment folder

## Prepare
Define environment variable with absolute path to the application root directory
```
export ORO_APP=$(realpath ~/orodev)/application/commerce-crm-ee
```
> This variable is required

Define environment variable with application env mode (prod or dev)
```
export SYMFONY_ENV=dev
```
> This variable is optional (will be in prod mode if not defined)

## Docker compose interaction

### Staring containers in detached mode
To start in detached mode your need to add `-d` option to `up` command:
```
docker-compose -p oro -f environment/php71_nginx_pgsql_full_ee.yml up -d
```

### Connect to container cli (command line interface) 
Is necessary to interaction with symfony cli commands
```
docker-compose -p oro -f environment/php71_nginx_pgsql_full_ee.yml exec --user www-data php bash
```
> To disconnect from container just execute `exit` command

### Stop containers (persistent data not be lose)
```
docker-compose -p oro -f environment/php71_nginx_pgsql_full_ee.yml stop
```

### Stop the hanged containers (persistent data not be lose)
```
docker-compose -p oro -f environment/php71_nginx_pgsql_full_ee.yml kill
```

### Destroy containers and data (persistent data will be lose)
```
docker-compose -p oro -f environment/php71_nginx_pgsql_full_ee.yml down -v
```

### Need more docker-compose commands?
```
docker-compose --help
```

### Clean up unused volumes (necessary to free disk space)
```
docker volumes prune
```
