. docker.sh

exec_or_dryrun \
  $(docker_run) \
  $(docker_workdir) \
  $(docker_publish) \
  $(docker_image hello-world) \
  "$@"
