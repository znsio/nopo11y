#!/bin/bash
set -e

readonly INITIAL_DIR=$(pwd)

source ./lib/config.sh
source ./lib/constants.sh
source ./lib/bootstrap.sh

function performAction() {
  local action="$(requestedAction)"
  show "Performing action - '$action'" "h1"

  if [[ "$action" == "$GENERATE_COMP_ARTIFACTS" ]]; then
    setupWorkspace
    generateCompArtifacts
  elif [[ "$action" == "$GENERATE_API_ARTIFACTS" ]]; then
    setupApiWorkspace
    generateApiArtifacts
  elif [[ "$action" == "$GENERATE_NOPOLLY_API_ARTIFACTS" ]]; then
    setupNopo11yWorkspace
    generateNopo11yApiArtifacts
  elif [[ "$action" == "$GENERATE_ARAZZO_WORKFLOW_ARTIFACTS" ]]; then
    setupArazzoWorkflowWorkspace
    generateArazzoWorkflowArtifacts
  elif [[ "$action" == "$RUN_API_CTKS_FROM_COMP_ARTIFACTS" ]]; then
    runApiCtksFromCompArtifacts
  else
    show "Action '$action' is not supported." "x"
    exit 1
  fi

  cd "$INITIAL_DIR"
  show "Done performing action '$action'" "/"
}

clear
bootstrap
checkPreReqs
performAction
