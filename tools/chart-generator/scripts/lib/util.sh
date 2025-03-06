
function copySpecmaticFilesIfPresent() {
  local srcDir="$1"
  local trgDir="$2"

  for specmaticFile in $(echo -n "$(specmaticJsonFileIn $srcDir) $(specmaticYamlFileIn $srcDir)")
  do
    if [[ -r "$specmaticFile" ]]; then
      cp "$specmaticFile" "$trgDir"
    fi
  done
}

function copyTemplatesDirIfPresent() {
  local srcTemplatesDir="$1"
  local trgTemplatesDir="$2"

  if [[ -d "$srcTemplatesDir" ]]; then
    mkdir -p "$trgTemplatesDir"
    cp -r "$srcTemplatesDir/." "$trgTemplatesDir"
  fi
}

function copyTemplatesDirInIfPresent() {
  local srcDir="$1"
  local trgDir="$2"
  copyTemplatesDirIfPresent $(templatesDirIn "$srcDir") $(templatesDirIn "$trgDir")
}

function projectDirName() {
  local projectBasePath="$1"

  name=$(dirname "$projectBasePath")
  if [[ -z "$name" ]]; then
    show "Project's directory name could not be found from its provided base path - '$projectBasePath'" "x"
    exit 1
  fi
  echo -n "$name"
}

function projectChartName() {
  local projectBasePath="$1"

  chartFile=$(chartsFileWithin "$projectBasePath")
  name=$(cat "$chartFile" | yq '.name')
  if [[ -z "$name" ]]; then
    show "Project's chart name could not be found from its provided base path - '$projectBasePath'" "x"
    exit 1
  fi
  echo -n "$name"
}

function helmTemplateName() {
  local name="$1"
  echo -n "$name" | awk '{print tolower($0)}' | tr '-' '\n' | sed 's/\(.\).*/\1/g' | tr -d '\n'
}

function mergeValuesHelm() {
  local entityTag="$1"
  local env="$2"
  local srcChartsDirByEnv="$3"
  local trgChartsDirByEnv="$4"

  show "Attempting to merge values.yaml of $entityTag by env '$env'" "h3"
  defaultValuesFile=$(valuesFileIn $srcChartsDirByEnv)
  envSpecificValuesFile=$(valuesFileIn $srcChartsDirByEnv $env)
  trgValuesFile=$(valuesFileIn $trgChartsDirByEnv)
  show "default      - '$defaultValuesFile'"
  show "env-specific - '$envSpecificValuesFile'"
  show "target       - '$trgValuesFile'"

  mkdir -p "$trgChartsDirByEnv"
  if [[ -r $defaultValuesFile && -r $envSpecificValuesFile ]]; then
    show "Merging default and env-specific values.yaml of $entityTag"
    # array replace mode
    yq eval-all '. as $item ireduce ({}; . * $item)' $defaultValuesFile $envSpecificValuesFile > $trgValuesFile
    # array append mode
    ## yq eval-all '. as $item ireduce ({}; . *+ $item)' $defaultValuesFile $envSpecificValuesFile > $trgValuesFile
  elif [[ -r $defaultValuesFile && ! -r $envSpecificValuesFile ]]; then
    show "Copying default values.yaml of $entityTag"
    cp $defaultValuesFile $trgValuesFile
  elif [[ ! -r $defaultValuesFile && -r $envSpecificValuesFile ]]; then
    show "Copying env-specific values.yaml of $entityTag"
    cp $envSpecificValuesFile $trgValuesFile
  else
    show "None found for $entityTag"
  fi
}

function extractCompProjDirName() {
  compArtifactsPath=$(compDirIn $(inputDir))
  compArtifactDirName=$(ls "$compArtifactsPath")

  countOfDirs=$(ls "$compArtifactsPath" | wc -l | xargs)
  if [[ $countOfDirs -ne 1 ]]; then
    show "Zero or multiple component dirs found - '$compArtifactDirName' (total '$countOfDirs'). Exiting..."
    exit 1
  fi

  echo -n "$compArtifactDirName"
}

function extractCompId() {
  valuesFilePath=$(findValuesFileWithin "$INPUT_ODAC")

  countOfFiles=$(ls $valuesFilePath | wc -l | xargs)
  if [[ $countOfFiles -gt 1 ]]; then
    show "More than one values.yaml files found - '$valuesFilePath' (total '$countOfFiles'). Exiting..."
    exit 1
  fi

  cat "$valuesFilePath" | yq 'oda-common.component.id'
}

function apiNamesAsSsv() {
  servicesFile=$(servicesFileIn $(compProjDirIn $(inputDir) $(extractCompProjDirName)))
  if [[ ! -r "$servicesFile" ]]; then
    show "services.yaml either does not exist or is not readable - '$services.yaml'" "x"
    exit 1
  fi
  cat "$servicesFile" | yq '.[]' | tr '\n' ' '
}

function configureGitClient() {
  if [[ "$RUNTIME_HOST" == "$RUNTIME_HOST_CONTAINER" ]]; then
    show "Configuring https verification to be false"
    git config --global http.sslVerify false
  fi

  if [[ "$RUNTIME_HOST" == "$RUNTIME_HOST_CONTAINER" ]]; then
    if [[ "$RUNTIME_MODE" == "$RUNTIME_MODE_LOCAL" ]]; then
      show "Configuring PAT as auth token"
      git config --global http.extraHeader "Authorization: Bearer $GIT_AUTH_TOKEN_LOCAL"
    elif [[ "$RUNTIME_MODE" == "$RUNTIME_MODE_ADO" ]]; then
      show "Configuring ADO (System Access Token) as auth token"
      git config --global http.extraHeader "Authorization: Bearer $GIT_AUTH_TOKEN_ADO"
    fi
  fi

  if [[ "$RUNTIME_MODE" == "$RUNTIME_MODE_ADO" ]]; then
    show "Configuring proxy to be '$GIT_REPO_PROXY'"
    git config --global http.proxy "$GIT_REPO_PROXY"
    git config --global https.proxy "$GIT_REPO_PROXY"
  fi
}

function cleanUpDirs() {
  dirPathsAsSSV="$1"
  for dirPath in $(echo -n "$dirPathsAsSSV")
  do
    cleanUpDir "$dirPath"
  done

}

function cleanUpDir() {
  dirPath="$1"

  show "Cleaning up dir '$dirPath'" "h3"
  mkdir -p "$dirPath"

  show "Before cleaning..."
  ls -lah "$dirPath"

  rm -rf "$dirPath" && mkdir -p "$dirPath"

  show "After cleaning..."
  ls -lah "$dirPath"
}

function showWarningOrFail() {
  local action="$1"
  local msg="$2"

  if [[ "$action" == "$KEY_WARN" ]]; then
    show "$msg" "w"
  elif [[ "$action" == "$KEY_ERROR" ]]; then
    show "$msg" "x"
    exit 1
  else
    show "Unknown action '$action' configured/provided" "x"
    show "Hint: $msg"
    exit 1
  fi
}

function nonBlankValOrDefault() {
  local value="$1"
  local defaultValue="$2"

  if [[ -z "$value" ]]; then
    echo -n "$defaultValue"
  else
    echo -n "$value"
  fi
}

function dockerImageUrl() {
  local imgName="$1"
  local imgTag="$2"
  local imgRepo="$3"

  if [[ -z "$imgRepo" ]]; then
    echo -n "$imgName:$imgTag"
  else
    echo -n "$imgRepo/$imgName:$imgTag"
  fi
}

function tagTokensAsSSV() {
  local tag=$1
  echo -n "$tag" | sed -E 's/([A-Z])/-\1/g' | tr '[:upper:]' '[:lower:]' | sed -e 's/^-//' -e 's/-$//' | sed 's/[-_]/ /g'
}

function shortenedTag() {
  local text="$1"
  echo -n "$(tagTokensAsSSV $text)" | awk '{for(i=1;i<=NF;i++)printf("%c", substr($i,1,1))}' | xargs
}

function readableTag() {
  local text="$1"

  result=""
  for token in $(tagTokensAsSSV $text); do
    if [[ ${#token} -le 4 ]]; then
      result+="$token-"
    else
      firstChar=$(echo -n "$token" | cut -c1)
      remaining2Chars=$(echo -n "$token" | cut -c2- | sed 's/[aeiouAEIOU]//g' | cut -c1-2)
      result+="$firstChar$remaining2Chars-"
    fi
  done

  echo -n ${result%-}
}
