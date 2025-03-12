
readonly CONFIG_PATH="./config"
readonly CONFIG=$(cat $CONFIG_PATH/settings.yaml)
readonly ENV_VAR_NAME_KEY="envVar"
readonly DEFAULT_VAL_KEY="default"

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
  envVar=$(configuredValOf "$path.$ENV_VAR_NAME_KEY")
  echo -n ${!envVar}
}

function envValOfOrDefault() {
  local path="$1"
  local defaultVal="$2"
  envValOrDefault $(configuredValOf "$path") "$defaultVal"
}

function envOrConfiguredValOf() {
  local basePath="$1"
  envValOrDefault $(configuredValOf "$basePath.$ENV_VAR_NAME_KEY") $(configuredValOf "$basePath.$DEFAULT_VAL_KEY")
}

function runtimeMode() {
  envOrConfiguredValOf "action.common.runtime.mode"
}

function runtimeHost() {
  envOrConfiguredValOf "action.common.runtime.host"
}

function allEnvsAsSsv() {
  configuredValOf "action.common.deploymentEnvs" | yq '. | @csv' | tr ',' ' '
}

function compSpecRepoUrl() {
  configuredValOf "action.compBuild.spec.repo.odac.url"
}

function compSpecRepoBranch() {
  configuredValOf "action.compBuild.spec.repo.odac.branch"
}

function compSpecRepoVersionDir() {
  configuredValOf "action.compBuild.spec.repo.odac.version"
}

function apiSpecRepoUrl() {
  configuredValOf "action.compBuild.spec.repo.odaa.url"
}

function apiSpecRepoBranch() {
  configuredValOf "action.compBuild.spec.repo.odaa.branch"
}

function apiSpecRepoSpecDir() {
  configuredValOf "action.compBuild.spec.repo.odaa.specBaseDir"
}

function apiSpecRepoCtkDir() {
  configuredValOf "action.compBuild.spec.repo.odaa.ctkBaseDir"
}

function specRepoCheckoutMode() {
  envOrConfiguredValOf "action.compBuild.spec.repoSettings.checkout.mode"
}

function specRepoAdoAuth() {
  envValOf "action.compBuild.spec.repoSettings.connection.ado.auth"
}

function specRepoLocalAuth() {
  envValOf "action.compBuild.spec.repoSettings.connection.local.auth"
}

function specRepoProxy() {
  configuredValOf "action.compBuild.spec.repoSettings.connection.ado.proxy"
}

function compCodeCheckoutDir() {
  envValOf "action.compBuild.input.codebase"
}

function workDir() {
  envValOf "action.common.workDir"
}

function requestedAction() {
  envValOf "action.common.command"
}

function apiProjectPath() {
  envValOf "action.apiBuild.input.codebase"
}

function apiArtifactCopyPath() {
  envValOf "action.apiBuild.output.artifact.fileSystem"
}

function apiArtifactRepoUrl() {
  configuredValOf "action.apiBuild.output.artifact.artifactory.url"
}

function apiArtifactRepoCred() {
  configuredValOf "action.apiBuild.output.artifact.artifactory.cred"
}

function onSpecMismatchForApi() {
  local apiKind="$1"
  envOrConfiguredValOf "action.compBuild.spec.verification.mismatchActionForApiType.$apiKind"
}

function compArtifactsPath() {
  envValOf "action.apiCtks.input.compArtifactsPath"
}

function onCtkFailure() {
  envOrConfiguredValOf "action.apiCtks.input.onCtkFailure"
}

function appHost() {
  envValOf "action.apiCtks.input.app.host"
}

function appProtocol() {
  envOrConfiguredValOf "action.apiCtks.input.app.protocol"
}

function appEnv() {
  envOrConfiguredValOf "action.apiCtks.input.app.env"
}

function appHostIpByEnv() {
  local env=$(appEnv)
  configuredValOf "action.apiCtks.input.app.hostInfoByEnv.$env.ip"
}

function appHostNameByEnv() {
  local env=$(appEnv)
  configuredValOf "action.apiCtks.input.app.hostInfoByEnv.$env.name"
}

function appImageName() {
  envValOf "action.nopo11yApiBuild.input.appImage.name"
}

function appImageTag() {
  envValOf "action.nopo11yApiBuild.input.appImage.tag"
}

function appImageRepo() {
  envValOf "action.nopo11yApiBuild.input.appImage.repo"
}

function nopo11yHelmName() {
  envOrConfiguredValOf "action.nopo11yApiBuild.input.nopo11yHelm.name"
}

function nopo11yHelmVersion() {
  envOrConfiguredValOf "action.nopo11yApiBuild.input.nopo11yHelm.version"
}

function nopo11yHelmRepo() {
  envOrConfiguredValOf "action.nopo11yApiBuild.input.nopo11yHelm.repo"
}
