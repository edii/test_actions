error() {
  echo -e "$@"
  exit 1
}

_script_directory() {
  local base; base=$(dirname $0)

  [ -z "$base" ] && base="."
  (cd "$base" && pwd)
}

SCRIPT_DIRECTORY=$(_script_directory); export SCRIPT_DIRECTORY
