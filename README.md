# Docker Shell Script Functions

Script to be included to add various docker shell script functions.

## Usage

Typical usage with shmod:

```bash
. shmod
import dockcmd/sh@v0.0.3 docker.sh

run `docker hello-world` "$@"
```

## Hello World

```bash
dr=l ./hello-world.sh
dr=l p=80 ./hello-world.sh
```

## Test

```bash
# tty interactive
ti= ./docker-test.sh
# test port
p=3000 ./docker-test.sh
```