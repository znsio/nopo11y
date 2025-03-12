
readonly CONFIG_PATH="./config"
readonly CONFIG=$(cat $CONFIG_PATH/settings.yaml)

function readFromConfig() {
  local funcName="$1"
  local funcParams="${@:2}"
  local keyEnvVar="envVar"
  local keyDefault="default"

  function envValOrDefault() {
    local envVar="$1"
    local defaultVal="$2"

    envVarVal=${!envVar}
    if [[ ! -z "$envVarVal" ]]; then
      echo -n "$envVarVal"
    else
      echo -n "$defaultVal"
    fi
  }

  function configuredValOf() {
    local path="$1"
    echo "$CONFIG" | yq ".$path"
  }

  function envValOf() {
    local path="$1"
    envVar=$(configuredValOf "$path.$keyEnvVar")
    echo -n ${!envVar}
  }

  function envValOfOrDefault() {
    local path="$1"
    local defaultVal="$2"
    envValOrDefault $(configuredValOf "$path") "$defaultVal"
  }

  function envOrConfiguredValOf() {
    local basePath="$1"
    envValOrDefault $(configuredValOf "$basePath.$keyEnvVar") $(configuredValOf "$basePath.$keyDefault")
  }

  $funcName ${funcParams[@]}
}

function runtimeMode() {
  readFromConfig "envOrConfiguredValOf" "action.common.runtime.mode"
}

function runtimeHost() {
  readFromConfig "envOrConfiguredValOf" "action.common.runtime.host"
}

function allEnvsAsSsv() {
  readFromConfig "configuredValOf" "action.common.deploymentEnvs" | yq '. | @csv' | tr ',' ' '
}

function compSpecRepoUrl() {
  readFromConfig "configuredValOf" "action.compBuild.spec.repo.odac.url"
}

function compSpecRepoBranch() {
  readFromConfig "configuredValOf" "action.compBuild.spec.repo.odac.branch"
}

function compSpecRepoVersionDir() {
  readFromConfig "configuredValOf" "action.compBuild.spec.repo.odac.version"
}

function apiSpecRepoUrl() {
  readFromConfig "configuredValOf" "action.compBuild.spec.repo.odaa.url"
}

function apiSpecRepoBranch() {
  readFromConfig "configuredValOf" "action.compBuild.spec.repo.odaa.branch"
}

function apiSpecRepoSpecDir() {
  readFromConfig "configuredValOf" "action.compBuild.spec.repo.odaa.specBaseDir"
}

function apiSpecRepoCtkDir() {
  readFromConfig "configuredValOf" "action.compBuild.spec.repo.odaa.ctkBaseDir"
}

function specRepoCheckoutMode() {
  readFromConfig "envOrConfiguredValOf" "action.compBuild.spec.repoSettings.checkout.mode"
}

function specRepoAdoAuth() {
  readFromConfig "envValOf" "action.compBuild.spec.repoSettings.connection.ado.auth"
}

function specRepoLocalAuth() {
  readFromConfig "envValOf" "action.compBuild.spec.repoSettings.connection.local.auth"
}

function specRepoProxy() {
  readFromConfig "configuredValOf" "action.compBuild.spec.repoSettings.connection.ado.proxy"
}

function compCodeCheckoutDir() {
  readFromConfig "envValOf" "action.compBuild.input.codebase"
}

function workDir() {
  readFromConfig "envValOf" "action.common.workDir"
}

function requestedAction() {
  readFromConfig "envValOf" "action.common.command"
}

function apiProjectPath() {
  readFromConfig "envValOf" "action.apiBuild.input.codebase"
}

function apiArtifactCopyPath() {
  readFromConfig "envValOf" "action.apiBuild.output.artifact.fileSystem"
}

function apiArtifactRepoUrl() {
  readFromConfig "configuredValOf" "action.apiBuild.output.artifact.artifactory.url"
}

function apiArtifactRepoCred() {
  readFromConfig "configuredValOf" "action.apiBuild.output.artifact.artifactory.cred"
}

function onSpecMismatchForApi() {
  local apiKind="$1"
  readFromConfig "envOrConfiguredValOf" "action.compBuild.spec.verification.mismatchActionForApiType.$apiKind"
}

function compArtifactsPath() {
  readFromConfig "envValOf" "action.apiCtks.input.compArtifactsPath"
}

function onCtkFailure() {
  readFromConfig "envOrConfiguredValOf" "action.apiCtks.input.onCtkFailure"
}

function appHost() {
  readFromConfig "envValOf" "action.apiCtks.input.app.host"
}

function appProtocol() {
  readFromConfig "envOrConfiguredValOf" "action.apiCtks.input.app.protocol"
}

function appEnv() {
  readFromConfig "envOrConfiguredValOf" "action.apiCtks.input.app.env"
}

function appHostIpByEnv() {
  local env=$(appEnv)
  readFromConfig "configuredValOf" "action.apiCtks.input.app.hostInfoByEnv.$env.ip"
}

function appHostNameByEnv() {
  local env=$(appEnv)
  readFromConfig "configuredValOf" "action.apiCtks.input.app.hostInfoByEnv.$env.name"
}

function appImageName() {
  readFromConfig "envValOf" "action.nopo11yApiBuild.input.appImage.name"
}

function appImageTag() {
  readFromConfig "envValOf" "action.nopo11yApiBuild.input.appImage.tag"
}

function appImageRepo() {
  readFromConfig "envValOf" "action.nopo11yApiBuild.input.appImage.repo"
}

function nopo11yHelmName() {
  readFromConfig "envOrConfiguredValOf" "action.nopo11yApiBuild.input.nopo11yHelm.name"
}

function nopo11yHelmVersion() {
  readFromConfig "envOrConfiguredValOf" "action.nopo11yApiBuild.input.nopo11yHelm.version"
}

function nopo11yHelmRepo() {
  readFromConfig "envOrConfiguredValOf" "action.nopo11yApiBuild.input.nopo11yHelm.repo"
}
