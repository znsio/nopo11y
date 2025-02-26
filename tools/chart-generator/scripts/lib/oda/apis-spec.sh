
readonly API_SPEC_VER_4="v4"
readonly API_SPEC_VER_5="v5"
readonly API_SPEC_VER_DEFAULT="$API_SPEC_VER_4"

function apiSpecVer() {
  local compDirByEnv="$1"
  local serviceName="$2"
  
  apiCompMergedValuesFile=$(apisNCompMergedValuesFile $(chartsDirIn "$compDirByEnv"))
  cat "$apiCompMergedValuesFile" | SVC="$serviceName" yq '.jio-oda-common.apis[] | select(.service.name == strenv(SVC)) | .service.spec'
}

function apiSpecVerOrDefault() {
  local compDirByEnv="$1"
  local serviceName="$2"
  
  specVersion=$(apiSpecVer "$compDirByEnv" "$serviceName")
  if [[ -z "$specVersion" || "$specVersion" == "null" ]]; then
    specVersion="$API_SPEC_VER_DEFAULT"
  fi
  echo -n "$specVersion"
}

function verifyApiSpecVer() {
  local specVersion="$1"
  if [[ ! "$specVersion" == "$API_SPEC_VER_4" && ! "$specVersion" == "$API_SPEC_VER_5" ]]; then
    show "Spec version '$specVersion' for api '$apiId' is not yet supported" "x"
    exit 1
  fi
}

function apiAppTag() {
  local compDirByEnv="$1"
  local serviceName="$2"
  
  apiCompMergedValuesFile=$(apisNCompMergedValuesFile $(chartsDirIn "$compDirByEnv"))
  cat "$apiCompMergedValuesFile" | SVC="$serviceName" yq '.jio-oda-common.apis[] | select(.service.name == strenv(SVC)) | .k8s.app'
}

function apiImplTag() {
  local compDirByEnv="$1"
  local serviceName="$2"
  
  apiCompMergedValuesFile=$(apisNCompMergedValuesFile $(chartsDirIn "$compDirByEnv"))
  cat "$apiCompMergedValuesFile" | SVC="$serviceName" yq '.jio-oda-common.apis[] | select(.service.name == strenv(SVC)) | .k8s.impl'
}

function apiSpecInfo() {
  local apiKind="$1"
  local apiId="$2"
  local specVersion="$3"
  local compDirByEnv="$4"
  local serviceName="$5"
  
  specFile=$(apiSpecFile "$apiId" "$specVersion")
  implTag=$(apiImplTag "$compDirByEnv" "$serviceName")
  appTag=$(apiAppTag "$compDirByEnv" "$serviceName")
  specRelativeLocation=$(echo "$specFile" | sed 's/.*\/ODA/\/ODA/g')
  tempFile=$(tempFileIn "$compDirByEnv" "9")
  
  cat "$specFile" | sed 's/"x-api-id":/"xApiId":/g' | jq --arg APP "$appTag" -r '{id: .info.xApiId, version: .info.version, apiType: (if has("swagger") then "swagger" elif has("openapi") then "openapi" else "unknown" end), name: (.info.title | gsub(" "; "")), path: (if has("swagger") then ("/" + $APP + .basePath) elif has("openapi") then ("/" + $APP + .servers[].url) else "unknown" end | sub("https://serverRoot/";"/") | sub("https://serverRoot";"/") | sub("{apiRoot}";""))}' | jq --arg IMPL "$implTag" --arg SPEC "$specRelativeLocation" '. + {developerUI: (.path + "docs/"), specification: ("https://devops.jio.com/XNSio/TmForum/_git/contracts" + $SPEC), implementation: $IMPL, port: "8080"}' | yq eval -P | sed 's/^/  /g' | sed 's/  id: /- id: /g' >> "$tempFile"

  result=""
  if [[ "$apiKind" == "$KEY_DEPENDENT" ]]; then
    result=$(cat "$tempFile" | grep -v 'implementation: \|path: \|developerUI: \|port:' | yq '.')
  else
    result=$(cat "$tempFile" | yq '.')
  fi
  rm -f "$tempFile"
  echo -n "$result"
}

function copyCtkInfo() {
  local apiKind="$1"
  local apiId="$2"
  local specVersion="$3"
  local compDirByEnv="$4"
  local apiSpecInfo="$5"

  if [[ "$apiKind" == "$KEY_EXPOSED" ]]; then
    show "Finding api ctk for '$apiId' ('$specVersion')" "h3"
    ctkDir=$(ctkInfoDir "$compDirByEnv" "$apiKind")  
    ctkFile=$(apiCTKFile "$apiId" "$specVersion")
    ctkServiceUrlFile=$(apiCTKServiceUrlFile "$ctkDir" "$ctkFile")

    ctkServiceUrlPath=$(echo "$apiSpecInfo" | yq '.[0].path')
    if [[ -z "$ctkServiceUrlPath" ]]; then
      show "No ODA API CTK service url path found for '$apiId' ($specVersion')" "x"
      exit 1
    fi
    show "Generated ctk service url path for '$apiId' ('$specVersion') - '$ctkServiceUrlPath'"

    show "Copying api ctk '$ctkFile' and ctk service url '$ctkServiceUrlFile' for '$apiId' ('$specVersion') in '$ctkDir'"
    mkdir -p "$ctkDir"
    cp "$ctkFile" "$ctkDir"
    echo -n "$ctkServiceUrlPath" > "$ctkServiceUrlFile"
  fi
}

function copySpec() {
  local apiKind="$1"
  local apiId="$2"
  local specVersion="$3"
  local compDirByEnv="$4"

  show "Finding api spec for '$apiId' ('$specVersion')" "h3"
  apiSpecsDir=$(apiSpecInfoDir "$compDirByEnv" "$apiKind")  
  specFile=$(apiSpecFile "$apiId" "$specVersion")
  show "Copying api spec for '$apiId' ('$specVersion') - '$specFile' in '$apiSpecsDir'"
  mkdir -p "$apiSpecsDir"
  cp "$specFile" "$apiSpecsDir"
}

function extractAndProcessApiSpecInfoFor() {
  local apiKind="$1"
  local compDirByEnv="$2"

  apiSpecInfoFile=$(apiSpecInfoFile "$compDirByEnv" "$apiKind")
  idsFile=$(declaredIdsFileIn "$compDirByEnv" "$apiKind")
  idsByServiceFile=$(declaredIdsFileByApiNameIn "$compDirByEnv" "$apiKind")

  show "Extracting $apiKind api specs for - '$(cat $idsFile)' in '$apiSpecInfoFile'" "h3"
  cat "$idsByServiceFile" | yq 'to_entries | .[].key' | while IFS= read -r serviceName || [ -n "$serviceName" ]; do
    cat "$idsByServiceFile" | SVC="$serviceName" yq '. | with_entries(select(.key == strenv(SVC))) | .[]' | sed 's/- //g' | while IFS= read -r apiId || [ -n "$apiId" ]; do
      
      show "Processing $apiKind api - id='$apiId', name='$serviceName'" "h3"
      if [[ ! -z "$apiId" && ! "$apiId" == "-" ]]; then
        specVersion=$(apiSpecVerOrDefault "$compDirByEnv" "$serviceName")
        verifyApiSpecVer "$specVersion"

        copySpec "$apiKind" "$apiId" "$specVersion" "$compDirByEnv"
        
        specInfo=$(apiSpecInfo "$apiKind" "$apiId" "$specVersion" "$compDirByEnv" "$serviceName")
        echo "$specInfo" >> "$apiSpecInfoFile"
        
        copyCtkInfo "$apiKind" "$apiId" "$specVersion" "$compDirByEnv" "$specInfo"
      fi
    done
  done

  show "Extracted $apiKind api specs for - '$(cat $idsFile)' in '$apiSpecInfoFile'"
  cat "$apiSpecInfoFile" | head -n 10
}

function extractApiSpecInfo() {
  local env="$1"
  local compDirByEnv="$2"

  for apiKind in $(echo -n "$KEY_EXPOSED $KEY_DEPENDENT")
  do
    extractAndProcessApiSpecInfoFor "$apiKind" "$compDirByEnv"
  done
}