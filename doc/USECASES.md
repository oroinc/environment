# Use Cases

## Core developer
```Cucumber
GIVEN I have GIT installed
 AND I have docker installed
 AND I have docker-compose installed
WHEN I do git clone https://github.com/laboro/dev
 AND Go to application folder (application/platform)
 AND Run docker-compose up -d
THEN webserver, php, DB containers are created
 AND I can run Composer
 AND I can install platform application
```

## QA
```Cucumber
GIVEN I have GIT installed
 AND I have docker installed
 AND I have docker-compose installed
WHEN I do git clone https://github.com/laboro/dev
 AND Go to application folder (application/platform)
 AND Run docker-compose up -d
 AND Run install script
THEN webserver, php, DB containers are created
 AND I can open in my browser platform.oro.dev
```

## CI server
```Cucumber
GIVEN GIT is installed
 AND docker installed
 AND docker-compose installed
WHEN Do git clone https://github.com/laboro/dev
 AND Open application folder (application/platform)
 AND Run docker-compose up -d
 AND Run install script
THEN webserver, php, DB containers are created
 AND CI can run UNIT tests
 AND CI can run FUNCTIONAL tests
 AND CI can run BEHAT tests
 ```

## Community developer or Partner
```Cucumber
GIVEN I have GIT installed
 AND I have docker installed
 AND I have docker-compose installed
WHEN I do git clone https://github.com/orocrm/platform-application to platform folder
 AND git clone https://github.com/orocrm/environment to environment folder
 AND Change dir to platform folder
 AND Run docker-compose up -d
THEN webserver, php, DB containers are created
 AND I can run Composer
 AND I can install platform application
```
