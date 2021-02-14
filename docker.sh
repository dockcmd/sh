# source into your script
# sh compatible

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
# it=       --interactive --tty
# it=bash   --interactive --tty --entrypoint bash
# u=        --user

docker() {
  if ! [ $1 ]; then
    echo usage: docker image [arg1] [arg2] ... 1>&2
    exit 1
  fi

  # expand environment variables
  docker_expand $1

  shift

  # return docker run command with any entrypoint, interactive and tty options
  echo docker run --rm \
    ${i+-i} \
    ${t+-t} \
    $(docker_publish) \
    ${u:+--user "$u"} \
    ${m:+--mount "$m"} \
    ${w:+-w "$w"} \
    ${h:+--env HOME="$h"} \
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

  if ! [ -z ${hwm+0} ]; then
    case $PWD in
    $HOME*) ;;
    *)
      echo "hwm requires current directory $PWD to start with $HOME" 1>&2
      exit 1
      ;;
    esac

    h=${h-$HOME}
    w=${w-$PWD}
    m=${m-"type=bind,source=$HOME,target=$HOME,consistency=delegated"}
  fi

  if [ -p 0 ]; then
    # named pipe
    #
    # "xyz" | docker
    i=
  fi

  if ! [ -t 0 ]; then
    # not in terminal

    if ! [ -z ${it+0} ]; then
      echo it=$it requires terminal 1>&2
      exit 1
    fi

    # suppress any terminal
    unset t
  fi

  if ! [ -z ${ti+0} ]; then
    it=$ti
  fi

  if ! [ -z ${it+0} ]; then
    # it set (might be blank), expand to individual variables
    i=
    t=
    ep=${ep-$it}
  fi
}

docker_publish() {
  IFS=','
  for port in $p; do
    if [ $port ]; then
      if [ $port -eq $port ] 2>/dev/null; then
        # $port is an integer
        echo --publish $port:$port
      else
        echo --publish $port
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
    echo --env "$line"
  done
}
