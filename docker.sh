#!/bin/sh --posix

# Construct docker command, execute or print, and exit shell
#
# Externally set environment variables to configure docker run:
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
# image=    image

# disable check for environment variable defined as most all set externally
# shellcheck disable=SC2154

docker_run() {
  if ! [ "$1" ]; then
    echo usage: docker_run image [arg1] [arg2] ... 1>&2
    exit 1
  fi

  # get any image override
  docker_image "$1"
  shift

  # expand environment variables
  docker_expand

  #
  # have to preserve "$@" passed into docker_run as the arguments
  #
  # therefore, need to build command in reverse order
  #

  # image and args
  set -- "$image" "$@"

  for port in $p; do
    if [ "$port" ]; then
      if [ "$port" -eq "$port" ] 2>/dev/null; then
        # $port is an integer
        set -- -p "$port:$port" "$@"
      else
        set -- -p "$port" "$@"
      fi
    fi
  done

  if [ "$e" ]; then
    # shellcheck disable=SC2013
    for name in $(awk 'BEGIN{for(v in ENVIRON) print v}' | grep -E -e "^($e)"); do
      set -- -e "$name=$(printenv -- "$name")" "$@"
    done
  fi

  # finally get to docker run with standard flags
  set -- docker run --rm ${i+-i} ${t+-t} \
    ${u:+--user "$u"} \
    ${v:+-v "$v"} \
    ${ds:+-v /var/run/docker.sock:/var/run/docker.sock} \
    ${m:+--mount "$m"} \
    ${w:+-w "$w"} \
    ${eh:+-e "HOME=$eh"} \
    ${ep:+--entrypoint "$ep"} \
    "$@"

  # if dr not set, just exec.  exec terminates script
  ! [ "${ddr+_}" ] && exec "$@"

  xpn_escape "$1"
  shift
  for param; do
    printf ' '
    [ "$ddr" = l ] && printf '\\\n'
    xpn_escape "$param"
  done
  printf "\n"

  exit 0
}

xpn_escape() {
  case $1 in
  *[[:space:]\|\&\;\<\>\(\)\$\`\\\"\'*?[]* | ~*)
    printf %s "$1" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"
    ;;
  *)
    printf %s "$1"
    ;;
  esac
}

docker_image() {
  # image defintion order -> externally supplied environment variable, docker_image file, $1
  [ "$image" ] && return

  f="${DOCKER_IMAGE-$HOME/.docker_image}"
  if [ -f "$f" ]; then
    # image:tag
    image="$(grep -m 1 -e '^[[:space:]]*'"${1%:*}:" "$f")" &&
      return

    # image=image:tag
    __="$(grep -m 1 -e '^[[:space:]]*'"${1%:*}=" "$f")" &&
      image="${__#*=}" &&
      return
  fi

  # default to provided value
  image="$1"
}

# expansion of environment variables
# it=
# m=
docker_expand() {
  if ! [ "$t9t" = - ] && [ "${t9t+_}" ]; then
    case $PWD in
    $HOME*) ;;
    *)
      echo "docker: transparent mode (t9t) requires current directory $PWD be in $HOME" 1>&2
      exit 1
      ;;
    esac

    eh="${eh-$HOME}"
    v="${v-$HOME:$HOME:delegated}"
    w="${w-$PWD}"
  fi

  if [ -n "${ti+_}" ]; then
    t=
    i=
    if [ "$ti" ] && ! [ "$ep" ]; then
      ep="$ti"
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