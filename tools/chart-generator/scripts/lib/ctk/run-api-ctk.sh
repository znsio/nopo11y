
function ctkTmfId() {
  local ctkFilePath="$1"
  echo "$ctkFilePath" | sed -n 's/^.*\(TMF[0-9][0-9][0-9]\).*$/\1/p'
}

function unzipCTK() {
  local ctkFile="$1"
  local unzippedCtkBasePath="$2"

  show "Unzipping CTK zip file '$ctkFile' into '$unzippedCtkBasePath'" "h3"
  unzip "$ctkFile" -d "$unzippedCtkBasePath"
  
  unzippedCtkPath=$(ctkUnzipDir $unzippedCtkBasePath)
  show "Unzipped content within '$unzippedCtkPath'"
  ls -lah "$unzippedCtkPath"
}

function updateConfigFile() {
  local unzippedCtkBasePath="$1"
  local appUrl="$2"

  originalConfig=$(ctkConfigFile $unzippedCtkBasePath)
  tempConfig=$(ctkTempConfigFile $unzippedCtkBasePath)
  
  show "Updating config file in '$unzippedCtkBasePath' with url '$appUrl'" "h3"
  show "Config contents (before) - '$originalConfig'"
  cat "$originalConfig" | head -n 10

  cat "$originalConfig" | jq --arg URL $appUrl '.url = $URL' > "$tempConfig"
  cp "$tempConfig" "$originalConfig"
  rm -f "$tempConfig"

  show "Config contents (after) - '$originalConfig'"
  cat "$originalConfig" | head -n 10
}

function updateNpmProxyConfig() {
  local unzippedCtkBasePath="$1"

  if [[ "$RUNTIME_MODE" == "$RUNTIME_MODE_PIPELINE" ]]; then
    unzippedCtkPath=$(ctkUnzipDir $unzippedCtkBasePath)
    srcProxyFile=$(npmProxyConfigFile $CONFIG_PATH)
    trgProxyFile=$(npmProxyConfigFile $(ctkNodeJsBaseDir $unzippedCtkPath))
    show "Copying npm proxy config from '$srcProxyFile' to '$trgProxyFile'" "h3"

    show "Contents of '$srcProxyFile'"
    cat "$srcProxyFile" | head -n 2

    show "Contents of '$unzippedCtkPath' (Before copy)"
    ls -lah "$unzippedCtkPath"

    cp "$srcProxyFile" "$trgProxyFile"

    show "Contents of '$unzippedCtkPath' (After copy)"
    ls -lah "$unzippedCtkPath"

    show "Contents of '$trgProxyFile'"
    cat "$trgProxyFile" | head -n 2
  else
    show "Skipping setting up npm proxy config for runtime mode '$RUNTIME_MODE'" "h3"
  fi
}

function runCtk() {
  local unzippedCtkBasePath="$1"
  local testResultsDir="$2"

  unzippedCtkPath=$(ctkUnzipDir $unzippedCtkBasePath)
  runLogFile=$(ctkRunLogFile $unzippedCtkPath)
  
  show "Running CTK from '$unzippedCtkPath'" "h3"
  (cd "$unzippedCtkPath" && chmod +x "$CTK_EXEC_FILE_NAME" && /bin/sh "./$CTK_EXEC_FILE_NAME" > "$runLogFile")
  if [[ -f "$runLogFile" ]]; then
    show "Snippet of ctk run log from '$runLogFile'"
    cat "$runLogFile"
  fi

  jsonResultsFile=$(jsonCtkResultsFile "$unzippedCtkPath")
  htmlResultsFile=$(htmlCtkResultsFile "$unzippedCtkPath")
  if [[ ! -f "$jsonResultsFile" ]]; then
    show "Failed to run CTK from '$unzippedCtkPath'" "x"
    exit 1
  fi

  show "Storing test results and run log in '$testResultsDir'" "h3"
  for file in $(echo -n "$jsonResultsFile $htmlResultsFile $runLogFile")
  do
    cp "$file" "$testResultsDir/"
  done
  ls -lah "$testResultsDir"

  totalTests=$(cat "$jsonResultsFile" | jq '.run.stats.assertions.total')
  failedTests=$(cat "$jsonResultsFile" | jq '.run.stats.assertions.failed')
  showWarningOrFail "$ON_CTK_FAILURE" "CTK ran total '$totalTests' tests, out of which '$failedTests' failed"
}

function processCtk() {
  local ctkFile="$1"
  local appUrl="$2"

  show "Processing ctk '$ctkFile' against app '$appUrl'" "h2"
  tmfId=$(ctkTmfId "$ctkFile")

  tmpDirByTmfId=$(createPath $(tempDir) "$tmfId")
  outputDirByTmfId=$(createPath $(artifactsDirIn $(outputDir)) "$tmfId")

  cleanUpDirs "$tmpDirByTmfId $outputDirByTmfId"
  unzipCTK "$ctkFile" "$tmpDirByTmfId"
  updateConfigFile "$tmpDirByTmfId" "$appUrl"
  updateNpmProxyConfig "$tmpDirByTmfId"
  runCtk "$tmpDirByTmfId" "$outputDirByTmfId"
}

