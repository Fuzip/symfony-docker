# Symfony Docker

A Docker Symfony project template ready to use !

![CI](https://github.com/Fuzip/symfony-docker/workflows/CI/badge.svg)

## Features

* PHP 8 support
* Symfony 7 support
* No superflu configuration
* Caddy server
* CI ready
* Automatic HTTPS
* XDebug integration


## Development

1. Install [Docker Desktop](https://docs.docker.com/desktop/) (or
[Docker Engine](https://docs.docker.com/engine/)).
2. Run `make start` to build and start the Docker image.
3. Open `https://localhost` in your favorite web browser and [accept the auto-generated TLS certificate]


## Troubleshooting


### [macOS] setfacl : Operation not supported

Inside the PHP entrypoint container (`docker-entrypoint.sh`), `setfacl` command
is used to set permission for the web-server user `www-data`
on the `var` folder.

This behavior is due to macOS ACLs on Docker bind mount, see this [thread](https://stackoverflow.com/a/77241711/10224525).

For the moment, the bind mount on the var folder is keep to get the content folder
on the host.

If some error happen on the PHP container, please delete the `var` folder
from your host and re-up the docker stack with : `make start`.


## License

Available under the MIT License.


## Authors

Created by [Fuzip](https://github.com/fuzip).
