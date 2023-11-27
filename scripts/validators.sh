#!/bin/sh

true='0'
false='1'
envvarsFile=".envvars"
# assign to a variable the value of a file relative to this script, even if the script is sourced into other script
# https://stackoverflow.com/a/246128/2885946
#envvarsFile="$(cd -- "$( dirname -- "${BASH_SOURCE}" )" &> /dev/null && pwd)/$envvarsFile"

printerr () {
  echo -e "[$(date)]\033[31m[ERROR] $1\033[0m"
}

printok () {
  echo -e "[$(date)]\033[32m[OK] $1\033[0m"
}

printinf () {
  echo -e "[$(date)]\033[33m[INFO] $1\033[0m"
}

printwarning() {
  echo -e "[$(date)]\033[1;38;5;208m[WARNING] $1\033[0m"
}

isNullOrEmpty() {
  [ -z "$1" ] && return $true || return $false
}

exitIfNullOrEmpty() {
  local varname="$1"
  local varvalue="$2"
  
  if isNullOrEmpty "$varvalue"; then
    printerr "Environment variable '$varname' is required."
    exit 1
  fi
}

warnIfNullOrEmpty() {
  local varname="$1"
  local varvalue="$2"
  if isNullOrEmpty "$varvalue" ; then
    printwarning "Environment variable '$varname' is empty."
  fi
}

isBetween() {
  local min="$1"
  local max="$2"
  local n="$3"

  if [ "$min" -gt "$max" ]; then
    printerr 'Bad usage. Min must be greater than Max.'
    exit 1
  fi

  [ "$n" -ge "$min" ] && [ "$n" -le "$max" ] && return $true || return $false
}

exitIfNotBetween() {
  local min="$1"
  local max="$2"
  local n="$3"
  local varname="$4"

  if ! isBetween "$min" "$max" "$n"; then
    printerr "Environment variable '$varname' is set with the value '$n', but must be between '$min' and '$max' (both included)."
    exit 1
  fi
}

getVarValue() {
  local varName="$1"
  local varValue="$(eval echo \$$varName)"
  echo "$varValue"
}

validateEnvvars() {
  local varName
  local isRequired
  local defaultValue

  # Read the file envvars line by line and get every token separated by a ;
  while IFS=';' read -r varName isRequired defaultValue; do
    # Ignore lines that start with a #
    if [ "${varName:0:1}" != "#" ]; then

      # Remove leading and trailing whitespaces
      varName="$(echo -e "${varName}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      isRequired="$(echo -e "${isRequired}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

      local varValue="$(getVarValue "$varName")"
      if [ "$isRequired" = "true" ]; then
        exitIfNullOrEmpty "$varName" "$varValue"
      elif isNullOrEmpty "$varValue" && ! isNullOrEmpty "$defaultValue"; then
        eval "export $varName=$defaultValue"
      else
        warnIfNullOrEmpty "$varName" "$varValue"
      fi

    fi
  done < "$envvarsFile"
}

checkIfArgMatches() {
  local arg="$1"

  while [ $# -gt 0 ]; do
    shift
    if [ "$arg" = "$1" ]; then
      return 0
    fi
  done

  return 1
}

# function to check if previous command was successful and, if it was, then do what is passed as argument
doIfPrevWas() {
  local prevExitCode="$?"

  #check if number of arguments is between 2 and 4
  if ! isBetween 2 4 "$#"; then
    printerr "doIfPrevWas: wrong number of arguments. Must be 2 or 4."
    exit 1
  fi

  local sucessCommand=''
  local errorCommand=''

  while [ $# -gt 0 ]; do
    case "$1" in
      -s|--success)
        shift
        if isNullOrEmpty "$sucessCommand"; then
          sucessCommand="$1"
        else
          printerr "doIfPrevWas: duplicated option '$1'"
          exit 1
        fi
        sucessCommand="$1"
        ;;
      -e|--error)
        shift
        if isNullOrEmpty "$errorCommand"; then
          errorCommand="$1"
        else
          printerr "doIfPrevWas: duplicated option '$1'"
          exit 1
        fi
        errorCommand="$1"
        ;;
      *)
        printerr "doIfPrevWas: invalid argument '$1'"
        exit 1
        ;;
    esac
    shift
  done

  if [ $prevExitCode -eq 0 ]; then
    eval "$sucessCommand"
    return $?
  else
    eval "$errorCommand"
    return $?
  fi
}