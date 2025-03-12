
function bootstrap() {
  function scriptsForDisplay() {
    local mode="$(runtimeMode)"

    if [[ $mode == "$RUNTIME_MODE_LOCAL" ]]; then
      echo -n "./lib/display/colored.sh"
    elif [[ $mode == "$RUNTIME_MODE_PIPELINE" ]]; then
      echo -n "./lib/display/basic.sh"
    else
      echo -e "\n\n#### Runtime mode '$mode' not supported! Exiting... ####\n\n"
      exit 1
    fi
  }

  function specificScriptsByMode() {
    echo -n "$(scriptsForDisplay)"
  }

  function importScripts() {
    specificLibPathsByModeAsSSV=$(specificScriptsByMode)
    echo -e "\nSourcing following specific scripts (by execution mode)..."
    for libPath in $(echo -n "$specificLibPathsByModeAsSSV")
    do
      echo -e "'$libPath'"
      source "$libPath"
    done

    echo -e "\nSourcing following common scripts..."
    for libPath in $(find ./lib -type f -name "*.sh" -print | grep -v 'constants.sh\|bootstrap.sh\|config.sh\|lib/display/')
    do
      echo -e "'$libPath'"
      source "$libPath"
    done
  }

  importScripts
}