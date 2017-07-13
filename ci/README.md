# How to run test like CI

## Requirements

- bash 4 (with coreutils and readline)
- parallel (run parallel --citation and follow instructions after installation)
- docker
- docker-compose

## Flow

```
environment/ci/run.sh {TESTSUTE} {PATH_TO_ORO_APP}
```

## Clean Up if something goes wrong
```
docker ps -aq | xargs docker rm -fv
docker volume ls -q | xargs docker volume rm -f
docker network ls -q | xargs docker network rm
docker images -q | xargs docker rmi -f
```

### Unit

```
environment/ci/run.sh unit application/platform
environment/ci/run.sh unit application/platform vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Tests/Unit/EventListener
environment/ci/run.sh unit application/platform vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Tests/Unit/EventListener/TestSessionListenerTest.php
environment/ci/run.sh unit application/platform --filter="TestSessionListenerTest"
environment/ci/run.sh unit application/platform --filter="TestFrameworkBundle\\\\Tests\\\\Unit"
```

### PHP Code Style

```
ORO_CS=true environment/ci/run.sh unit application/platform
```

### Functional

```
environment/ci/run.sh functional application/platform
environment/ci/run.sh functional application/platform vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Tests/Functional
environment/ci/run.sh functional application/platform vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Tests/Functional/SchemaTest.php
environment/ci/run.sh functional application/platform --filter="SchemaTest"
environment/ci/run.sh functional application/platform --filter="TestFrameworkBundle\\\\Tests\\\\Functional"
```

### Documentation

```
environment/ci/run.sh documentation documentation/crm
environment/ci/run.sh documentation documentation/commerce
```

### JavaScript

```
environment/ci/run.sh javascript application/platform
```

### JavaScript Code Style

```
ORO_CS=true environment/ci/run.sh javascript application/platform
```

### Behat

```
environment/ci/run.sh behat application/platform
environment/ci/run.sh behat application/platform "-s OroHelpBundle"
environment/ci/run.sh behat application/platform "-s OroHelpBundle -vvv"
```
