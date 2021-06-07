#!/bin/sh
. shmod
import github.com/sageify/shert@v0.0.1 shert.sh

. docker.sh

# dry run for entire test and do image mapping
export ddr="" DOCKER_IMAGE=docker_image

shert_equals 'docker_run helm:3.5.4' "docker run --rm helm:3.5.4"
shert_equals 'docker_run alpine/helm:3.5.1' "docker run --rm alpine/helm:3.5.4"
shert_equals 'docker_run alpine/helm' "docker run --rm alpine/helm:3.5.4"
shert_equals 'docker_run ubuntu' "docker run --rm ubuntu:20.04"

image=helloworld shert_equals 'docker_run ubuntu' "docker run --rm helloworld"
