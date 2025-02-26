
function extractCompSpecInfo() {
  local specFile="$1"
  local infoFile=$(compSpecInfoFile "$2")

  show "Extracting relevant ODAC spec info from '$specFile' into '$infoFile'" "h3"
  cat "$specFile" | yq '.spec | with_entries(select(.key == "name" or .key == "status" or .key == "functionalBlock" or .key == "publicationDate" or .key == "version" or .key == "description")) | (.description = "Jio implementation of ODA component - " + .name) | (.k8s.name.full = (.name | downcase)) | (.k8s.name.short = (.name | sub("[a-z]+", "") | downcase))' > "$infoFile"
  cat "$infoFile"
}

function extractNopollyInfo() {
  local specFile="$1"
  local infoFile=$(nopollyInfoFile "$2")

  show "Extracting relevant nopolly info from '$specFile' into '$infoFile'" "h3"
  cat "$specFile" | yq '.spec | with_entries(select(.key == "name")) | (.appLabel = (.name | downcase)) | (.deploymentName = (.name | sub("[a-z]+", "") | downcase) | (.includeReleaseNameInMetricsLabels = true) | with_entries(select(.key == "appLabel" or .key == "deploymentName" or .key == "includeReleaseNameInMetricsLabels")))' > "$infoFile"
  cat "$infoFile"
}

function extractRequiredApiIdsInfo() {
  local specFile="$1"
  local compDirByEnv="$2"
  local apiKind="$3"

  requiredIdsFile=$(requiredIdsFileIn "$compDirByEnv" "$apiKind")
  show "Extracting required ($apiKind) api ids from '$specFile' into '$requiredIdsFile'" "h3"
  mkdir -p $(apiIdsInfoDirIn "$compDirByEnv" "$apiKind")

  yqQuery=".spec.coreFunction.${apiKind}APIs.[] | select(.required == \"true\") | .id | @csv"
  cat "$specFile" | yq "$yqQuery" | sed 's/ //g' | tr '\n' ',' | sed 's/,$//' > "$requiredIdsFile"
  cat "$requiredIdsFile" && echo
}

# TODO refactor with other two aggregation functions
function aggregateDeclaredApiIdsByApiName() {
  local compDirByEnv="$1"
  local apiKind="$2"

  declaredIdsFile=$(declaredIdsFileByApiNameIn "$compDirByEnv" "$apiKind")
  show "Aggregating declared ($apiKind) api ids (by api name) into '$declaredIdsFile'" "h3"

  tempFile=$(tempFileIn "$compDirByEnv" "1")
  for svcName in $(apiNamesAsSsv)
  do
    svcDirByEnv=$(apiSvcDirIn "$tempEnvDir" "$svcName")
    apiIdsInfoFile=$(declaredIdsFileByApiNameIn $svcDirByEnv $apiKind)
    cat $apiIdsInfoFile >> "$tempFile"
  done

  mkdir -p $(apiIdsInfoDirIn "$compDirByEnv" "$apiKind")
  cat "$tempFile" | grep -v '^$' > "$declaredIdsFile"
  rm -f "$tempFile"
  cat "$declaredIdsFile" && echo
}

# TODO refactor with other two aggregation functions
function aggregateDeclaredApiIdsByDirName() {
  local compDirByEnv="$1"
  local apiKind="$2"

  declaredIdsFile=$(declaredIdsFileByDirNameIn "$compDirByEnv" "$apiKind")
  show "Aggregating declared ($apiKind) api ids (by dir name) into '$declaredIdsFile'" "h3"

  tempFile=$(tempFileIn "$compDirByEnv" "1")
  for svcName in $(apiNamesAsSsv)
  do
    svcDirByEnv=$(apiSvcDirIn "$tempEnvDir" "$svcName")
    apiIdsInfoFile=$(declaredIdsFileByDirNameIn $svcDirByEnv $apiKind)
    cat $apiIdsInfoFile >> "$tempFile"
  done

  mkdir -p $(apiIdsInfoDirIn "$compDirByEnv" "$apiKind")
  cat "$tempFile" | grep -v '^$' > "$declaredIdsFile"
  rm -f "$tempFile"
  cat "$declaredIdsFile" && echo
}

# TODO refactor with other two aggregation functions
function aggregateDeclaredApiIds() {
  local compDirByEnv="$1"
  local apiKind="$2"

  declaredIdsFile=$(declaredIdsFileIn "$compDirByEnv" "$apiKind")
  show "Aggregating declared ($apiKind) api ids into '$declaredIdsFile'" "h3"

  tempFile=$(tempFileIn "$compDirByEnv" "1")
  for svcName in $(apiNamesAsSsv)
  do
    svcDirByEnv=$(apiSvcDirIn "$tempEnvDir" "$svcName")
    apiIdsInfoFile=$(declaredIdsFileIn $svcDirByEnv $apiKind)
    ids=$(cat $apiIdsInfoFile)
    if [[ ! -z "$ids" ]]; then
      echo -n "$ids," >> "$tempFile"
    fi
  done

  mkdir -p $(apiIdsInfoDirIn "$compDirByEnv" "$apiKind")
  cat "$tempFile" | sed 's/,$//' > "$declaredIdsFile"
  rm -f "$tempFile"
  cat "$declaredIdsFile" && echo
}

function raiseErrIfRequiredIdsAbsent() {
  local compDirByEnv="$1"
  local apiKind="$2"

  requiredIdsCsvFile=$(requiredIdsFileIn "$compDirByEnv" "$apiKind")
  declaredIdsCsvFile=$(declaredIdsFileIn "$compDirByEnv" "$apiKind")
  if [[ -s "$requiredIdsCsvFile" ]]; then
    show "Checking whether all required $apiKind api ids - '$(cat $requiredIdsCsvFile)' are declared - '$(cat $declaredIdsCsvFile)'" "h3"
    set +e
    $(cat "$requiredIdsCsvFile" | sed 's/,/\n/g' | xargs -I {} grep -q '{}' "$declaredIdsCsvFile")
    if [[ $? -ne 0 ]]; then
      specMismatchAction=${SPEC_MISMATCH_ACTION[$apiKind]}
      show "Configured action on spec verification mismatch - '$specMismatchAction'"
      showWarningOrFail "$specMismatchAction" "One/more required $apiKind api ids not found in declaration"
    fi

    show "All $apiKind api ids: OK"
    set -e
  else
    show "Spec does not mandate any $apiKind api ids as required ones. Skipping checks."
  fi
}

function verifyIfApiDeclarationMatchesSpec() {
  local env="$1"
  local compDirByEnv="$2"
  local specFile="$3"

  for apiKind in $(echo -n "$KEY_EXPOSED $KEY_DEPENDENT")
  do
    extractRequiredApiIdsInfo "$specFile" "$trgCompDirByEnv" "$apiKind"
    aggregateDeclaredApiIds "$trgCompDirByEnv" "$apiKind"
    aggregateDeclaredApiIdsByDirName "$trgCompDirByEnv" "$apiKind"
    aggregateDeclaredApiIdsByApiName "$trgCompDirByEnv" "$apiKind"
    raiseErrIfRequiredIdsAbsent "$trgCompDirByEnv" "$apiKind"
  done
}
