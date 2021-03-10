#!/bin/sh

# Construct docker command, execute or print, and exit shell
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
  if ! [ "$1" ]; then
    echo usage: docker_run image[:tag] [arg1] [arg2] ... 1>&2
    exit 1
  fi

  # get image and tag and expand environment variables
  docker_expand "$1"
  shift

  # build command in reverse order

  # image and args
  set -- "$image${tag:+:$tag}" "$@"

  IFS=','
  for port in $p; do
    if [ $port ]; then
      if [ $port -eq $port ] 2>/dev/null; then
        # $port is an integer
        set -- -p "$port:$port" "$@"
      else
        set -- -p "$port" "$@"
      fi
    fi
  done
  unset IFS

  if [ "$e" ]; then
    while read line; do
      [ "$line" ] && set -- -e "$line" "$@"
    done <<EOF
$(env | grep -e "$e")
EOF
  fi

  # standard flags
  set -- docker run --rm ${i+-i} ${t+-t} \
    ${u:+--user "$u"} \
    ${v:+-v "$v"} \
    ${m:+--mount "$m"} \
    ${w:+-w "$w"} \
    ${eh:+-e "HOME=$eh"} \
    ${ep:+--entrypoint "$ep"} \
    "$@"

  # if dr not set, just exec.  exec terminates script
  [ -z "${dr+x}" ] && exec "$@"

  if [ "$dr" = l ]; then
    # dr list in long format unescaped
    for word in "$@"; do
      echo "$word \\"
    done
    exit 0
  fi

  echo "$@"
  exit 0
}

# expansion of environment variables
# it=
# m=
docker_expand() {
  IFS=':' read _image _tag <<EOF
$1
EOF

  image=${image-$_image}

  if ! [ "$tag" ]; then
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

    tag=${tag-$_tag}
  fi

  if [ -n "${t9t+x}" ]; then
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

  if [ -n "${ti+x}" ]; then
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
