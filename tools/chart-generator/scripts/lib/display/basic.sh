function show() {
  local message="$1"
  local flag="$2"

  local msg=""
  if [[ "$flag" == "x" ]]; then
    msg+="\n[ERROR] "
    message+=". Exiting...\n"
  elif [[ "$flag" == "w" ]]; then
    msg+="\n[WARN] "
  elif [[ "$flag" == "/" ]]; then
    msg+="\n[SUCCESS] "
  elif [[ "$flag" == "h1" ]]; then
    msg+="\n\n>>>>>> "
  elif [[ "$flag" == "h2" ]]; then
    msg+="\n\n >> "
  elif [[ "$flag" == "h3" ]]; then
    msg+="\n >> "
  else
    msg+="  > [INFO] "
  fi

  msg+="$message"
  echo -e "$msg"
}
