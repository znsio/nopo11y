
function checkPreReqs() {
  show "Checking Pre reqs" "h1"
  
  show "Checking if required programs are installed" "h2"
  if [[ -z "$(command -v yq)" ]]; then
    show "'yq' is not installed" "x"
    exit 1
  elif [[ -z "$(command -v jq)" ]]; then
    show "'jq' is not installed" "x"
    exit 1
  else
    show "Required programs are installed"
  fi

  show "Displaying version of required applications" "h2"
  show "yq     : $(yq -V)"
  show "jq     : $(jq --version)"
  show "helm   : $(helm version)"
  show "git    : $(git --version)"
  show "node   : $(node --version)"
  show "npm    : $(npm --version)"
  show "newman : $(newman --version)"
  show "curl   : $(curl --version)"
  show "zip    : $(zip -v)"
  show "unzip  : $(unzip -v)"
}

function prepGitRepo() {
  local repoUrl="$1"
  local repoBranch="$2"
  local repoDir="$3"
  local repoCheckoutDirs="$4"

  if [[ "$(specRepoCheckoutMode)" == "doFreshRepoClone" || ! -d "$repoDir" ]]; then
    show "Sparsely checking out '$repoUrl' (branch='$repoBranch', dirs='$repoCheckoutDirs') into '$repoDir'" "h2"

    show "Cloning '$repoUrl' ('$repoBranch')"
    cd $(tmfSpecDir)
    git clone --no-checkout --depth 1 -b $repoBranch $repoUrl $repoDir
    cd $repoDir
    ls -lah

    show "Sparsely checking out '$repoCheckoutDirs'"
    git config core.sparseCheckout true
    echo -n $repoCheckoutDirs | tr "," "\n" | xargs -I{} echo "{}" >> .git/info/sparse-checkout
    git checkout $repoBranch
  else
    show "Using an existing checkout of '$repoUrl' (branch='$repoBranch', dirs='$repoCheckoutDirs')" "h2"
  fi
  ls -lah "$repoDir" | head -n 10
}

function dirsToClean() {
  if [[ "$(requestedAction)" == "$GENERATE_COMP_ARTIFACTS" && ! "$(specRepoCheckoutMode)" == "doFreshRepoClone" ]]; then
      echo -n "$(pathOf 'IP') $(pathOf 'OP') $(pathOf 'TMP')"
  else
    echo -n "$(baseWorkDir)"
  fi
}

function createInitialDirs() {
  show "Creating initial set of directories under '$(baseWorkDir)'"
  mkdir -p $(tmfSpecDir) $(apisDirIn $(inputDir)) $(compDirIn $(inputDir))

  for env in $(echo -n "$(allEnvsAsSsv)")
  do
    mkdir -p $(envDirIn $(tempDir) "$env") $(envDirIn $(artifactsDirIn $(outputDir)) "$env")
  done
  ls -lah $(baseWorkDir)
}

function createApiInitialDirs() {
  show "Creating initial set of directories under '$(baseWorkDir)'"
  mkdir -p $(inputDir)
  for env in $(echo -n "$(allEnvsAsSsv)")
  do
    mkdir -p $(envDirIn $(tempDir) "$env") $(envDirIn $(artifactsDirIn $(outputDir)) "$env")
  done
  ls -lah $(baseWorkDir)
}

function initialiseInputDirs() {
  show "Copying required artifacts under - '$(baseWorkDir)'" "h2"
  show "Contents of source: '$(compCodeCheckoutDir)'"
  ls -lah "$(compCodeCheckoutDir)"
  compDir=$(createPath $(compDirIn $(inputDir)) $(extractCompId))
  mkdir -p "$compDir"
  cp -r "$(compCodeCheckoutDir)/." "$compDir"
  show "Contents of destination: '$compDir'"
  ls -lah "$compDir"

  show "Inupt: '$(apiNamesAsSsv)'"
  apisDir=$(apisDirIn $(inputDir))
  for svcName in $(apiNamesAsSsv)
  do
    zipName="$svcName.zip"
    trgDir=$(createPath "$apisDir" "$svcName")
    trgZipFile="$trgDir/$zipName"
    mkdir -p "$trgDir"

    if [[ "$(runtimeMode)" == "$RUNTIME_MODE_LOCAL" ]]; then
      if [[ -z "$(apiArtifactCopyPath)" ]]; then
        show "Invalid artifacts file path provided '$(apiArtifactCopyPath)'" "x"
      fi
      show "Fetching artifact '$zipFile' to '$(apiArtifactCopyPath)'"
      zipFile=$(createPath "$(apiArtifactCopyPath)" "$zipName")
      cp "$zipFile" "$trgDir"
    elif [[ "$(runtimeMode)" == "$RUNTIME_MODE_PIPELINE" ]]; then
      show "Fetching artifact '$zipName' from '$(apiArtifactRepoUrl)'"
      zipFile=$(createPath "$(apiArtifactCopyPath)" "$zipName")
      curl -k -u "$(apiArtifactRepoCred)" "$(apiArtifactRepoUrl)/$zipName" -o "$trgZipFile"
    else
      show "Runtime mode '$(runtimeMode)' not supported! Exiting..." "x"
      exit 1
    fi

    show "Contents of destination '$trgDir' (after copying artifact)"
    ls -lah "$trgDir"

    show "Unzipping '$trgZipFile'"
    file "$trgZipFile"
    unzip "$trgZipFile" -d "$trgDir"

    show "Contents of destination '$trgDir' (after unzipping artifact)"
    ls -lah "$trgDir"
  done
}

function initialiseApiInputDirs() {
  local repoPath="$(apiProjectPath)"
  # trgPath=$(createPath $(inputDir) $(projectChartName "$repoPath"))
  trgPath=$(inputDir)
  show "Copying required source content from '$repoPath' under - '$trgPath'" "h2"

  mkdir -p "$trgPath"
  cp -r $(chartsDirIn "$repoPath") "$trgPath"
  copySpecmaticFilesIfPresent "$repoPath" "$trgPath"

  show "Contents of source: '$repoPath'"
  ls -lah "$repoPath"

  show "Contents of destination: '"$trgPath"'"
  ls -lah "$trgPath"
  ls -lah "$(chartsDirIn $trgPath)"
}

function initialiseSpecDirs() {
  show "Prepping git client for git operations" "h2"
  configureGitClient

  prepGitRepo "$(compSpecRepoUrl)" "$(compSpecRepoBranch)" $(compDirIn $(tmfSpecDir)) "$(compSpecRepoVersionDir)"
  prepGitRepo "$(apiSpecRepoUrl)" "$(apiSpecRepoBranch)" $(apisDirIn $(tmfSpecDir)) "$(apiSpecRepoSpecDir),$(apiSpecRepoCtkDir)"
}

function setupWorkspace() {
  show "Setting up workspace under directory - '$(baseWorkDir)'" "h1"

  show "Creating/Cleaning required dirs" "h2"
  cleanUpDirs "$(dirsToClean)"

  createInitialDirs
  initialiseInputDirs
  initialiseSpecDirs
}

function setupApiWorkspace() {
  show "Setting up workspace under directory - '$(baseWorkDir)'" "h1"

  show "Creating/Cleaning required dirs" "h2"
  cleanUpDirs "$(dirsToClean)"

  createApiInitialDirs
  initialiseApiInputDirs
}