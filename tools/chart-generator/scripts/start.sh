#!/bin/bash
set -e

readonly INITIAL_DIR=$(pwd)

source ./lib/config.sh
source ./lib/constants.sh
source ./lib/bootstrap.sh

function performAction() {
  show "Performing action - '$ACTION'" "h1"

  if [[ "$ACTION" == "$GENERATE_COMP_ARTIFACTS" ]]; then
    setupWorkspace
    generateCompArtifacts
  elif [[ "$ACTION" == "$GENERATE_API_ARTIFACTS" ]]; then
    setupApiWorkspace
    generateApiArtifacts
  elif [[ "$ACTION" == "$GENERATE_NOPOLLY_API_ARTIFACTS" ]]; then
    setupNopo11yWorkspace
    generateNopo11yApiArtifacts
  elif [[ "$ACTION" == "$GENERATE_ARAZZO_WORKFLOW_ARTIFACTS" ]]; then
    setupArazzoWorkflowWorkspace
    generateArazzoWorkflowArtifacts
  elif [[ "$ACTION" == "$RUN_API_CTKS_FROM_COMP_ARTIFACTS" ]]; then
    runApiCtksFromCompArtifacts
  else
    show "Action '$ACTION' is not supported." "x"
    exit 1
  fi

  cd "$INITIAL_DIR"
  show "Done performing action '$ACTION'" "/"
}

clear
bootstrap
checkPreReqs
performAction
