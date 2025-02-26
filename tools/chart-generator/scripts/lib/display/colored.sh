
readonly RED="\033[0;31m"
readonly GREEN="\033[0;30m"
readonly YELLOW="\033[0;33m"
readonly BOLD="\033[1m"
readonly UNDERLINE="\033[4m"
readonly NC="\033[0m"

function show() {
  local message="$1"
  local flag="$2"

  local msg=""
  if [[ "$flag" == "x" ]]; then
    msg+="${RED}${BOLD}\n[ERROR] "
    message+=". Exiting...\n"
  elif [[ "$flag" == "w" ]]; then
    msg+="${RED}\n[WARN] "
  elif [[ "$flag" == "/" ]]; then
    msg+="${GREEN}${BOLD}\n[SUCCESS] "
  elif [[ "$flag" == "h1" ]]; then
    msg+="${BOLD}\n>>>>>> ${UNDERLINE}"
  elif [[ "$flag" == "h2" ]]; then
    msg+="${BOLD}\n >> "
  elif [[ "$flag" == "h3" ]]; then
    msg+="${YELLOW}\n >> "
  else
    msg+="${YELLOW}  > [INFO] "
  fi

  msg+="$message${NC}"
  echo -e "$msg"
}
