
function createPath() {
  local prefix="$1"
  local infix="$2"
  local suffix="$3"

  if [[ -z "$suffix" ]]; then
    echo -n "$prefix/$infix"
  else
    echo -n "$prefix/$infix/$suffix"
  fi
}

function baseWorkDir() {
  local action="$(requestedAction)"
  if [[ "$action" == "$GENERATE_COMP_ARTIFACTS" ]]; then
    echo -n "$WORKDIR/$WORKDIR_SUfFIX_CA"
  elif [[ "$action" == "$GENERATE_API_ARTIFACTS" ]]; then
    echo -n "$WORKDIR/$WORKDIR_SUfFIX_AA"
  elif [[ "$action" == "$GENERATE_NOPOLLY_API_ARTIFACTS" ]]; then
    echo -n "$WORKDIR/$WORKDIR_SUfFIX_NAA"
  elif [[ "$action" == "$GENERATE_ARAZZO_WORKFLOW_ARTIFACTS" ]]; then
    echo -n "$WORKDIR/$WORKDIR_SUfFIX_AZW"
  elif [[ "$action" == "$RUN_API_CTKS_FROM_COMP_ARTIFACTS" ]]; then
    echo -n "$WORKDIR/$WORKDIR_SUfFIX_CR"
  else
    show "Action '$action' not supported for building work dir paths" "x"
  fi
}

function pathOf() {
  local key="$1"
  local suffix=""
  
  if [[ "$key" == "IP" ]]; then
    suffix="input"
  elif [[ "$key" == "OP" ]]; then
    suffix="output"
  elif [[ "$key" == "SP" ]]; then
    suffix="tmf-specs"
  elif [[ "$key" == "TMP" ]]; then
    suffix="temp"
  else
    show "path for key '$key' not set!" "x"
    exit 1
  fi
  echo -n "$(baseWorkDir)/$suffix"
}

function tmfSpecDir() {
  pathOf "SP"
}

function inputDir() {
  pathOf "IP"
}

function outputDir() {
  pathOf "OP"
}

function tempDir() {
  pathOf "TMP"
}

function artifactsDirIn() {
  local prefix="$1"
  createPath $prefix "artifacts"
}

function apisDirIn() {
  local prefix="$1"
  createPath $prefix "apis"
}

function apiSvcDirIn() {
  local prefix="$1"
  local svcAsSuffix="$2"
  createPath $prefix "apis" $svcAsSuffix
}

function compDirIn() {
  local prefix="$1"
  local compIdAsSuffix="$2"
  createPath $prefix "component" "$compIdAsSuffix"
}

function compProjDirIn() {
  local prefix="$1"
  local compProjDirName="$2"
  compDirIn "$prefix" "$compProjDirName"
}

function compChartsDirIn() {
  local prefix="$1"
  local compProjDirName="$2"
  createPath $(compProjDirIn $prefix $compProjDirName) "charts"
}

function chartsDirIn() {
  local prefix="$1"
  createPath $prefix "charts"
}

function chartsFileIn() {
  local prefix="$1"
  createPath $prefix "Chart.yaml"
}

function chartsFileWithin() {
  local prefix="$1"
  chartsFileIn $(chartsDirIn $prefix)
}

function servicesFileIn() {
  local prefix="$1"
  createPath $prefix "services.yaml"
}

function envDirIn() {
  local prefix="$1"
  local env="$2"
  createPath $prefix "env" "$env"
}

function templatesDirIn() {
  local prefix="$1"
  createPath $prefix "templates"
}

function templatesDirWithin() {
  local basePath="$1"
  templatesDirIn $(chartsDirIn "$basePath")
}

function lastTemplatesDirWithin() {
  local basePath="$1"
  find $basePath -type d -name "templates" | tail -n 1
}

function specmaticJsonFileIn() {
  local prefix="$1"
  createPath $prefix "specmatic.json"
}

function specmaticYamlFileIn() {
  local prefix="$1"
  createPath $prefix "specmatic.yaml"
}

function valuesFileIn() {
  local prefix="$1"
  local qualifier="$2"

  if [[ -z "$qualifier" ]]; then
    suffix=""
  else
    suffix="-$qualifier"
  fi
  createPath $prefix "values$suffix.yaml"
}

function valuesFileWithin() {
  local basePath="$1"
  local qualifier="$2"

  valuesFileIn $(chartsDirIn "$basePath") "$qualifier"
}

function findValuesFileWithin() {
  local basePath="$1"
  local qualifier="$2"

  if [[ -z "$qualifier" ]]; then
    suffix=""
  else
    suffix="-$qualifier"
  fi
  find "$basePath" -type f -name "values$suffix.yaml" -print
}

function apiIdsInfoDirIn() {
  local prefix="$1"
  local apiKind="$2"
  createPath $prefix $apiKind
}

function declaredIdsFileIn() {
  local prefix="$1"
  local apiKind="$2"
  createPath $(apiIdsInfoDirIn $prefix $apiKind) "$KEY_DECLARED-ids.csv"
}

function requiredIdsFileIn() {
  local prefix="$1"
  local apiKind="$2"
  createPath $(apiIdsInfoDirIn $prefix $apiKind) "$KEY_REQUIRED-ids.csv"
}

function declaredIdsFileByDirNameIn() {
  local prefix="$1"
  local apiKind="$2"
  createPath $(apiIdsInfoDirIn $prefix $apiKind) "$KEY_DECLARED-ids-by-dir-name.yaml"
}

function declaredIdsFileByApiNameIn() {
  local prefix="$1"
  local apiKind="$2"
  createPath $(apiIdsInfoDirIn $prefix $apiKind) "$KEY_DECLARED-ids-by-api-name.yaml"
}

function tempFileIn() {
  local prefix="$1"
  local tempFileName="$2"
  createPath $prefix $tempFileName
}

function compSpecFile() {
  local compId="$1"

  local compSpecDir=$(compDirIn "$(tmfSpecDir)" "$ODAC_SPEC_VER")
  local specFile=$(find "$compSpecDir" -type f -name '*.yaml' -print | grep "$compId")
  if [[ -z $specFile ]]; then
    show "No ODA Component spec file found for - '$compId'." "x"
    exit 1
  fi
  echo -n "$specFile"
}

function apiSpecFile() {
  local apiId="$1"
  local version="$2"

  local specDir=$(apisDirIn "$(tmfSpecDir)" "$ODAA_SPEC_DIR_NAME")
  specFile=$(find "$specDir" -type f -name "${apiId}_$version*.json" -print)
  if [[ -z "$specFile" ]]; then
    show "No ODA API spec found for '$apiId' version '$version'" "x"
    exit 1
  fi
  echo -n "$specFile"
}

function apiCTKFile() {
  local apiId="$1"
  local version=$(echo "$2" | sed 's/v//g')

  local specDir=$(apisDirIn "$(tmfSpecDir)" "$ODAA_CTK_SPEC_DIR_NAME")
  ctkFile=$(find "$specDir" -type f -name "${apiId}*.zip" -print | grep -i "/ctk" | grep "/$version")
  if [[ -z "$ctkFile" ]]; then
    show "No ODA API CTK zip found for '$apiId' version '$version'" "x"
    exit 1
  fi
  echo -n "$ctkFile"
}

function apiCTKServiceUrlFile() {
  local prefix="$1"
  local ctkFile="$2"

  createPath $prefix "$(basename $ctkFile '.zip').url.txt"
}

function compSpecInfoFile() {
  local prefix="$1"
  createPath $prefix "comp-spec-info.yaml"
}

function nopollyInfoFile() {
  local prefix="$1"
  createPath $prefix "nopolly-info.yaml"
}

function apisNCompMergedValuesFile() {
  local prefix="$1"
  createPath $prefix "values-with-all-api-values.yaml"
}

function apisNCompSpecInfoMergedValuesFile() {
  local prefix="$1"
  createPath $prefix "values-with-all-api-spec-info.yaml"
}

function compGeneratedValuesFile() {
  local prefix="$1"
  createPath $prefix "values-generated.yaml"
}

function apiSpecInfoDir() {
  local prefix="$1"
  local apiKind="$2"

  createPath $prefix "$apiKind" "api-specs"
}

function ctkInfoDir() {
  local prefix="$1"
  local apiKind="$2"

  createPath $prefix "$apiKind" "ctks"
}

function ctkInfoDirWithin() {
  local basePath="$1"
  find "$basePath" -type d -name "ctks" -print | tail -n 1
}

function apiSpecInfoFile() {
  local prefix="$1"
  local apiKind="$2"
  createPath $prefix "$apiKind" "apis-spec-info.yaml"
}

function specsDir() {
  local prefix="$1"
  local apiKind="$2"

  createPath $prefix "specs" "$apiKind"
}

function ctkZipFilePaths() {
  local basePath="$1"
  find "$basePath" -type f -name "*.zip" -print
}

function ctkZipFileName() {
  local ctkFilePath="$1"
  basename $ctkFilePath ".zip"
}

function ctkUnzipDir() {
  local unzippedCtkBasePath="$1"
  extractedDirName=$(ls $unzippedCtkBasePath | sed 's/\///g')
  echo -n "$unzippedCtkBasePath/$extractedDirName"
}

function ctkZipDirPath() {
  local ctkFilePath="$1"
  dirname "$ctkFilePath"
}

function apiCTKServiceUrlFileByCtkFile() {
  local ctkFilePath="$1"
  echo -n "$(ctkZipDirPath $ctkFilePath)/$(ctkZipFileName $ctkFilePath).url.txt"
}

function ctkConfigFile() {
  local unzippedCtkBasePath="$1"
  echo -n "$(ctkUnzipDir $unzippedCtkBasePath)/config.json"
}

function ctkTempConfigFile() {
  local unzippedCtkBasePath="$1"
  echo -n "$(ctkUnzipDir $unzippedCtkBasePath)/tmp-config.json"
}

function jsonCtkResultsFile() {
  local prefix="$1"
  createPath "$prefix" "$CTK_RESULTS_JSON_FILE_NAME"
}

function htmlCtkResultsFile() {
  local prefix="$1"
  createPath "$prefix" "$CTK_RESULTS_HTML_FILE_NAME"
}

function ctkRunLogFile() {
  local prefix="$1"
  createPath "$prefix" "ctk-run.log"
}

function npmProxyConfigFile() {
  local prefix="$1"
  createPath "$prefix" ".npmrc"
}

function ctkNodeJsBaseDir() {
  local prefix="$1"
  createPath "$prefix" "ctk"
}

function nopo11yConfigDirIn() {
  local prefix="$1"
  createPath $prefix "nopo11y-config"
}

function nopo11yConfigFileIn() {
  local prefix="$1"
  local env="$2"
  createPath $(nopo11yConfigDirIn $prefix) "$env.yaml"
}

function arazzoConfigDirIn() {
  local prefix="$1"
  createPath $prefix "arazzo"
}

function metaConfigFileIn() {
  local prefix="$1"
  createPath $prefix "meta-config.yaml"
}
