
function generateCompArtifacts() {
  for env in $(echo -n "$(allEnvsAsSsv)")
  do
    show "Generating ODAC artifacts by env '$env'" "h1"

    for svcName in $(apiNamesAsSsv)
    do
      prepApiArtifactsByEnv "$svcName" "$env"
    done

    prepCompArtifactsByEnv $env
  done
}

function generateApiArtifacts() {
  for env in $(echo -n "$(allEnvsAsSsv)")
  do
    show "Generating ODAA artifacts by env '$env'" "h1"
    prepApiArtifactsByEnv2 "$env"
  done

  publishArtifacts
}