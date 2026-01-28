# GrumPHP Magento Convention

This package is to be required on all PHPro's Magento projects.

## Configuration 
The project `grumphp.yml` should contain at least:
```
imports:
    - { resource: './vendor/phpro/magento-conventions/grumphp-convention.yml' }
    
parameters:
  git.project: (FOO)
```

### Configurable parameters

#### GENERAL
| Parameter                | Default                                       | Info |
|--------------------------|-----------------------------------------------| --- |
| **root_conventions_dir** | vendor/phpro/magento-conventions/Conventions/ | Relative path to the root directory of the convention installation |

#### PHPCS
| Parameter | Default | Info |
| --- | --- | --- |
| **phpcs.standard** | [ Magento2, PSR2 ] | The standards to check code styling |
| **phpcs.severity** | ~ | Global severity level |
| **phpcs.warning_severity** | ~ | Warning severity level |
| **phpcs.error_severity** | ~ | Error severity level |
| **phpcs.whitelist_patterns** | [ '/^app\/code\/(.*)/' ] | Whitelist patterns to check code styling |
| **phpcs.ignore_patterns** | [ "Test/Unit", "Setup/Patch/Data", "Setup/Upgrade", "Setup/Install" ] | Ignore patterns |
| **phpcs.exclude** | [ Magento2.Functions.StaticFunction, Magento2.Exceptions.DirectThrow, Magento2.Exceptions.ThrowCatch, Magento2.Commenting.ClassAndInterfacePHPDocFormatting, Magento2.Commenting.ClassPropertyPHPDocFormatting, Magento2.Commenting.ConstantsPHPDocFormatting, Magento2.Annotation.MethodAnnotationStructure, Magento2.Annotation.MethodArguments ] | Bullet list of excluded sniffs |
| **phpcs.triggered_by** | [ php ] | Triggered by |

#### PHP CS FIXER
If you want to change the rules or check paths, we recommend to create and use your own `.php-cs-fixer.php` file in your project.

| Parameter | Default | Info |
| --- | --- | --- |
| **phpcs_file** | cs/.php-cs-fixer.php | Relative path to CS config file |
| **phpcsfixer.allow_risky** | ~ | Allow risky |
| **phpcsfixer.cache_file** | ~ | Create a .php_cs cache file |
| **phpcsfixer.config** | '%root_dir%%phpcs_file%' | Path to php CS config file |
| **phpcsfixer.rules** | [ ] | Add custom rules |
| **phpcsfixer.using_cache** | ~ | Use caching |
| **phpcsfixer.config_contains_finder** | true | Configuration file uses a finder |
| **phpcsfixer.verbose** | true | Verbose |
| **phpcsfixer.diff** | false | Diff |
| **phpcsfixer.triggered_by** | [ 'php' ] | Php triggered by files |

#### PHPLINT
| Parameter | Default | Info |
| --- | --- | --- |
| **phplint.exclude** | [ 'vendor' ] | Excluded directories |
| **phplint.jobs** | ~ | Lint jobs |
| **phplint.short_open_tag** | false | Short open tags |
| **phplint.ignore_patterns** | [ ] | ignore patterns |
| **phplint.triggered_by** | [ 'php', 'phtml' ] | Triggered by files |

#### PHPSTAN
For existing Magento 2 project, we recommend to set the level to `1` or `0` and fix the issues you encounter. 

The minimal PHPStan version in your project should be `0.12.65` to ensure the `excludePaths` config will work. 

| Parameter | Default | Info |  
| --- | --- | --- |
| **phpstan_file** | phpstan/phpstan.neon | Relative path to PHPStan neon file |
| **phpstan.autoload_file** | ~ | Autoload files |
| **phpstan.configuration** | '%root_dir%%phpstan_file%' | Path to configuration file |
| **phpstan.level** | 5 | Level of PHPstan (0-8) |
| **phpstan.triggered_by** | [ 'php' ] | PHPStan triggered files |
| **phpstan.memory_limit** | "-1" | Memory limit PHPStan uses |
| **phpstan.use_grumphp_paths** | true | Use GrumPHP paths |
| **phpstan.ignore_patterns** | [ "/Test/", "/Setup/", "pub/" ] | Ingore patterns |

#### PHPUNIT
Make sure you create a `phpunit.xml` file in your project root.

| Parameter | Default | Info |  
| --- | --- | --- |
| **phpunit.config_file** | ~ | Path to phpunit.xml  |
| **phpunit.testsuite** | ~ | Run tests for certain suite |
| **phpunit.group** | [ ] | Run tests for certain group |
| **phpunit.always_execute** | true | Always run the whole test suite, even if no PHP files were changed |
| **phpunit.order** | null | Run tests in a specific order |

#### COMPOSER
| Parameter | Default | Info |
| --- | --- | --- |
| **composer.file** | ./composer.json | File location |
| **composer.no_check_all** | false | Check all |
| **composer.no_check_lock** | true | Check lock file |
| **composer.no_check_publish** | true | Check publish |
| **composer.no_local_repository** | true | Check for local repo's |
| **composer.with_dependencies** | true | Check dependencies |
| **composer.strict** | false | Set composer to strict |

#### GIT
| Parameter                                | Default | Info                                                                         |
|------------------------------------------| --- |------------------------------------------------------------------------------|
| **git.project**                          | PROJECT| Project abbreviation code used in Jira. Use (FOO\|BAR) for multiple projects |
| **git_commit_message.matchers**          | ['/%git.project%-([0-9]*)/'] | Match commit message to PROJECT-{number}...                                  |
| **git_commit_message.max_subject_width** | 70 | Git commit subject message length                                            |
| **git_commit_message.max_body_width**    | 80 | Git commit body message length                                               |
| **git_commit_message.case_insensitive**  | true | Message is case sensitive                                                    |
| **git_commit_message.multiline**         | true | Message can contain multiple lines                                           |
| **git_branch_name.blacklist**            | [ "development", "production", "staging", "master", "infra" ] | List of non-wanted branch names                                              |
| **git_branch_name.whitelist**            | Check phpro-grumphp.yml itself | Allowed branch names                                                         |
| **git_blacklist.keywords**               | Check phpro-grumphp.yml itself | Disallowed words                                                             |
| **git_blacklist.triggered_by**           | ['php', 'js', 'html', 'phtml']| Triggered by files                                                           |
| **git_branch_name.allow_detached_head**  | true | Allow detached head                                                          |

#### FILE SIZE
| Parameter | Default | Info |
| --- | --- | --- |
| **file_size.size** | 5M | The maximum file size |
| **file_size.ignore_patterns** | [ ] | Patterns that will be ignored |

#### CLOVER
| Parameter | Default       | Info                                                     |
| --- |---------------|----------------------------------------------------------|
| **clover_coverage.clover_file** | ./.clover.xml | The maximum file size                                    |
| **clover_coverage.minimum_level** | 20            | Clover minimum level, this will hard fail if not reached |
| **clover_coverage.target_level** | 80            | Clover target level, this will soft fail if not reached  |

#### SECURITYCHECKER COMPOSERAUDIT
| Parameter                                     | Default  | Info                                         |
|-----------------------------------------------| --- |----------------------------------------------|
| **securitychecker_composeraudit.format**      | null     |                                              |
| **securitychecker_composeraudit.locked**      | true     |                                              |
| **securitychecker_composeraudit.no_dev**      | false    |                                              |
| **securitychecker_composeraudit.run_always**  | true     |                                              |
| **securitychecker_composeraudit.working_dir** | null     |                                              |
| **securitychecker_composeraudit.abandoned**   | ignore   | Ignore abandoned packages, Magento uses some |
