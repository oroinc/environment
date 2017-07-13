# How to run test like CI


## Flow

```
export ORO_APP=~/dev/application/commerce-crm-ee
docker-compose -f environment/unit.yml up -d
docker-compose -f environment/unit.yml run php bin/phpunit --testsuite=unit
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
export ORO_APP=~/dev/application/commerce-crm-ee
docker-compose -f environment/unit.yml up -d
docker-compose -f environment/unit.yml run composer install --prefer-dist --no-suggest --no-interaction --ignore-platform-reqs --optimize-autoloader
docker-compose -f environment/unit.yml run php bin/phpunit --testsuite=unit
docker-compose -f environment/unit.yml run php bin/phpunit vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Tests/Unit/EventListener
docker-compose -f environment/unit.yml run php bin/phpunit vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Tests/Unit/EventListener
docker-compose -f environment/unit.yml run php bin/phpunit vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Tests/Unit/EventListener/TestSessionListenerTest.php
docker-compose -f environment/unit.yml run php bin/phpunit --filter="TestSessionListenerTest"
docker-compose -f environment/unit.yml run php bin/phpunit --filter="TestFrameworkBundle\\\\Tests\\\\Unit"
docker-compose -f environment/unit.yml down -v
```

### PHP Code Style

```
export ORO_APP=~/dev/application/commerce-crm-ee
docker-compose -f environment/unit.yml up -d
docker-compose -f environment/unit.yml run composer install --prefer-dist --no-suggest --no-interaction --ignore-platform-reqs --optimize-autoloader
docker-compose -f environment/unit.yml run php bin/phpcs vendor/oro -p --encoding=utf-8 --extensions=php --standard=vendor/oro/platform/build/phpcs.xml
docker-compose -f environment/unit.yml run run php bin/phpmd vendor/oro text /var/www/package/commerce/build_config/phpmd.xml --suffixes php
docker-compose -f environment/unit.yml run run run php bin/phpcpd vendor/oro/commerce
docker-compose -f environment/unit.yml down -v
```

### Functional

```
export SYMFONY_ENV=test
export ORO_APP=~/dev/application/commerce-crm-ee
# prepare parameters_test.yml
docker-compose -f environment/functional.yml up -d
docker-compose -f environment/functional.yml run composer install --prefer-dist --no-suggest --no-interaction --ignore-platform-reqs --optimize-autoloader
docker-compose -f environment/functional.yml run php app/console oro:install --no-interaction --skip-assets --skip-translations --user-name=admin --user-email=admin@example.com --user-firstname=John --user-lastname=Doe --user-password=admin --sample-data=n --organization-name=Oro --application-url='http://localhost/' --timeout=600
docker-compose -f environment/functional.yml run php bin/phpunit --testsuite=functional
docker-compose -f environment/functional.yml run php bin/phpunit vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Tests/Functional
docker-compose -f environment/functional.yml run php bin/phpunit vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Tests/Functional/SchemaTest.php
docker-compose -f environment/functional.yml run php bin/phpunit --filter="TestFrameworkBundle\\\\Tests\\\\Functional\\\\SchemaTest"
docker-compose -f environment/functional.yml run php bin/phpunit --filter="TestFrameworkBundle\\\\Tests\\\\Functional"
docker-compose -f environment/functional.yml down -v
```

### Documentation

```
docker run -v ~/dev/documentation/crm:/documentation oroinc/documentation:python-2.7-alpine
docker run -v ~/dev/documentation/commerce:/documentation oroinc/documentation:python-2.7-alpine
```

### JavaScript

```
export ORO_APP=~/dev/application/commerce-crm-ee
docker-compose -f environment/javascript.yml up -d
docker-compose -f environment/functional.yml run composer install --prefer-dist --no-suggest --no-interaction --ignore-platform-reqs --optimize-autoloader
docker-compose -f environment/javascript.yml run php npm install --prefix vendor/oro/platform/build/
docker-compose -f environment/javascript.yml run php vendor/oro/platform/build/node_modules/.bin/jscs --config=vendor/oro/platform/build/.jscsrc vendor/oro
docker-compose -f environment/javascript.yml run php vendor/oro/platform/build/node_modules/.bin/jshint --config=vendor/oro/platform/build/.jshintrc --exclude-path=vendor/oro/platform/build/.jshintignore vendor/oro
docker-compose -f environment/javascript.yml down -v
```

### Behat

```
export SYMFONY_ENV=prod
export ORO_APP=~/dev/application/commerce-crm-ee
docker-compose -f environment/behat.yml up -d
docker-compose -f environment/behat.yml run composer install --prefer-dist --no-suggest --no-interaction --ignore-platform-reqs --optimize-autoloader
```

Create ~/dev/application/commerce-crm-ee/behat.yml from ~/dev/application/commerce-crm-ee/behat.dist.yml, for example:

```behat.yml
imports:
  - ./vendor/oro/platform/src/Oro/Bundle/TestFrameworkBundle/Resources/config/behat.yml.dist

default: &default
    gherkin:
        filters:
            tags: ~@not-automated&&~@skip&&~@community-edition-only
    extensions: &default_extensions
        Behat\MinkExtension:
            base_url: 'http://webserver:80/'
            sessions:
                second_session:
                    oroSelenium2:
                        wd_host: "http://browser:8910/wd/hub"
                first_session:
                    oroSelenium2:
                        wd_host: "http://browser:8910/wd/hub"
        Behat\Symfony2Extension: ~
        Oro\Bundle\TestFrameworkBundle\Behat\ServiceContainer\OroTestFrameworkExtension:
            reference_initializer_class: Oro\Bundle\ApplicationBundle\Tests\Behat\ReferenceRepositoryInitializer
            shared_contexts:
                - Oro\Bundle\TestFrameworkBundle\Tests\Behat\Context\OroMainContext
                - Oro\Bundle\TestFrameworkBundle\Tests\Behat\Context\FixturesContext
                - OroActivityListBundle::ActivityContext
                - OroDataGridBundle::GridContext
                - OroSecurityBundle::ACLContext
                - OroSecurityBundle::PermissionContext
                - OroSearchBundle::SearchContext
                - OroImportExportBundle::ImportExportContext:
                    - '@oro_entity.entity_alias_resolver'
                    - '@oro_importexport.processor.registry'
                - OroAddressBundle::AddressContext
                - OroApplicationBundle::CommerceMainContext
                - OroCustomerBundle::CustomerUserContext
                - OroOrderBundle::OrderContext
                - OroSalesBundle::SalesContext
                - Oro\Bundle\ShippingProBundle\Tests\Behat\Context\MultiplyCurrencyContext
                - OroShoppingListBundle::ShoppingListContext
                - OroRedirectBundle::SlugPrototypesContext

selenium2:
    <<: *default
```

```
docker-compose -f environment/behat.yml run php bin/behat -s OroInstallerBundle -v
docker-compose -f environment/behat.yml run php bin/behat --available-suites

# run full suite
docker-compose -f environment/behat.yml run php bin/behat -f progress -v

# or specific one
docker-compose -f environment/behat.yml run php bin/behat -f progress -v -s OroHelpBundle
```
