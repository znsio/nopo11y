function setupArazzoWorkflowWorkspace() {

  show "Setting up workspace under directory - '$(baseWorkDir)'" "h1"

  function createInitialDirs() {
    show "Creating initial set of directories under '$(baseWorkDir)'"
    mkdir -p $(tempDir) $(inputDir) $(artifactsDirIn $(outputDir))
    ls -lah $(baseWorkDir)
  }

  function initialiseInputDirs() {
    trgPath=$(inputDir)
    show "Copying required source content from '$INPUT_ODAC' under - '$trgPath'" "h2"

    mkdir -p "$trgPath"
    cp -r $(arazzoConfigDirIn "$INPUT_ODAC") "$trgPath"
    copySpecmaticFilesIfPresent "$INPUT_ODAC" "$trgPath"
    cp $(metaConfigFileIn "$INPUT_ODAC") $(metaConfigFileIn $trgPath)

    show "Contents of source: '$INPUT_ODAC'"
    ls -lah "$INPUT_ODAC"

    show "Contents of destination: '"$trgPath"'"
    ls -lah "$trgPath"
    ls -lah "$(arazzoConfigDirIn $trgPath)"
  }

  show "Creating/Cleaning required dirs" "h2"
  cleanUpDirs "$(dirsToClean)"

  createInitialDirs
  initialiseInputDirs
}

function generateArazzoWorkflowArtifacts() {

  function finalizeArtifacts() {
    show "Finalizing artifact (of component)" "h2"

    srcDir=$(inputDir)
    trgDir=$(artifactsDirIn $(outputDir))

    cp -r "$srcDir/." $trgDir
    ls -lah $trgDir
  }

  function publishArtifacts() {
    local zipName="$componentName.zip"
    local artifactsDir=$(artifactsDirIn $(outputDir))
    local zipFile=$(createPath "$artifactsDir" "$zipName")

    show "Creating artifact '$zipName' in '$artifactsDir'" "h2"
    currentDir=($pwd)
    cd "$artifactsDir" && zip -r "$zipFile" . && cd "$currentDir"
    unzip -l "$zipFile"

    if [[ "$(runtimeMode)" == "$RUNTIME_MODE_LOCAL" ]]; then
      if [[ -z "$(apiArtifactCopyPath)" ]]; then
        show "Invalid artifacts file path provided '$(apiArtifactCopyPath)'" "x"
      fi
      show "Publishing artifact '$zipFile' to '$(apiArtifactCopyPath)'"

      mkdir -p "$(apiArtifactCopyPath)"
      mv "$zipFile" "$(apiArtifactCopyPath)"

      show "Contents of destination '$(apiArtifactCopyPath)' (after copying artifact)"
      ls -lah "$(apiArtifactCopyPath)"
    fi
  }

  function displayReleaseInfo() {
    local zipName="$componentName.zip"

    if [[ "$(runtimeMode)" == "$RUNTIME_MODE_LOCAL" ]]; then
      zipFile=$(createPath "$(apiArtifactCopyPath)" "$zipName")
      trgDirName=$(basename "$zipFile" ".zip")
      trgDir="$(apiArtifactCopyPath)/$trgDirName"

      show "Unzipping artifact '$zipName' in '$trgDir'" "h2"
      if [[ -z "$(apiArtifactCopyPath)" ]]; then
        show "Invalid artifacts file path provided '$(apiArtifactCopyPath)'" "x"
      fi

      show "Unzipping artifact '$zipFile' into '$trgDir'"
      mkdir -p "$trgDir" && rm -rf "$trgDir" && mkdir -p "$trgDir"
      unzip "$zipFile" -d "$trgDir"

      show "Contents of destination '$trgDir' (after unzipping artifact)"
      ls -lah "$trgDir"

      show "API artifacts to download"
      metaCnfigFile=$(metaConfigFileIn "$trgDir")
      cat $metaCnfigFile | yq '.apis[] | "\(.name).zip"'

      show "Arazzo command to use"
      metaCnfigFile=$(metaConfigFileIn "$trgDir")
      params=$(cat $metaCnfigFile | yq '.apis[] | "--serverUrlIndex=\(.arazzoSpecName):\(.server.urlIndexInSpec)"' | tr '\n' ' ')
      echo "specmatic-arazzo test $params"
    fi
  }

  componentName=$(cat $(metaConfigFileIn $(inputDir)) | yq '.component.name')

  finalizeArtifacts
  publishArtifacts
  displayReleaseInfo
}