#!/bin/sh

# Construct docker command line
#
# environment variables used as parameters
#
# it=sh docker alpine -->  docker run -it --entrypoint sh --rm alpine
#
# e=^AWS_   --env (env | grep ^AWS_)
# ep=bash   --entrypoint bash
# i=        -i
# t=        --tty
# ti=       --interactive --tty
# ti=bash   --interactive --tty --entrypoint bash
# u=        --user
# v=        -v

docker_run() {
  if ! [ $1 ]; then
    echo usage: docker image [arg1] [arg2] ... 1>&2
    exit 1
  fi

  # expand environment variables
  docker_expand $1
  shift

  # return docker run command with any entrypoint, interactive and tty options
  docker_exec \
    docker run \
    --rm \
    ${i+-i} \
    ${t+-t} \
    $(docker_publish) \
    ${u:+--user "$u"} \
    ${v:+-v "$v"} \
    ${m:+--mount "$m"} \
    ${w:+-w "$w"} \
    ${eh:+-e HOME="$eh"} \
    $(docker_env) \
    ${ep:+--entrypoint "$ep"} \
    $image${tag:+":$tag"} \
    "$@"
}

# expansion of environment variables
# it=
# m=
docker_expand() {
  IFS=':' read _image _tag <<EOF
$1
EOF

  if ! [ $image ]; then
    image=$_image
  fi

  if ! [ $tag ]; then
    # check for tag override
    f=${DOCKER_IMAGE-~/.docker_image}
    if [ -f $f ]; then
      while IFS=':' read _image _otag || [ "$_image" ]; do
        if [ "$image" == "$_image" ]; then
          tag=$_otag
          break
        fi
      done <$f
    fi

    if ! [ $tag ]; then
      tag=$_tag
    fi
  fi

  if ! [ -z ${t9t+0} ]; then
    case $PWD in
    $HOME*) ;;
    *)
      echo "docker: transparent mode (t9t) requires current directory $PWD be in $HOME" 1>&2
      exit 1
      ;;
    esac

    eh=${eh-$HOME}
    v=${v-"$HOME:$HOME:delegated"}
    w=${w-$PWD}
  fi

  if ! [ -z ${ti+0} ]; then
    t=
    i=
    if [ $ti ] && ! [ $ep ]; then
      ep=$ti
    fi
  fi

  if [ -p 0 ]; then
    # named pipe, force interactive
    i=
  fi

  if ! [ -t 0 ]; then
    # the input device is not a TTY
    # suppress docker TTY
    unset t
  fi
}

docker_publish() {
  IFS=','
  for port in $p; do
    if [ $port ]; then
      if [ $port -eq $port ] 2>/dev/null; then
        # $port is an integer
        echo "-p" "$port:$port"
      else
        echo "-p" "$port"
      fi
    fi
  done
}

# Add env grep'd from this environment
docker_env() {
  if ! [ $e ]; then
    return
  fi

  env | grep $e | while IFS= read -r line; do
    echo "-e" "$line"
  done
}

# if dryrun (dr) is not assigned, exec cmd, otherwise print cmd
# will not return from this function
docker_exec() {
  ! [ $1 ] &&
    exit 0

  # if dr not set, just exec.  exec terminates script
  [ -z ${dr+x} ] &&
    exec "$@"

  if [ "$dr" = l ]; then
    # dr list in long format unescaped
    for word in "$@"; do
      echo $word \\
    done
    exit 0
  fi

  echo "$@"
  exit 0
}

# shmod requires git
if ! command -v git >/dev/null; then
  echo "Error: git is required for shmod." 1>&2
  exit 1
fi
