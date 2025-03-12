function setupNopo11yWorkspace() {

  show "Setting up workspace under directory - '$(baseWorkDir)'" "h1"

  function initialiseInputDirs() {
    local repoPath="$(apiProjectPath)"
    # trgPath=$(createPath $(inputDir) $(projectChartName "$repoPath"))
    trgPath=$(inputDir)
    show "Copying required source content from '$repoPath' under - '$trgPath'" "h2"

    mkdir -p "$trgPath"
    cp -r $(nopo11yConfigDirIn "$repoPath") "$trgPath"
    copySpecmaticFilesIfPresent "$repoPath" "$trgPath"

    show "Contents of source: '$repoPath'"
    ls -lah "$repoPath"

    show "Contents of destination: '"$trgPath"'"
    ls -lah "$trgPath"
    ls -lah "$(nopo11yConfigDirIn $trgPath)"
  }

  show "Creating/Cleaning required dirs" "h2"
  cleanUpDirs "$(dirsToClean)"

  createApiInitialDirs
  initialiseInputDirs
}

function generateNopo11yApiArtifacts() {

  function generateInitialHelmCharts() {
    show "Generating initial helm charts based on provided meta-chart config" "h2"
    
    show "Creating Chart.yaml '$chartsFile'" "h3"
    mkdir -p "$tmpChartsDir"
    cat $(nopo11yConfigFileIn $(inputDir) "default") | NAME="$(nopo11yHelmName)" VER="$(nopo11yHelmVersion)" REPO="$(nopo11yHelmRepo)" yq '{"apiVersion": "v2", "name": .api.service.name, "description": .api.service.description, "type": "application", "version": "1.0.0", "appVersion": .api.service.version, "dependencies": [{"name": strenv(NAME), "version": strenv(VER), "repository": strenv(REPO)}]}' > "$chartsFile"
    cat "$chartsFile"

    show "Creating default and env wise values.yaml" "h3"
    show "Creating default values.yaml"
    cat $(nopo11yConfigFileIn $(inputDir) "default") | yq '{"meta-chart": .}' > $(valuesFileIn $tmpChartsDir)
    for env in $(echo -n "$ALL_ENVS")
    do
      srcFile=$(nopo11yConfigFileIn $(inputDir) "$env")
      if [[ -r "$srcFile" ]]; then
        show "Creating values.yaml for env '$env'"
        cat "$srcFile" | yq '{"meta-chart": .}' > $(valuesFileIn $tmpChartsDir "$env")
      else
        show "Skipping values.yaml for env '$env' as it does not exist"
      fi
    done
    ls -lah $tmpChartsDir
  }

  function generateArtifactsByEnv() {
    show "Prepping artifact (of service) by env '$env'" "h2"

    srcDir=$(inputDir)
    show "Contents of api '$(inputDir)'"
    ls -lah $srcDir

    trgDirByEnv=$(envDirIn $(tempDir) "$env")
    mkdir -p "$trgDirByEnv"
    
    trgChartsDir=$(chartsDirIn "$trgDirByEnv")
    mergeValuesHelm "api" "$env" "$tmpChartsDir" "$trgChartsDir"
    cp $(chartsFileIn "$tmpChartsDir") $(chartsFileIn "$trgChartsDir")
    copySpecmaticFilesIfPresent "$srcDir" "$trgDirByEnv"
  }

  function modifyValuesByEnv() {
    show "Modifying values (of service) by env '$env'" "h2"

    srcDirByEnv=$(envDirIn $(tempDir) "$env")
    valuesFile=$(valuesFileWithin "$srcDirByEnv")
    valuesFileTemp="$valuesFile.tmp"
    
    show "Adding initial k8s name tags to '$valuesFile'"
    cat "$valuesFile" | SHORT_TAG="$(shortenedTag $serviceName)" READABLE_TAG="$(readableTag $serviceName)" yq '.meta-chart.api.service.nameGenerated = {"short": strenv(SHORT_TAG), "readable": strenv(READABLE_TAG)}' > "$valuesFileTemp"
    cp "$valuesFileTemp" "$valuesFile"
    cat "$valuesFile" | grep -A5 'nameGenerated'

    show "Adding generated image name to '$valuesFile'"
    imgName=$(nonBlankValOrDefault "$(appImageName)" "$serviceName")
    imgTag=$(nonBlankValOrDefault "$(appImageTag)" "$serviceVer")
    cat "$valuesFile" | IMG_URL=$(dockerImageUrl "$imgName" "$imgTag" "$(appImageRepo)") yq '.meta-chart.api.container.imageGenerated = strenv(IMG_URL)' > "$valuesFileTemp"
    cp "$valuesFileTemp" "$valuesFile"
    cat "$valuesFile" | grep -A1 'imageGenerated'

    show "Adding specmatic config to '$valuesFile'"
    cat "$valuesFile" | SPECMATIC_FILE_NAME=$(specmaticYamlFileIn $srcDirByEnv) yq eval '.meta-chart.api.specmatic.config *= load(strenv(SPECMATIC_FILE_NAME))' > "$valuesFileTemp"
    cp "$valuesFileTemp" "$valuesFile"
    cat "$valuesFile" | grep -A5 'specmatic'
  }

  function finalizeArtifactsByEnv() {
    show "Finalizing artifact (of service) by env '$env'" "h2"

    srcDirByEnv=$(envDirIn $(tempDir) "$env")
    trgDirByEnv=$(envDirIn $(artifactsDirIn $(outputDir)) "$env")

    mkdir -p $(chartsDirIn "$trgDirByEnv")
    cp $(chartsFileWithin "$srcDirByEnv") $(chartsFileWithin "$trgDirByEnv")
    cp $(valuesFileWithin "$srcDirByEnv") $(valuesFileWithin "$trgDirByEnv")
    copySpecmaticFilesIfPresent "$srcDirByEnv" "$trgDirByEnv"
    ls -lah "$trgDirByEnv"
    ls -lah $(chartsDirIn $trgDirByEnv)
  }

  function publishArtifacts() {
    local zipName="$serviceName.zip"
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

  tmpChartsDir=$(chartsDirIn $(tempDir))
  chartsFile=$(chartsFileIn $tmpChartsDir)
  serviceName=$(cat $(nopo11yConfigFileIn $(inputDir) "default") | yq '.api.service.name')
  serviceVer=$(cat $(nopo11yConfigFileIn $(inputDir) "default") | yq '.api.service.version')
  generateInitialHelmCharts

  for env in $(echo -n "$ALL_ENVS")
  do
    show "Generating Nopo11y artifacts by env '$env'" "h1"
    generateArtifactsByEnv
    modifyValuesByEnv
    finalizeArtifactsByEnv
  done

  publishArtifacts
}