# docker-bind-sql-base-alpine

Base Docker image containing BIND 9 project of Internet Systems Consortium (https://www.isc.org/bind/)

## Goals
- **Enabled SQL backend support** (compiled with `--with-dlz-mysql`)
- Simple base image for widely usable DNS server configurations
- Small Alpine Linux footprint
- Preinstalled Python and pip for extended scripting/templating (or use tag `nopython-latest`)

## Configuration

### /container/init.d
The default entrypoint of this image runs `/container/init` which will invoke all files mounted into `/container/init.d/`. 

That directory may/should be mounted read only. Files don't need to be executable (`chmod +x`). They need at least **have an file extension** like `file.sh` or `script.py` and **start with a correct shebang** like: `#!/bin/sh`.

Contained files are always copied into a temporary directory before being executed. This if for compensating non executable files mounted read only. File attributes can't be fixed on them directly.

This mountpoint is **not required** if you mount `/etc/bind/` with your own config directly.


### /container/default-zones
This directory contains some default zone data files.

It may be mounted with custom files.

If mounted, the directory should be mounted read only.

Init scripts contained in `/container/init.d/` may copy zone files to an appropriate directory like `/var/named/`.

This mountpoint is **not required**.


### Volumes
`/var/named` and `/etc/bind` are exposed as volumes by the Dockerfile.

Heavily depending on your application of this image you should mount static config and data (read only), persistent (and named) volumes or at least a `tmpfs` mount.


### CMD
This container starts with `/bin/sh` after a successful run of all init scripts by default if no explicit command has been specified. The actual command to start BIND 9's daemon `named` should be specified on calling `docker run` or configured in a `docker-compose.yml`.


## Sample applications
Some basic sample applications and their documentation can be found at:  
https://github.com/sausix/docker-bind-applications


## License
Sourcecode contained in this respository is licensed under:

`GNU GENERAL PUBLIC LICENSE, version 3`


BIND 9 (Internet Systems Consortium, Inc., https://www.isc.org) and its components contained in the resulting Docker image are licensed under:

`Mozilla Public License, version 2.0`
