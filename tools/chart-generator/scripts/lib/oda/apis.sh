
function copySpecmaticYaml() {
  local srcSvcDirByEnv="$1"
  local trgSvcDirByEnv="$2"

  show "Copying Specmatic spec file for api '$svcName' by env '$env'" "h3"
  srcSpecmaticJson=$(specmaticJsonFileIn "$srcSvcDirByEnv")
  srcSpecmaticYaml=$(specmaticYamlFileIn "$srcSvcDirByEnv")
  trgSpecmaticYaml=$(specmaticYamlFileIn "$trgSvcDirByEnv")

  if [[ ! -r $srcSpecmaticJson && ! -r $srcSpecmaticYaml ]]; then
    show "No Specmatic spec file found in '$srcSvcDirByEnv'" "x"
    ls -lah "$srcSvcDirByEnv"
    exit 1
  fi

  if [[ -r "$srcSpecmaticYaml" ]]; then
    cp "$srcSpecmaticYaml" "$trgSpecmaticYaml"
  fi

  if [[ ! -r "$srcSpecmaticYaml" && -r "$srcSpecmaticJson" ]]; then
    show "Found only Specmatic (json) spec file - '$srcSpecmaticJson'. Converting it into Specmatic (yaml) spec file"
    yq -P -oy "$srcSpecmaticJson" > "$trgSpecmaticYaml"
    cat "$trgSpecmaticYaml" | head -n 10
  fi
}

function copyOtherApiArtifactsByEnv() {
  local svcName="$1"
  local env="$2"
  local srcSvcDirByEnv="$3"
  local trgSvcDirByEnv="$4"

  show "Copying other artifacts of api '$svcName' by env '$env'" "h3"
  copyTemplatesDirInIfPresent "$srcSvcDirByEnv" "$trgSvcDirByEnv"
  copySpecmaticYaml "$srcSvcDirByEnv" "$trgSvcDirByEnv"
}

injectNetworkPolicyLabels() {
  local svcName="$1"
  local env="$2"
  local svcDirByEnv="$3"

  local templatesDir=$(templatesDirIn "$svcDirByEnv")
  show "Injecting network policy labels in templates of api '$svcName' by env '$env' in dir '$templatesDir'" "h3"

  countOfFiles=0
  for k8sDeployment in $(find "$templatesDir" -type f -name "*.yaml" -exec grep -l "kind: Deployment" {} \;)
  do
    show "Injecting network policy labels in '$k8sDeployment'"
    show "Before"
    cat $k8sDeployment | yq '.spec.template.metadata.labels' | head -n 5

    yq -i '.spec.template.metadata.labels.component = "{{ include \"oda.compName\" (index .Subcharts \"oda-common\") }}"' $k8sDeployment

    show "After"
    cat $k8sDeployment | yq '.spec.template.metadata.labels' | head -n 5

    countOfFiles++
  done
  show "Injected network polices to '$countOfFiles' files"
}

function injectNecessaryConfigs() {
  local svcName="$1"
  local env="$2"
  local svcDirByEnv="$3"

  specmaticYaml=$(specmaticYamlFileIn "$svcDirByEnv")
  valuesYaml=$(valuesFileIn $svcDirByEnv)
  tempFile=$(tempFileIn $svcDirByEnv "1")

  show "Generating [image-url] config for api '$svcName' by env '$env'" "h3"
  imageUrl=$(cat "$valuesYaml" | yq '.api.service | with_entries(select(.key == "name" or .key == "version" or .key == "spec")) | "your-domain.com/docker-repo/" + .name + "-" + .spec + ":" + .version')
  if [[ -z "$imageUrl" ]]; then
    show "Could not generate image-url for api '$svcName' by env '$env'" "x"
    show "Check api.component.service[name, version, spec] values to be present in values file '$valuesYaml'" "i"
    cat "$valuesYaml" | grep -A 10 'service'
    exit 1
  else
    show "Generated image-url for api '$svcName' by env '$env' is '$imageUrl'"
  fi

  show "Injecting [image url + specmatic, default] configs for api '$svcName' by env '$env'" "h3"
  cat "$valuesYaml" | IMG_URL="$imageUrl" SPECMATIC_FILE_NAME="$specmaticYaml" yq eval '.api.specmatic.config *= load(strenv(SPECMATIC_FILE_NAME)), .api.container.imageGenerated=strenv(IMG_URL)' | yq '.api.container.probes.readiness.enabled=false | .api.container.probes.liveness.enabled=false' > "$tempFile"
  mv "$tempFile" "$valuesYaml"
  rm -f "$tempFile"
  cat "$valuesYaml" | grep -A 10 'specmatic'
}

function extractDeclaredIdsFromSpecmaticConfig() {
  local svcName="$1"
  local env="$2"
  local svcDirByEnv="$3"
  local apiKind="$4"
  local specmaticKey="$5"

  show "Extracting declared $apiKind ids from specmatic spec of api '$svcName'" "h3"
  apiIdsInfoDir=$(apiIdsInfoDirIn $svcDirByEnv $apiKind)
  tempFile=$(tempFileIn $svcDirByEnv "1")
  specmaticYaml=$(specmaticYamlFileIn $svcDirByEnv)
  valuesYaml=$(valuesFileIn $svcDirByEnv)
  service=$(cat "$valuesYaml" | yq ".api.service.name")

  mkdir -p $apiIdsInfoDir
  echo "" > "$tempFile"
  # TODO
  ## `sed` expression below only outputs the last matched TMF id. Not sure if relevant, but if so, change the `sed` expression to have the desired effect.
  tempResult=$(cat "$specmaticYaml" | KEY="$specmaticKey" yq -r eval '.sources[] | with_entries(select(.key == strenv(KEY))) | .[]' | sed -n 's/^.*\(TMF[0-9][0-9][0-9]\).*$/\1/p')
  echo "$tempResult" >> "$tempFile"
  echo "$tempResult" | sed 's/^/- /g' | PROJECT="$svcName" yq eval '{strenv(PROJECT): .}' >> $(declaredIdsFileByDirNameIn $svcDirByEnv $apiKind)
  echo "$tempResult" | sed 's/^/- /g' | SERVICE="$service" yq eval '{strenv(SERVICE): .}' >> $(declaredIdsFileByApiNameIn $svcDirByEnv $apiKind)
  cat "$tempFile" | sort | uniq | tr '\n' ',' | sed 's/^,*//;s/,*$//' >> $(declaredIdsFileIn $svcDirByEnv $apiKind)

  cat $apiIdsInfoDir/*
  rm -f "$tempFile"
}

function prepApiArtifactsByEnv() {
  local svcName="$1"
  local env="$2"
  show "Prepping provided artifacts (of apis) by env '$env'" "h2"

  svcSuffix=$(envDirIn "$svcName" "$env")
  srcSvcDirByEnv=$(apiSvcDirIn $(inputDir) "$svcSuffix")
  show "Contents of api '$svcName'"
  ls -lah $srcSvcDirByEnv

  tempEnvDir=$(envDirIn $(tempDir) "$env")
  trgSvcDirByEnv=$(apiSvcDirIn "$tempEnvDir" "$svcName")
  mkdir -p $trgSvcDirByEnv

  mergeValuesHelm "api '$svcName'" "$env" "$srcSvcDirByEnv" "$trgSvcDirByEnv"
  copyOtherApiArtifactsByEnv "$svcName" "$env" "$srcSvcDirByEnv" "$trgSvcDirByEnv"
  echo ""

  injectNetworkPolicyLabels "$svcName" "$env" "$trgSvcDirByEnv"
  injectNecessaryConfigs "$svcName" "$env" "$trgSvcDirByEnv"

  extractDeclaredIdsFromSpecmaticConfig "$svcName" "$env" "$trgSvcDirByEnv" "$KEY_EXPOSED" "test"
  extractDeclaredIdsFromSpecmaticConfig "$svcName" "$env" "$trgSvcDirByEnv" "$KEY_DEPENDENT" "stub"
}

function prepTempWorkDirByEnv() {
  srcDir="$1"
  trgDirByEnv="$2"

  srcChartsDir=$(chartsDirIn "$srcDir")
  trgChartsDir=$(chartsDirIn "$trgDirByEnv")

  mergeValuesHelm "api" "$env" "$srcChartsDir" "$trgChartsDir"
  cp $(chartsFileIn "$srcChartsDir") $(chartsFileIn "$trgChartsDir")
  copyTemplatesDirInIfPresent "$srcChartsDir" "$trgChartsDir"
  copySpecmaticFilesIfPresent "$srcDir" "$trgDirByEnv"
}

function createHelmTemplatesByEnv() {
  srcDir="$1"
  trgDirByEnv="$2"

  srcChartsDir=$(chartsDirIn "$srcDir")
  trgChartsDir=$(chartsDirIn "$trgDirByEnv")

  templateName=$(helmTemplateName $(projectChartName "$trgDirByEnv"))
  valFile=$(valuesFileIn "$trgChartsDir")
  show "Creating helm templates with name '$templateName' and values '$valFile' in '$trgDirByEnv' by env '$env'" "h3"
  helm template "$trgChartsDir" --output-dir "$trgDirByEnv" -f "$valFile" --name-template "$templateName"

  templatesDir=$(templatesDirIn "$trgChartsDir")
  generatedTemplatesBaseDir=$(createPath "$trgDirByEnv" $(projectChartName "$trgDirByEnv"))
  generatedTemplatesDir=$(lastTemplatesDirWithin $generatedTemplatesBaseDir)
  show "Shifting templates from '$generatedTemplatesDir' to '$templatesDir'"

  if [[ -d "$templatesDir" ]]; then
    show "Removing existing contents of '$templatesDir'"
    ls -lah "$templatesDir"
    rm -rf "$templatesDir"
  fi

  if [[ -d "$generatedTemplatesBaseDir" ]]; then
    show "Copying '$generatedTemplatesDir' into '$templatesDir'"
    cp -r "$generatedTemplatesDir" "$templatesDir"
    rm -rf "$generatedTemplatesBaseDir"
    ls -lah "$templatesDir"
  fi
}

function createArtifactsByEnv() {
  local contentDirByEnv="$1"
  local artifactsDirByEnv="$2"

  show "Creating artifact content from source in '$contentDirByEnv' into '$artifactsDirByEnv'" "h3"
  copySpecmaticFilesIfPresent "$contentDirByEnv" "$artifactsDirByEnv"
  cp $(valuesFileWithin "$contentDirByEnv") "$artifactsDirByEnv"

  if [[ -d $(templatesDirWithin "$contentDirByEnv") ]]; then
    cp -r $(templatesDirWithin "$contentDirByEnv") "$artifactsDirByEnv"
  fi

  show "Contents of artifact '$artifactsDirByEnv'"
  ls -lah "$artifactsDirByEnv"
}

function prepApiArtifactsByEnv2() {
  local env="$1"
  show "Prepping provided artifacts (of apis) by env '$env'" "h2"

  srcDir=$(inputDir)
  show "Contents of api '$(inputDir)'"
  ls -lah $srcDir

  trgDirByEnv=$(envDirIn $(tempDir) "$env")
  mkdir -p "$trgDirByEnv"

  prepTempWorkDirByEnv "$srcDir" "$trgDirByEnv"
  createHelmTemplatesByEnv "$srcDir" "$trgDirByEnv"
  createArtifactsByEnv "$trgDirByEnv" $(envDirIn $(artifactsDirIn $(outputDir)) "$env")
}

function publishArtifacts() {
  local zipName="$(projectChartName $(inputDir)).zip"
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
    cp "$zipFile" "$(apiArtifactCopyPath)"

    show "Contents of destination '$(apiArtifactCopyPath)' (after copying artifact)"
    ls -lah "$(apiArtifactCopyPath)"

  elif [[ "$(runtimeMode)" == "$RUNTIME_MODE_PIPELINE" ]]; then
    show "Publishing artifact '$zipFile' to '$API_ARTIFACT_REPO_URL'"
    curl -k -i -X PUT -T "$zipFile" -u "$API_ARTIFACT_REPO_CRED" "$API_ARTIFACT_REPO_URL/$zipName"
  else
    show "Runtime mode '$(runtimeMode)' not supported! Exiting..." "x"
    exit 1
  fi
}