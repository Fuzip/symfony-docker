# SymfonyDocker

SymfonyDocker is a boiler template with a Symfony application hosted on Caddy server, ready to be used with Docker compose.

[[_TOC_]]

## Requirement

Work in progress...

## Installation

Use the Make command `install` :
```shell
make install
```

The `install` command initialize the environment file of Docker and Symfony, then run
the project with Docker compose.

## Uninstallation

Use the Make command `uninstall` :

```shell
make uninstall
```

The `uninstall` command will stop and remove the Docker container. **Docker volumes and images
will be also deleted.** Then, Symfony cache and build folder will be deleted (root password
will be asked).

## Deployment

Work in progress...
