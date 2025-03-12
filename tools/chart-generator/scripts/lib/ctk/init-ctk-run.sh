
function setupCtksWorkspace() {
  local workDir="$(baseWorkDir)"
  show "Setting up workspace under directory - '$workDir'" "h2"
  cleanUpDirs "$workDir $(tempDir) $(artifactsDirIn $(outputDir))"
}

function extractCompIdFromArtifact() {

  countOfFiles=$(ls $valuesFilePath | wc -l | xargs)
  if [[ $countOfFiles -gt 1 ]]; then
    show "More than one values.yaml files found - '$valuesFilePath' (total '$countOfFiles'). Exiting..."
    exit 1
  fi

  cat "$valuesFilePath" | yq 'oda-common.component.id'
}

function determineAppHost() {
  appHost=""
  if [[ ! -z "$(appHost)" ]]; then
    appHost="$(appHost)"
  else
    appHost=$(appHostIpByEnv)
  fi
  echo -n "$appHost"
}

function appServiceUrl() {
  local ctkFile="$1"
  
  urlFile=$(apiCTKServiceUrlFileByCtkFile $ctkFile)
  echo -n "$(appProtocol)://$(determineAppHost)$(cat $urlFile)"
}

function runApiCtksFromCompArtifacts() {
  show "Running CTKs from component artifacts in - '$(compArtifactsPath)'" "h1"
  ls -lah "$(compArtifactsPath)"
  
  setupCtksWorkspace
  
  ctksDir=$(ctkInfoDirWithin $(compDirIn $(envDirIn "$(compArtifactsPath)" "$ENV_EAT")))
  show "Found ctks dir to be - '$ctksDir'"
  ls -lah "$ctksDir"

  for ctkFile in $(ctkZipFilePaths "$ctksDir")
  do
    processCtk "$ctkFile" $(appServiceUrl "$ctkFile")
  done
}