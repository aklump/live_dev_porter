##
 # Set and evaluate $cached_var_name as an array of processed filepaths.
 #
 # @global array $cached_var_name The name of the array to be created.
 # @global array $paths An array of unprocessed (tokenized, globbed) paths.
 ##

local _i
local _p
local _path
local _file_list

declare -a _file_list=()
for _path in "${paths[@]}"; do
  _path=$(_cloudy_resolve_path_tokens "$_path")
  [[ "$_path" != null ]] && _p="$(path_make_absolute "$_path" "$config_path_base")" && _path="$_p"

  # This will expand a glob finder.
  if [ -d "$_path" ]; then
    _file_list=("${_file_list[@]}" $_path)
  elif [ -f "$_path" ]; then
    _file_list=("${_file_list[@]}" $(ls $_path))
  elif [[ "$_path" != null ]]; then
    _file_list=("${_file_list[@]}" $_path)
  fi
done

# Glob can increase _file_list so we apply realpath to all here now.
local _i=0
for _path in "${_file_list[@]}"; do
  if [ -e "$_path" ]; then
    _file_list[$_i]=$(realpath "$_path")
  fi
  let _i++
done

if [[ ${#_file_list[@]} -eq 1 ]]; then
  eval "$cached_var_name="${_file_list[0]}""
else
  eval "$cached_var_name=("${_file_list[@]}")"
fi

unset _i
unset _p
unset _path
unset _file_list
