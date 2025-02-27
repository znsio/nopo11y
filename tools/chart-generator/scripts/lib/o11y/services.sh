function setupNopo11yWorkspace() {

  show "Setting up workspace under directory - '$(baseWorkDir)'" "h1"

  function initialiseInputDirs() {
    # trgPath=$(createPath $(inputDir) $(projectChartName "$INPUT_ODAA_PROJECT_PATH"))
    trgPath=$(inputDir)
    show "Copying required source content from '$INPUT_ODAA_PROJECT_PATH' under - '$trgPath'" "h2"

    mkdir -p "$trgPath"
    cp -r $(nopo11yConfigDirIn "$INPUT_ODAA_PROJECT_PATH") "$trgPath"
    copySpecmaticFilesIfPresent "$INPUT_ODAA_PROJECT_PATH" "$trgPath"

    show "Contents of source: '$INPUT_ODAA_PROJECT_PATH'"
    ls -lah "$INPUT_ODAA_PROJECT_PATH"

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
    cat $(nopo11yConfigFileIn $(inputDir) "default") | yq '{"apiVersion": "v2", "name": .api.service.name, "description": .api.service.description, "type": "application", "version": "1.0.0", "appVersion": .api.service.version, "dependencies": [{"name": "meta-chart", "version": "1.0.0", "repository": "https://znsio.github.io/nopo11y"}]}' > "$chartsFile"
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
    
    show "Adding k8s labels to '$valuesFile'"
    shortName=$(cat "$valuesFile" | yq '.meta-chart.api.service.name' | tr '[:upper:]' '[:lower:]' | sed 's/[-_]/ /g' | awk '{for(i=1;i<=NF;i++)printf("%c", substr($i,1,1))}' | xargs)
    cat "$valuesFile" | APP_LABEL="$shortName" IMPL_LABEL="$shortName" yq '.meta-chart.api.k8s = {"app": (strenv(APP_LABEL) + "-app"), "impl": (strenv(IMPL_LABEL) + "-impl")}' > "$valuesFileTemp"
    cp "$valuesFileTemp" "$valuesFile"
    cat "$valuesFile" | grep -A5 'k8s'

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

  tmpChartsDir=$(chartsDirIn $(tempDir))
  chartsFile=$(chartsFileIn $tmpChartsDir)
  generateInitialHelmCharts

  for env in $(echo -n "$ALL_ENVS")
  do
    show "Generating Nopo11y artifacts by env '$env'" "h1"
    generateArtifactsByEnv
    modifyValuesByEnv
    finalizeArtifactsByEnv
  done
}