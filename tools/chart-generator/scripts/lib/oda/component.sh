

function copyOtherCompArtifactsByEnv() {
  local compId="$1"
  local env="$2"
  local srcCompDir="$3"
  local trgCompDirByEnv="$4"

  show "Copying other artifacts of component '$compId' by env '$env'" "h3"
  mkdir -p $(chartsDirIn $trgCompDirByEnv)
  cp $(chartsFileWithin $srcCompDir) $(chartsFileWithin $trgCompDirByEnv)
  cp $(servicesFileIn $srcCompDir) $(servicesFileIn $trgCompDirByEnv)
}

function configureSpecmaticStubbing() {
  local env="$1"
  local compChartsDirByEnv=$(chartsDirIn "$2")

  show "Configuring specmatic stubbing for component '$compId' by env '$env'" "h3"
  valuesFile=$(valuesFileIn "$compChartsDirByEnv")
  tempFile=$(tempFileIn "$compChartsDirByEnv" "1")

  ymlPath="oda-common.component.specmatic.stub.enabled"
  if [[ "$env" == "$ENV_EAT" ]]; then
    cat "$valuesFile" | yq "$ymlPath=true" > "$tempFile"
  else
    cat "$valuesFile" | yq "$ymlPath=false" > "$tempFile"
  fi
  cp "$tempFile" "$valuesFile"
  rm -f "$tempFile"
  cat "$valuesFile" | grep -A5 "specmatic"
}


function odacVersion() {
  local compSpecInfoFile="$1"
  cat "$compSpecInfoFile" | yq '.version | sub("\.", "")'
}

function prefixAppLabel() {
  local compSpecInfoFile="$1"
  cat "$compSpecInfoFile" | VER="$(odacVersion $compSpecInfoFile)" yq '.k8s.name.full + "-" + strenv(VER)'
}

function prefixImplLabel() {
  local compSpecInfoFile="$1"
  cat "$compSpecInfoFile" | VER="$(odacVersion $compSpecInfoFile)" yq '.k8s.name.short + "-" + strenv(VER)'
}

function mergeApiValueHelms() {
  local env="$1"
  local compDirByEnv="$2"

  compSpecInfoFile=$(compSpecInfoFile "$compDirByEnv")
  compValuesFileByEnv=$(valuesFileIn $(chartsDirIn "$compDirByEnv"))
  compMergedValuesFileByEnv=$(apisNCompMergedValuesFile $(chartsDirIn "$compDirByEnv"))
  apisDirByEnv=$(apisDirIn $(envDirIn $(tempDir) "$env"))
  tempFile=$(tempFileIn $compDirByEnv "1")
  show "Merging all api values.yaml from '$apisDirByEnv' into '$compMergedValuesFileByEnv'" "h3"

  find "$apisDirByEnv" -type f -name 'values.yaml' -print | xargs -I{} yq '. | with_entries(select(.key == "api"))' "{}" | sed 's/^api:.*$/- /g' | APP_LABEL="$(prefixAppLabel $compSpecInfoFile)" IMPL_LABEL="$(prefixImplLabel $compSpecInfoFile)" yq '. | map(. + {"k8s": {"app": (strenv(APP_LABEL) + "-" + (.service.name | downcase)), "impl": (strenv(IMPL_LABEL) + "-" + (.service.name | downcase))}})' > "$tempFile"
  cat "$compValuesFileByEnv" | PFX="$(prefixImplLabel $compSpecInfoFile)" yq 'oda-common.component.apiDeploymentNamePrefix = (strenv(PFX) + "-")' | ODA_FILE_NAME="$tempFile" yq eval 'oda-common.apis *= load(strenv(ODA_FILE_NAME))' > "$compMergedValuesFileByEnv"
  rm -f "$tempFile"
  head -n 15 "$compMergedValuesFileByEnv"
}

function mergeApiNCompSpecInfo() {
  local compDirByEnv="$1"

  apiNCompValuesFileByEnv=$(apisNCompSpecInfoMergedValuesFile $(chartsDirIn "$compDirByEnv"))
  show "Merging the api and component spec file info into '$apiNCompValuesFileByEnv'" "h3"

  cat $(apiSpecInfoFile "$compDirByEnv" "$KEY_EXPOSED") | yq '{"exposed": .}' > $(tempFileIn "$compDirByEnv" "1")
  cat $(apiSpecInfoFile "$compDirByEnv" "$KEY_DEPENDENT") | yq '{"dependent": .}' > $(tempFileIn "$compDirByEnv" "2")
  cat $(tempFileIn "$compDirByEnv" "1") $(tempFileIn "$compDirByEnv" "2") | yq '{"apis": .}' > $(tempFileIn "$compDirByEnv" "3")
  cat $(compSpecInfoFile "$compDirByEnv") $(tempFileIn "$compDirByEnv" "3") | yq '{"genOdaComp": .}' > $(tempFileIn "$compDirByEnv" "4")
  cat $(nopollyInfoFile "$compDirByEnv") | yq '{"nopo11y": .}' > $(tempFileIn "$compDirByEnv" "5")
  cat $(tempFileIn "$compDirByEnv" "4") $(tempFileIn "$compDirByEnv" "5") | yq '{"oda-common": .}' > $(tempFileIn "$compDirByEnv" "6")
  cat $(tempFileIn "$compDirByEnv" "6") | sed 's/swagger/openapi/g' | sed 's/publicationDate:.*/publicationDate: 2023-08-18T00:00:00.000Z/g' > "$apiNCompValuesFileByEnv"

  for i in {1..6}
  do
    rm -f $(tempFileIn "$compDirByEnv" "$i")
  done

  cat "$apiNCompValuesFileByEnv" | head -n 10
}

function generateFinalValueHelm() {
  local compDirByEnv="$1"

  apiNCompMergedValuesFileByEnv=$(apisNCompMergedValuesFile $(chartsDirIn "$compDirByEnv"))
  apiNCompSpecInfoFileByEnv=$(apisNCompSpecInfoMergedValuesFile $(chartsDirIn "$compDirByEnv"))
  compValuesFileByEnv=$(compGeneratedValuesFile $(chartsDirIn "$compDirByEnv"))
  show "Generating final values helm into '$compValuesFileByEnv'" "h3"
  yq eval-all 'select(fi == 0) * select(fi == 1)' "$apiNCompMergedValuesFileByEnv" "$apiNCompSpecInfoFileByEnv" > "$compValuesFileByEnv"

  grep -A10 "component:" "$compValuesFileByEnv"
  grep -A10 "genOdaComp:" "$compValuesFileByEnv"
}

function generateArtifacts() {
  local env="$1"
  local tempCompDirByEnv="$2"
  local outputCompDirByEnv="$3"

  show "Generating artifacts into '$outputCompDirByEnv'" "h3"
  outputChartsDir=$(chartsDirIn "$outputCompDirByEnv")

  mkdir -p $outputChartsDir
  cp $(compGeneratedValuesFile $(chartsDirIn "$tempCompDirByEnv")) "$outputChartsDir"
  cp $(valuesFileIn $(chartsDirIn "$tempCompDirByEnv")) "$outputChartsDir"
  cp $(chartsFileIn $(chartsDirIn "$tempCompDirByEnv")) "$outputChartsDir"
  show "Content of charts in '$outputChartsDir'"
  ls -lah "$outputChartsDir"

  for svcName in $(apiNamesAsSsv)
  do
    srcTemplatesDir=$(templatesDirIn $(apiSvcDirIn $(envDirIn $(tempDir) "$env") "$svcName"))
    trgTemplatesDir=$(createPath $(templatesDirIn "$outputChartsDir") "$svcName")
    copyTemplatesDirIfPresent "$srcTemplatesDir" "$trgTemplatesDir"
    if [[ -d "$srcTemplatesDir" ]]; then
      show "Content of '$svcName' templates in '$trgTemplatesDir'"
      ls -lah "$trgTemplatesDir"
    fi
  done

  if [[ "$env" == "$ENV_EAT" ]]; then
    for apiKind in $(echo -n "$KEY_EXPOSED $KEY_DEPENDENT")
    do
      trgSpecsDir=$(specsDir "$outputCompDirByEnv" "$apiKind")
      srcApiSpecsInfoDir=$(apiSpecInfoDir "$tempCompDirByEnv" "$apiKind")
      srcApiCtkDir=$(ctkInfoDir "$tempCompDirByEnv" "$apiKind")

      mkdir -p "$trgSpecsDir"
      cp -r "$srcApiSpecsInfoDir" "$trgSpecsDir"
      if [[ -d "$srcApiCtkDir" ]]; then
        cp -r "$srcApiCtkDir" "$trgSpecsDir"
      fi
      ls -lah "$trgSpecsDir"
    done
  fi
}

function prepCompArtifactsByEnv() {
  local env="$1"
  show "Prepping provided artifacts (of component) by env '$env'" "h2"

  compArtifactsPath=$(compDirIn $(inputDir))
  compArtifactDirName=$(ls "$compArtifactsPath")

  countOfDirs=$(ls "$compArtifactsPath" | wc -l | xargs)
  if [[ $countOfDirs -ne 1 ]]; then
    show "Zero or multiple component dirs found - '$compArtifactDirName' (total '$countOfDirs'). Exiting..."
    exit 1
  fi

  echo -n "$compArtifactDirName"
  compDirName=$(extractCompProjDirName)
  compId=$(extractCompId)
  srcCompDir=$(compProjDirIn $(inputDir) "$compDirName")
  show "Contents of component '$compId' in '$srcCompDir'"
  ls -lah $srcCompDir

  trgCompDirByEnv=$(compProjDirIn $(envDirIn $(tempDir) "$env") "$compDirName")
  mkdir -p "$trgCompDirByEnv"

  mergeValuesHelm "component '$compId'" "$env" $(chartsDirIn "$srcCompDir") $(chartsDirIn "$trgCompDirByEnv")
  copyOtherCompArtifactsByEnv "$compId" "$env" "$srcCompDir" "$trgCompDirByEnv"

  configureSpecmaticStubbing "$env" "$trgCompDirByEnv"

  specFile=$(compSpecFile "$compId")
  extractCompSpecInfo "$specFile" "$trgCompDirByEnv"
  extractNopollyInfo "$specFile" "$trgCompDirByEnv"

  verifyIfApiDeclarationMatchesSpec "$env" "$trgCompDirByEnv" "$specFile"

  mergeApiValueHelms "$env" "$trgCompDirByEnv"

  extractApiSpecInfo "$env" "$trgCompDirByEnv"
  mergeApiNCompSpecInfo "$trgCompDirByEnv"

  generateFinalValueHelm "$trgCompDirByEnv"
  generateArtifacts "$env" "$trgCompDirByEnv" $(compProjDirIn $(envDirIn $(artifactsDirIn $(outputDir)) "$env") "$compDirName")
}
