# Docker Command Shell Script Function

Provides a *docker_run* shell script function to automate the construction and configuration of a *docker run* command. 

Function is primarily used in the [misc-sh](https://github.com/dockcmd/misc-sh) shell scripts that enable programs via docker calls.

## Usage

Typical usage with shmod:

```sh
cat > ubuntu.sh <<_
. shmod
import dockcmd/sh@v0.0.6 docker.sh

docker_run hello-world "$@"
_

```

## Configuration

The docker run command is created via environment variables:

```
ddr=      signify dry run
e=^AWS_   --env (env | grep ^AWS_)
ep=bash   --entrypoint bash
i=        -i
t=        --tty
ti=       --interactive --tty
ti=bash   --interactive --tty --entrypoint bash
u=        --user
v=        -v
image=    image
```

## Hello World
To view the docker run command created instead of executing it, use *ddr=* before calling the script.

```bash
ddr=l ./hello-world.sh
ddr=l p=80,8080 ./hello-world.sh
```

## Test

```bash
# tty interactive
ti= ./docker-test.sh
# test port
p=3000 ./docker-test.sh
```