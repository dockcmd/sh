# standard docker call, pass image
docker() {
  if [ $# -ne 1 ]
  then
    echo usage: docker image 1>&2
    exit 1
  fi

  docker_run
  docker_home_workdir
  docker_image $1
}

# return docker run command with defaults and overrides for 
# tty, interactive, entrypoint and publish (ports)
docker_run() {
  if [ $1 ]
  then
    echo usage: docker_run 1>&2
    exit 1
  fi

  if ! [ -z ${ti+0} ] ||  ! [ -z ${it+0} ]
  then
    # ti or it set (might be blank), expand to individual variables
    i=
    t=
  fi

  if [ -p 0 ]
  then
    # ensure interactive if named pipe
    i=
  fi

  if ! [ -z ${bash+0} ]
  then
    # bash=
    ep=bash
    i=
    t=
  elif ! [ -z ${sh+0} ]
  then
    # sh=
    ep=sh
    i=
    t=
  fi

  if ! [ -t 0 ]
  then
    # if not in terminal, suppress tty
    unset t
  fi

  # return docker run command with any entrypoint, interactive and tty options
  echo docker run --rm ${ep:+--entrypoint $ep} ${i+--interactive} ${t+--tty}

  # add port publishing
  IFS=','
  for port in $p
  do
    if [ $port ] 
    then
      if [ $port -eq $port ] 2>/dev/null
      then
        # $port is an integer
        echo --publish $port:$port
      else
        echo --publish $port
      fi
    fi
  done
}

# return docker image with any override tag or use tag provided
docker_image() {
  if [ $# -ne 1 ]
  then
    echo usage: image image[:tag] 1>&2
    exit 1
  fi

  IFS='@' read image tag <<< "$1"

  # check for tag override
  f=${DOCKER_IMAGE-~/.docker_image}
  if [ -f $f ]
  then
    while IFS=':' read _image _tag || [ "$_image" ]
    do
      if [ "$image" == "$_image" ]
      then
        tag=$_tag
        break
      fi
    done < $f
  fi

  # prepend a ':' if $tag set and not null, otherwise leave as null 
  echo $image${tag:+":$tag"}
}

# add --user flag if UID is present
docker_user() {
  if [ $1 ]
  then
    echo usage: docker_user 1>&2
    exit 1
  fi

  if [ -z ${u-x} ]
  then
    # if u is null: u=
    return
  fi
  
  if [ "$u" ]
  then
    echo --user $u
    return
  fi

  if [ "$UID" ]
  then
    echo --user $UID${GROUPS+:$GROUPS}
    return
  fi
}

# if current directory is a home subdirectory, then mount home and set work dir to
# the path.  This allows for directory traversal.
#
docker_workdir() {
  if [ $1 ]
  then
    echo usage: docker_workdir 1>&2
    exit 1
  fi

  if [[ $PWD == $HOME* ]]
  then
    echo --mount type=bind,source=$HOME,target=/wd,consistency=delegated
    echo --workdir ${PWD/$HOME//wd} 
  else
    echo --mount type=bind,source=$PWD,target=/wd,consistency=delegated
    echo --workdir /wd
  fi
}

# if current directory is a home subdirectory, then mount home and set work dir to
# the path.  This allows for directory traversal.
docker_home_workdir() {
  if [ $1 ]
  then
    echo usage: docker_home_workdir 1>&2
    exit 1
  fi

  # mount home
  echo --env HOME=$HOME
  echo --mount type=bind,source=$HOME,target=$HOME,consistency=delegated
 
  if [[ $PWD == $HOME* ]]
  then
    # current directory has a base as current home
    echo --workdir ${PWD}
  else
    # current directory is outside, mount separately
    echo --mount type=bind,source=$PWD,target=/wd,consistency=delegated
    echo --workdir /wd
  fi
}
