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
  show "generateArazzoWorkflowArtifacts" "h2"

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

    if [[ "$RUNTIME_MODE" == "$RUNTIME_MODE_LOCAL" ]]; then
      if [[ -z "$API_ARTIFACTS_PATH" ]]; then
        show "Invalid artifacts file path provided '$API_ARTIFACTS_PATH'" "x"
      fi
      show "Publishing artifact '$zipFile' to '$API_ARTIFACTS_PATH'"

      mkdir -p "$API_ARTIFACTS_PATH"
      mv "$zipFile" "$API_ARTIFACTS_PATH"

      show "Contents of destination '$API_ARTIFACTS_PATH' (after copying artifact)"
      ls -lah "$API_ARTIFACTS_PATH"
    fi
  }

  componentName=$(cat $(metaConfigFileIn $(inputDir)) | yq '.component.name')

  finalizeArtifacts
  publishArtifacts
}