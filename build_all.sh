#!/usr/bin/env bash

error_exit() {
  echo -e "\nERROR EXITING: ${1}"
  exit 1
}

run_cmd () {
  run_cmd_status=0

  echo -e "  $@"
  if [[ $trial_run == false ]]; then
    eval "$@"
    run_cmd_status=$?
  fi
}

usage() {
  this_script="$(basename $0)"

  # Optional
  echo "Usage: ${this_script} [options]"

  echo "Optional options:"
  echo "  -t                        [false]    trial_run flag \\"
  echo "  -r                        [manageiq] registry name \\"

  echo "Example usage:"
  echo "${this_script} \\"
  echo "  -r my_registry \\"
  echo ""
}

parse_args() {
  echo -e "\n*** Invoked function ${FUNCNAME} ***"

  registry="manageiq"
  trial_run=false

  while getopts "r:t" opt; do
    case $opt in
    r)
      registry=$OPTARG
      ;;
    t)
      trial_run=true
      ;;
    ?)
      echo "*** ? ***"
      usage
      exit 1
      ;;
    :)
      echo "*** : ***"
      usage
      exit 1
      ;;
    esac
  done

  echo -e "\n    trial_run: ${trial_run}"
  echo -e "     registry: ${registry}"
}

cwd_images() {
  echo -e "\n*** Invoked function ${FUNCNAME} ***"

  if [[ -d images ]]; then
    pushd images
  else
    error_exit "images directory not found"
  fi
}

rm_old_logs() {
  echo -e "\n*** Invoked function ${FUNCNAME} ***"

  find . -name build.log | xargs rm
}

docker_cmd() {
  if [[ $# -ne 2 ]]; then
    error_exit "${FUNCNAME} invoked with wrong number of arguments"
  fi

  sub_cmd="$1"
  image_name="$2"

  if ! [[ -d ${image_name} ]]; then
    error_exit "${image_name} directory not found"
  fi

  if [[ ${sub_cmd} == "build" ]]; then
    run_cmd "docker build ${image_name} -t ${registry}/${image_name}:latest --no-cache > ${image_name}/build.log"
  elif [[ ${sub_cmd} == "push" ]]; then
    run_cmd "docker push ${registry}/${image_name}:latest >> ${image_name}/build.log"
  else
    error_exit "Unsupported docker sub command ${sub_cmd}"
  fi
}


docker_build_all_images() {
  echo -e "\n*** Invoked function ${FUNCNAME} ***"

  docker_cmd "build" "manageiq-base"
  docker_cmd "build" "manageiq-orchestrator"
  docker_cmd "build" "manageiq-base-worker"
  docker_cmd "build" "manageiq-webserver-worker"
  docker_cmd "build" "manageiq-ui-worker"
}

docker_push_all_images() {
  echo -e "\n*** Invoked function ${FUNCNAME} ***"

  docker_cmd "push" "manageiq-base"
  docker_cmd "push" "manageiq-orchestrator"
  docker_cmd "push" "manageiq-base-worker"
  docker_cmd "push" "manageiq-webserver-worker"
  docker_cmd "push" "manageiq-ui-worker"
}

echo -e "\n*** In main***"

parse_args "$@"
cwd_images
# docker_build_all_images
# docker_push_all_images

docker_cmd "build" "manageiq-base"
docker_cmd "push" "manageiq-base"

docker_cmd "build" "manageiq-orchestrator"
docker_cmd "push" "manageiq-orchestrator"

docker_cmd "build" "manageiq-base-worker"
docker_cmd "push" "manageiq-base-worker"

docker_cmd "build" "manageiq-webserver-worker"
docker_cmd "push" "manageiq-webserver-worker"

docker_cmd "build" "manageiq-ui-worker"
docker_cmd "push" "manageiq-ui-worker"

popd
