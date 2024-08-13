#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause

# Set a JSON string to be later read by json_get_value().
#
# Call this once to put your json string into memory, then make unlimited calls
# to json_get_value as necessary.  You may check the return code to ensure JSON syntax
# is valid.  If your string contains single quotes, you will need to escape them.
#
# @param string A JSON string, wrapped by single quotes.
#
# @code
#   json_set '{"foo":{"bar":"baz et al"}}'
# @endcode
#
# @return 0 if the JSON is valid; 1 otherwise.
json_content=''
function json_set() {
  local incoming_json="$1"

  local clean_json

  clean_json="$(. "$PHP_FILE_RUNNER" "$CLOUDY_CORE_DIR/php/functions/invoke.php" "json_bash_filter" "$incoming_json")"
  if [[ $? -ne 0 ]]; then
    write_log_error "json_set \"$path\" failed to set JSON: $incoming_json"
    write_log_error "$clean_json"
    return 1
  fi
  json_content="$clean_json"
}

# Load a JSON file to be read by json_get_value.
#
# @param string Path to a valid JSON file
#
# @return 0 if JSON is valid. 1 if not.
function json_load_file() {
  local path_to_json="$1"

  local loaded_json

  loaded_json="$(. "$PHP_FILE_RUNNER" "$CLOUDY_CORE_DIR/php/functions/invoke.php" "json_load_file" "$path_to_json")"
  if [[ $? -ne 0 ]]; then
    write_log_error "json_load_file \"$path\" failed to load $path_to_json"
    write_log_error "$loaded_json"
    return 1
  fi
  json_set "$loaded_json"
}

# Get the set JSON
#
# @echo The JSON string set by json_set
#
# @code
#   json="$(json_get)"
# @endcode
#
function json_get() {
  echo "$json_content"
}

# Echo a value by dot-path in the set/loaded JSON.
#
# If the path is invalid, an empty string is echoed.  Be sure to wrap in double quotes to protect values that contain spaces.
#
# @param string The dot path, e.g. 'foo.bar'
#
# @code
#   json_set '{"foo":{"bar":"baz et al"}}'
#   value="$(json_get_value foo.bar)"
# @endcode
#
function json_get_value() {
  local path="$1"

  local value

  value="$(. "$PHP_FILE_RUNNER" "$CLOUDY_CORE_DIR/php/functions/invoke.php" "json_get_value" "$path" "$json_content")"
  if [[ $? -ne 0 ]]; then
    write_log_error "json_get_value \"$path\" failed against JSON: $(json_get)"
    write_log_error "$value"
    return 1
  fi
  echo "$value"
}

# Present a multiple choice selection list to the user.
#
# @param string The message to display
# @param string Optional.  Alter the option to display for cancel.
#
# The choices should be defined in the variable: choose__array before calling.
# You may pass another array which is the labels to appear in the menu if you
# want, it must have the same number of elements as choose__array and the
# indexes must correspond label/value. Here is an example of a menu to choose a
# file in a directory:
# @code
# choose__array=($(ls "$CONFIG_DIR"/processors/))
# processor=$(choose "Which processor?")
# [ $? -ne 0 ] && exit_with_success
# @endcode
#
# @return 0 and echos the choice if one was selected; returns 1 if cancelled.
choose__array=()
choose__labels=()
function choose() {
  parse_args "$@"
  local message="${parse_args__args[0]}"
  local cancel_label="${parse_args__args[1]:-NONE}"

  message="${message% }"
  message="${message%.}"
  message="$message >"

  if [[ "$parse_args__options__caution" ]]; then
    PS3="$(echo_warning "$message") "
  elif [[ "$parse_args__options__danger" ]]; then
    PS3="$(echo_error "$message") "
  else
    PS3="$(echo_green_highlight "$message") "
  fi

  choose__values=("${choose__array[@]}")
  if [[ ${#choose__labels[@]} -eq 0 ]]; then
    choose__labels=("${choose__values[@]}")
  fi
  choose__values=("${choose__values[@]}" "$cancel_label")
  choose__labels=("${choose__labels[@]}" "$cancel_label")

  select selection in "${choose__labels[@]}"; do
    [[ "$selection" == "$cancel_label" ]] && return 1

    # Convert label to value, if necessary.
    for (( i=0; i<${#choose__values[@]}; i++ )); do
      if [[ "${choose__labels[$i]}" == "$selection" ]]; then
        echo "${choose__values[$i]}" && return 0
      fi
    done

    echo "$selection" && return 0
  done
}

# Prompt for a Y or N confirmation.
#
# @param string The confirmation message
# --caution - Use when answering Y requires caution.
# --danger - Use when answering Y is a dangerous thing.
#
# @return 0 if the user answers Y; 1 if not.
function confirm() {
    parse_args "$@"
    local message="${parse_args__args[0]:-Continue?} [y/n]:"
    [[ "$parse_args__options__caution" ]] && message=$(echo_warning "$message")
    [[ "$parse_args__options__danger" ]] && message=$(echo_error "$message")
    echo
    while true; do
        read -r -n 1 -p "$message " REPLY
        case $REPLY in
            [yY]) echo; return 0 ;;
            [nN]) echo; return 1 ;;
            *) printf " \033[31m %s \n\033[0m" "invalid input"
        esac
    done
}

# Prompt the user to read a message and press any key to continue.
#
# @param string The message to show the user.
#
# @return nothing
function wait_for_any_key() {
    local message="$1"

    parse_args "$@"
    local message="${parse_args__args}; press any key to continue..."
    [[ "$parse_args__options__caution" ]] && message=$(echo_warning "$message")
    [[ "$parse_args__options__danger" ]] && message=$(echo_error "$message")
    read -r -n 1 -p "$message "
}

# Determine if a given directory has any non-hidden files or directories.
#
# @param string The path to a directory to check
#
# @return 0 if the path contains non-hidden files directories; 1 if not.
function dir_has_files() {
    local path_to_dir="$1"

    [ -d "$path_to_dir" ] && [[ "$(ls "$path_to_dir")" ]]
}

# Echo the title as defined in the configuration.
#
# @param string A default value if no title is defined.
#
# @return nothing.
function get_title() {
    local default="$1"

    local title
    eval $(get_config_as "title" "title" "$default")
    echo $title
}

##
 # Echo the md5 hash of a string.
 #
 # $1 = string The string to hash
 #
 # @return 0 if the string was able to be hashed.
 #
function md5_string() {
  local string="$1"

  type md5sum >/dev/null 2>&1; [ $? -eq 0 ] && printf '%s' "$string" | md5sum | cut -d ' ' -f 1 && return 0
  type md5 >/dev/null 2>&1; [ $? -eq 0 ] && printf '%s' "$string" | md5 | cut -d ' ' -f 1 && return 0

  return 1
}

# Echos the version of the script.
#
# @return nothing.
function get_version() {
    local version
    eval $(get_config_as "version" "version" "1.0")
    echo $version
}

# Echo the current unix timestamp.
#
# @return nothing.
function timestamp() {
    date +%s
}

# Echo the current local time as hours/minutes with optional seconds.
#
# options -
#   -s - Include the seconds
#
# @return nothing.
function time_local() {
    parse_args "$@"
    if [[ "$parse_args__options__s" ]]; then
        date +%H:%M:%S
    else
        date +%H:%M
    fi
}

# Return the current datatime in ISO8601 in UTC.
#
# options -
#   -c - Remove hyphens and colons for use in a filename
#
# @return nothing.
function date8601() {
    parse_args "$@"
    if [[ "$parse_args__options__c" ]]; then
        date -u +%Y%m%dT%H%M%S
    else
        date -u +%Y-%m-%dT%H:%M:%S
    fi
    return 0
}

# Validate the CLI input arguments and options and exit if invalid.
#
# @return 0 if all input is valid
function validate_input() {
    local command
    local assume_command
    local commands

    [[ "$CLOUDY_CONFIG_JSON" ]] || fail_because "$FUNCNAME() cannot be called if \$CLOUDY_CONFIG_JSON is empty."

    command=$(get_command)

    # Insert an assume_command if that's configured.
    eval $(get_config "assume_command")
    if [[ "$assume_command" ]]; then
      eval $(get_config_keys "commands")
      array_has_value__array=(${commands[@]})
      ! array_has_value "$command" && CLOUDY_ARGS=("$assume_command" "${CLOUDY_ARGS[@]}")
      command=$(get_command)
    fi

    # Assert only defined operations are valid.
    [[ "$command" ]] && _cloudy_validate_command $command && _cloudy_validate_command_arguments $command

    # Assert only defined options for a given op.
    _cloudy_get_valid_operations_by_command $command

    for name in "${CLOUDY_OPTIONS[@]}"; do
       array_has_value__array=(${_cloudy_get_valid_operations_by_command__array[@]})
       array_has_value $name || fail_because "Invalid option: $name"
       eval "value=\"\$CLOUDY_OPTION__$(md5_string $name)\""
       . "$PHP_FILE_RUNNER" "$CLOUDY_CORE_DIR/php/validate_against_schema.php" "commands.$command.options.$name" "$name" "$value"
    done

    has_failed && exit_with_failure "Input validation failed."
    return 0
}

# Parses arguments into options, args and option values.
#
# Use this in your my_func function: parse_args "$@"
#
# The following variables are generated for:
# @code
#   my_func -ab --tree=life do re
# @endcode
#
# - parse_args__args=(do re)
# - parse_args__options=(a b tree)
# - parse_args__options__a=true
# - parse_args__options__b=true
# - parse_args__options__tree=life
# - parse_args__options_passthru="-a -b -tree=life"
#
function parse_args() {
    local name
    local value

    # Purge any previous values.
    for name in "${parse_args__options[@]}"; do
        eval "unset parse_args__options__${name//-/_}"
    done
    parse_args__options=()
    parse_args__args=()
    parse_args__options_passthru=''

    # Set the new values.
    for arg in "$@"; do
        if ! [[ "$arg" =~ ^(-{1,2})(.+)$ ]]; then
            parse_args__args=("${parse_args__args[@]}" "$arg")
            continue
        fi

        # a=1, dog=bark
        if [[ ${BASH_REMATCH[2]} = *"="* ]]; then
            [[ ${BASH_REMATCH[2]} =~ (.+)=(.+) ]]
            name="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"

            parse_args__options=("${parse_args__options[@]}" "$name")
            eval "parse_args__options__${name}=\"${value}\""
            parse_args__options_passthru="$parse_args__options_passthru $arg"

        # bc, tree
        else
            if [ ${#BASH_REMATCH[1]} -gt 1 ]; then
                options=("${BASH_REMATCH[2]}")
            else
                options=($(echo "${BASH_REMATCH[2]}" | grep -o .))
            fi
            for name in "${options[@]}"; do
                parse_args__options=("${parse_args__options[@]}" "$name")
                eval "parse_args__options__${name//-/_}=true"
                parse_args__options_passthru="$parse_args__options_passthru -${name}"
            done
        fi
    done
}

# Determine if the script was called with a command.
#
# @return 0 if a command was used.
function has_command() {
  [ ${#CLOUDY_ARGS[0]} -gt 0 ]
}

# Echo the command that was used to call the script.
#
# @return 0 if a valid command, 1 otherwise.
function get_command() {
    local command
    local c

    # Return default if no command given.
    if [ ${#CLOUDY_ARGS[0]} -eq 0 ]; then
        eval $(get_config_as "command" "default_command")
        echo $command && return 2
    fi

    command="${CLOUDY_ARGS[0]}"

    # See if it's a master command.
    eval $(get_config_keys "commands")
    array_has_value__array=(${commands[@]})
    array_has_value "$command" && echo $command && return 0

    # Look for command as an alias.
    for c in "${commands[@]}"; do
        eval $(get_config_as -a "aliases" "commands.$c.aliases")
        array_has_value__array=(${aliases[@]})
        array_has_value "$command" && echo $c && return 0
    done

    echo $command && return 1
}

# Determine if the script was called with a given option.
#
# @param string The option to check for.
#
# @return 0 if the option was used; 1 if not.
function has_option() {
    local option=$1

    array_has_value__array=(${CLOUDY_OPTIONS[@]})
    array_has_value "$1" && return 0
    return 1
}

# Determine if any options were used when calling the script.
#
# @return 0 if at least one option was used; 1 otherwise.
function has_options() {
    [ ${#CLOUDY_OPTIONS[@]} -gt 0 ] && return 0
    return 1
}

# Echo the value of a script option, or a default.
#
# @param string The name of the option
# @param string A default value if the option was not used.
#
# @return 0 if the option was used; 2 if the default is echoed.
function get_option() {
    local param=$1
    local default=$2

    local var_name="\$CLOUDY_OPTION__$(md5_string $param)"
    local value=$(eval "echo $var_name")
    [[ "$value" ]] && echo "$value" && return 0
    echo "$default" && return 2
}

# Search $array_has_value__array for a value.
#
# array_has_value__array
#
# @param string The value to search for in array.
#
# You must provide your array as $array_has_value__array like so:
# @code
#   array_has_value__array=("${some_array_to_search[@]}")
#   array_has_value "tree" && echo "found tree"
# @endcode
#
function array_has_value() {
    local needle="$1"

    local value
    local index=0
    array_has_value__index=null
    for value in "${array_has_value__array[@]}"; do
       [[ "$value" == "$needle" ]] && array_has_value__index=$index && return 0
       let index++
    done
    return 1
}

# Apply a callback to every item in an array and echo new array eval statement.
#
# array_map__callback
#
# The array_map__callback has to be re-defined for each call of array_map and receives the value of an array item as
# it's argument.  The example here expects that user_patterns is an array, already defined.  The array user_patterns is
# mutated by the eval statement at the end.
#
# @code
#   function array_map__callback {
#       echo "<h1>$1</h1>"
#   }
#   declare -a titles=("The Hobbit" "Charlottes Web");
#   eval $(array_map titles)
# @endcode
#
# @param string The VARIABLE NAME of the defined array.
#
# @return nothing.
function array_map() {
    local array_name=$1

    local -a stash=()
    local subject
    function_exists array_map__callback || return 1
    eval subject=(\"\${$array_name[@]}\")
    [[ ${#subject[@]} -eq 0 ]] && return 1
    for item in "${subject[@]}" ; do
        stash=("${stash[@]}" "\"$(array_map__callback "$item")\"")
    done
    echo "$array_name=(${stash[@]})"
}

# Remove duplicate values from an array.
#
# Beware the order of the array will most likely be altered.
#
# @code
#   declare -a duplicated=("blue" "red" "blue" "yellow");
#   eval $(array_dedupe duplicated)
# @endcode
#
# @param string The VARIABLE NAME of the defined array.
#
# @return nothing.
function array_dedupe() {
    local array_name=$1

    eval subject=(\"\${$array_name[@]}\")
    echo "$array_name=($(for i in  "${subject[@]}" ; do  echo "\"$i\"" ; done|sort -u))"
}

# Determine if a function has been defined.
#
# @param string The name of the function to check.
#
# @return 0 if defined; 1 otherwise.
function function_exists() {
    local function_name=$1

    local type=$(eval type $function_name 2>/dev/null)
    [[ "$type" =~ "function" ]] && return 0
    return 1
}

# Split a string by a delimiter.
#
# string_split__string
# string_split__array
#
# @code
#  string_split__string="do<br />re<br />mi"
#  string_split '<br />' && local words=("${string_split__array[@]}")
# @endcode
#
# @param string The delimiter string.
#
# @return 0 if .
function string_split() {
    local delimiter="$1"

    if [ ${#delimiter} -eq 1 ]; then
        IFS=$delimiter; string_split__array=($string_split__string); unset IFS;
    else
        #http://www.linuxquestions.org/questions/programming-9/bash-shell-script-split-array-383848/#post3270796
        string_split__array=(${string_split__string//$delimiter/ })
    fi
}

# Echo $array_csv__array as CSV
#
# @global array $array_csv__array
#
# @option --prose Use comma+space and then the word "all" as the final separator
# as when writing English prose, e.g. "do, re and mi".
# @option --quotes Wrap each item with double quotes.
# @option --single-quotes Wrap each item with single quotes.
#
# @echo The CSV string
#
# @code
#   array_csv__array=('foo bar' 'baz' zulu)
#   csv=$(array_csv)
# @endcode
function array_csv() {
  local csv
  local i=0
  local length=${#array_csv__array[@]}
  parse_args $@
  for item in "${array_csv__array[@]}"; do
    if [[ "$parse_args__options__quotes" ]]; then
      item='"'$item'"'
    elif [[ "$parse_args__options__single_quotes" ]]; then
      item="'$item'"
    fi
    [[ ! "$csv" ]] && csv="$item" && continue
    if [[ "$parse_args__options__prose" ]]; then
      if [ $((i+=1)) -eq $((length-1)) ]; then
        csv="$csv and $item"
      else
        csv="$csv, $item"
      fi
    else
      csv="$csv,$item"
    fi
  done
  echo "$csv"
}

# Echo a string, which is an array joined by a substring.
#
# @global array array_join__array
#
# @param string The string to use to glue the pieces together with.
#
# @return 0 if all goes well.
# @return 1 on failure.
function array_join() {
    local glue="$1"

    local string
    string=$(printf "%s$glue" "${array_join__array[@]}") && string=${string%$glue} || return 1
    echo $string
    return 0
}

# Mutate an array sorting alphabetically.
#
# @global array array_sort__array
#
# @return nothing.
function array_sort() {
    local IFS=$'\n'
    array_sort__array=($(sort <<< "${array_sort__array[*]}"))
}

# Mutate an array sorting by the length of each item, short ot long
#
# @global array array_sort__array
#
# @code
#  array_sort_by_item_length__array=("september" "five" "three" "on")
#  array_sort_by_item_length
# @endcode
#
# # @return 0 if assertion is true.
# @return 1 if assertion failure.
function array_sort_by_item_length() {
    local sorted
    local php_result
    local result

    php_result=$(. "$PHP_FILE_RUNNER" "$CLOUDY_CORE_DIR/php/functions/invoke.php" "array_sort_by_item_length" "sorted" "${array_sort_by_item_length__array[@]}")
    result=$?
    if [[ $result -ne 0 ]]; then
      write_log_error "array_sort_by_item_length failed."
      write_log_error "$php_result"
      return 1
    fi
    eval $php_result
    array_sort_by_item_length__array=("${sorted[@]}")
    return $result
}

# Determine if there are any arguments for the script "command".
#
# @return 0 if the command has any arguments
# @return 1 if not.
function has_command_args() {
    [ ${#CLOUDY_ARGS[@]} -gt 1 ] && return 0
    return 1
}

# Return a operation argument by zero-based index key.
#
# @param int  The index of the argument
# @param mixed Optional, default value.
#
# As an example see the following code:
# @code
#   ./script.sh action blue apple
#   get_command --> "action"
#   get_command_arg 0 --> "blue"
#   get_command_arg 1 --> "apple"
# @endcode
# @return 0 if found
# @return 2 if using the default.
function get_command_arg() {
    local index=$1
    local default="${2}"

    let index=(index + 1)
    [ ${#CLOUDY_ARGS[@]} -gt $index ] && echo  ${CLOUDY_ARGS[$index]} && return 0
    echo $default && return 2
}

# Echo all command arguments
#
# If options are mixed in they will be stripped out, that is to say, if the
# script was called like this "script.sh do -f re -h mi", this function will
# echo "do re mi"
#
# @return 0
function get_command_args() {
  local command_args=("${CLOUDY_ARGS[@]:1}")

  echo "${command_args[@]}" && return 0
}

##
 # Get a config path assignment.
 #
 # You should probably use get_config_as() instead as it's less brittle.
 #
 # @code
 #   eval $(get_config 'path.to.config')
 # @code
 #
 # When requesting an array you must pass -a as the first argument if there's
 # any chance that the return value will be empty.
 #
 # @code
 #   eval $(get_config 'path.to.string' 'default_value')
 #   eval $(get_config -a 'path.to.array' 'default_value')
 # @code
 #
 # @deprecated Since version 2.0.0, Use get_config_as() instead.
 #
function get_config() {
    local config_path=$1
    local default_value=$2

    parse_args "$@"
    local config_path="${parse_args__args[0]}"
    local default_value="${parse_args__args[1]}"
    _cloudy_get_config "$config_path" "$default_value" $parse_args__options_passthru
}

##
 # Get config path but assign it's value to a custom variable.
 #
 # @code
 #   eval $(get_config_as 'title' 'path.to.some.title' 'default')
 #   eval $(get_config_as 'title' -a 'path.to.some.array' )
 # @code
 #
function get_config_as() {
    local custom_var_name=$1
    local config_path=$2
    local default_value=$3

    parse_args "$@"
    local custom_var_name="${parse_args__args[0]}"
    local config_path="${parse_args__args[1]}"
    local default_value="${parse_args__args[2]}"
    _cloudy_get_config "$config_path" "$default_value" --as="$custom_var_name" $parse_args__options_passthru
}

## Echos eval code for the keys of a configuration associative array.
 #
 # @param string The path to the config item, e.g. "files.private"
 #
 # @return 0 on success.
 #
 # @deprecated Since version 2.0.0, Use get_config_keys_as() instead.
 ##
function get_config_keys() {
    local config_key_path="$1"

    _cloudy_get_config -a --keys "$config_key_path"
}

# Echo eval code for keys of a configuration associative array using custom var.
#
# @param string The path to the config item, e.g. "files.private"
#
# @return 0 on success.
function get_config_keys_as() {
    local custom_var_name=$1
    local config_key_path=$2

    parse_args "$@"
    custom_var_name="${parse_args__args[0]}"
    config_key_path="${parse_args__args[1]}"
    _cloudy_get_config -a --keys "$config_key_path" "" --as="$custom_var_name"
}

## Echo eval code for paths of a configuration item.
 #
 # Relative paths are made absolute using $CLOUDY_BASEPATH.
 #
 # @param string The path to the config item, e.g. "files.private"
 # @option -a If you are expecting an array
 #
 # @return 0 on success.
 #
 # @deprecated Since version 2.0.0, Use get_config_path_as() instead.
 ##
function get_config_path() {
    local config_key_path=$1
    local default_value=$2

    parse_args "$@"
    config_key_path="${parse_args__args[0]}"
    local default_value="${parse_args__args[1]}"
    _cloudy_get_config "$config_key_path" "$default_value" --mutator=_cloudy_realpath $parse_args__options_passthru
}

# Echo eval code for paths of a configuration item using custom var.
#
# Relative paths are made absolute using $CLOUDY_BASEPATH.
#
# @param string The variable name to assign the value to.
# @param string The path to the config item, e.g. "files.private"
# @option -a If you are expecting an array
#
# @return 0 on success.
function get_config_path_as() {
    local custom_var_name=$1
    local config_key_path=$2
    local default_value=$3

    parse_args "$@"
    custom_var_name="${parse_args__args[0]}"
    config_key_path="${parse_args__args[1]}"
    default_value="${parse_args__args[2]}"
    _cloudy_get_config "$config_key_path" "$default_value"  --as="$custom_var_name" --mutator=_cloudy_realpath $parse_args__options_passthru
}

# Echo the translation of a message id into $CLOUDY_LANGUAGE.
#
# @param string The untranslated message.
#
# @return 0 if translated
# @return 2 if not translated.
function translate() {
    local untranslated_message="$1"

    # A faster way to response if no translate.
    [ ${#cloudy_config_keys___translate[@]} -eq 0 ] && echo "$untranslated_message" && return 2

    # Look up the index of the translation id...
    eval $(_cloudy_get_config -a --as=ids "translate.ids")
    array_has_value__array=("${ids[@]}")
    ! array_has_value "$untranslated_message" && echo "$untranslated_message" && return 2

    # Look for a string under that index in the current language.
    eval $(_cloudy_get_config --as=translated "translate.strings.$CLOUDY_LANGUAGE.$array_has_value__index")

    # Echo the translate or the original.
    echo ${translated:-$untranslated_message} && return 0
}

# Echo a string with white text.
#
# @param string The string to echo.
#
# @return nothing.
function echo_white() {
    _cloudy_echo_color 37 "$1"
}

# Echo a string with red text.
#
# @param string The string to echo.
#
# @return nothing.
function echo_red() {
    _cloudy_echo_color 31 "$1"
}

# Echo a string with a red background.
#
# @param string The string to echo.
#
# @return nothing.
function echo_red_highlight() {
    _cloudy_echo_color 37 "$1" 1 41
}

# Echo a string with really, really loudly.
#
# @param string The string to echo.
#
# @return nothing.
function echo_scream() {
  local message="$1"

  local length
  local header_length
  length=${#message}
  header_length=$(( $length + 6 ))
  echo_red_highlight "$(string_repeat " " $header_length)"
  echo_red_highlight "$(string_repeat " " 3)$(string_upper "$message")$(string_repeat " " 3)"
  echo_red_highlight "$(string_repeat " " $header_length)"
}

# Echo an error message
#
# @param string The error message.
#
# @return nothing.
function echo_error() {
    _cloudy_echo_color 37 "$1" 1 41
}

# Echo a warning message
#
# @param string The warning message.
#
# @return nothing.
function echo_warning() {
    _cloudy_echo_color 30 "$1" 1 43
}

# Echo a string with green text.
#
# @param string The string to echo.
#
# @return nothing.
function echo_green() {
    _cloudy_echo_color 32 "$1" 0
}

# Echo a string with a green background.
#
# @param string The string to echo.
#
# @return nothing.
function echo_green_highlight() {
  _cloudy_echo_color 37 "$1" 1 42
}

# Echo a message indicating a passed test result.
#
# @param string The message to print
#
function echo_pass() {
  local message=$1
  echo "$(echo_green_highlight '[X]') $(echo_green "$message")"
}

# Echo a message indicating a failed test result.
#
# @param string The message to print
#
function echo_fail() {
  local message=$1
  echo "$(echo_red_highlight '[ ]') $(echo_red "$message")"
}

# Echo a task has started, a.k.a, pending.
#
# This should be followed by echo_task_completed or echo_task_failed.
#
# @param string The imperative, e.g., "Download all files"
#
# @return nothing.
#
# @see echo_task_completed
# @see echo_task_failed
function echo_task() {
  echo_task__task="$1"
  tput sc
  echo "$(echo_blue '[ ]') $(echo_blue "$echo_task__task")"
}

# Call this to erase the last "echo_task".
#
# You may want to do this if the task was aborted and neight completed nor
# failed.  It will erase the task instead of marking a result.
#
# @return nothing.
function clear_task() {
  tput rc && tput sc && echo && tput rc
}

# Replace the task pending with success.
#
# @return nothing.
#
# @see echo_task
# @see echo_task_failed
function echo_task_completed() {
  tput rc && echo_pass "$echo_task__task"
}

# Replace the task pending with failure.
#
# @return nothing.
#
# @see echo_task
# @see echo_task_completed
function echo_task_failed() {
  tput rc && echo_fail "$echo_task__task"
}


# Echo a string with yellow text.
#
# @param string The string to echo.
#
# @return nothing.
function echo_yellow() {
    _cloudy_echo_color 33 "$1" 0
}

# Echo a string with a yellow background.
#
# @param string The string to echo.
#
# @return nothing.
function echo_yellow_highlight() {
    _cloudy_echo_color 30 "$1" 1 43
}

# Echo a string with blue text.
#
# @param string The string to echo.
#
# @return nothing.
function echo_blue() {
    _cloudy_echo_color 34 "$1" 0
}

# Echo a title string.
#
# @param string The title string.
#
# @return nothing.
function echo_title() {
    local headline="$1"
    [[ ! "$headline" ]] && return 1
    echo && echo "🔶  $(string_upper "${headline}")" && echo
}

# Echo a heading string.
#
# @param string The heading string.
#
# @return nothing.
function echo_heading() {
    local headline="$1"
    [[ ! "$headline" ]] && return 1
    echo "🔸  ${headline}"
}

# Remove all items from the list.
#
# @return nothing
function list_clear() {
    echo_list__array=()
}

# Add an item to the list.
#
# @global array echo_list__array
#
# @param string The string to add as a list item.
#
# @return nothing.
function list_add_item() {
    local item="$1"
    echo_list__array=("${echo_list__array[@]}" "$item")
}

# Detect if the list has any items.
#
# @return 0 if the list has at least one item.
function list_has_items() {
    [ ${#echo_list__array[@]} -gt 0 ]
}

##
 # Echo an array as a bulleted list (does not clear list)
 #
 # @param $echo_list__array
 # @echo The list
 #
 # You must add items to your list first:
 # @code
 #   list_add_item "List item"
 #   echo_list
 #   list_clear
 # @endcode
 #
 # @see echo_list__array=("${some_array_to_echo[@]}")
 #
function echo_list() {
    _cloudy_echo_list
}

##
 # @param $echo_list__array
 # @echo The list in red.
 #
function echo_red_list() {
    _cloudy_echo_list 31 31
}

##
 # @param $echo_list__array
 # @echo The list in green.
 #
function echo_green_list() {
    _cloudy_echo_list 32 32 -i=0
}

##
 # @param $echo_list__array
 # @echo The list in yellow.
 #
function echo_yellow_list() {
    _cloudy_echo_list 33 33 i=0
}

##
 # @param $echo_list__array
 # @echo The list in blue.
 #
function echo_blue_list() {
    _cloudy_echo_list 34 34 -i=0
}

# Echo the elapsed time since the beginning of the script.
#
# @global int $SECONDS
#
# @echo The elapsed time.
# @return nothing.
function echo_elapsed() {
  if [[ $SECONDS -lt 61 ]]; then
    printf "%d sec\n" $SECONDS
  elif [[ $SECONDS -lt 3601 ]]; then
    ((m=($SECONDS%3600)/60))
    ((s=$SECONDS%60))
    printf "%d min %d sec\n" $m $s
  else
    ((h=$SECONDS/3600))
    ((m=($SECONDS%3600)/60))
    ((s=$SECONDS%60))

    hword="hours"
    if [[ $h -eq 1 ]]; then
      hword="hour"
    fi

    mword="minutes"
    if [[ $m -eq 1 ]]; then
      mword="minute"
    fi

    sword="seconds"
    if [[ $m -eq 1 ]]; then
      sword="second"
    fi

    printf "%d %s %d %s %d %s\n" $h $hword $m $mword $s $sword
  fi
}

#
# SECTION: Ending the script.
#
# @link https://www.tldp.org/LDP/abs/html/exit-status.html
#

##
 # Implement cloudy common commands and options.
 #
 # An optional set of commands for all scripts.  This is just the handlers,
 # you must still set up the commands in the config file as usual.
 #
function implement_cloudy_basic() {

    # Handle options on any command.
    has_option "h" && exit_with_help $command

    # Handle certain commands.
    case $(get_command) in

        "help")
            exit_with_help $(get_command_arg 0)
            ;;

        "clear-cache")
            exit_with_cache_clear
            ;;

    esac
}

##
 # Run the Init API for a package.
 #
 # You must set up an init command in your core config file.
 # Then call this function from inside `on_boot`, e.g.
 # @code
 # [[ "$(get_command)" == "init" ]] && handle_init
 # ...do your extra work here...
 # exit_with...
 # @endcode
 #
 # You should only call this function if you need to do something additional in
 # your init step, where you don't want to exit.  If not, you should use
 # exit_with_init, instead.
 #
 # The translation service is not yet bootstrapped in on_pre_config, so if you
 # want to alter the strings printed you can do something like this:
 # @code
 # if [[ "$(get_command)" == "init" ]]; then
 #     CLOUDY_FAILED="Initialization failed."
 #     CLOUDY_SUCCESS="Initialization complete."
 #     exit_with_init
 # fi
 # @endcode
 #
 # @global string $CLOUDY_INIT_RULES
 #
 # @return 1 If $CLOUDY_BASEPATH is empty or does not exist
 # @return 2 If $CLOUDY_INIT_RULES is empty.
 # @return 3 If $CLOUDY_INIT_RULES does not exist.
 # @return 5 If a legacy (unsupported) token is used.
 # @return 6 If any file copy failes; see log for more info.
 ##
function handle_init() {
  ([[ ! "$CLOUDY_BASEPATH" ]] || [ ! -d "$CLOUDY_BASEPATH" ]) && fail_because "\$CLOUDY_BASEPATH must be set before you can initialize" && return 1
  ! [[ "$CLOUDY_INIT_RULES" ]] && fail_because "\$CLOUDY_INIT_RULES is empty" && return 2
  ! [ -f "$CLOUDY_INIT_RULES" ] && fail_because "Missing required initialization file: $CLOUDY_INIT_RULES." && return 3

  # Check for legacy code usage, and suggest upgrade. @see changelog for version 2.0.0
  # TODO Move this to review_code...
  grep \${config_path_base} "$CLOUDY_INIT_RULES" > /dev/null
  if [[ $? -eq 0 ]]; then
    fail_because "The token \"{APP_ROOT}\" must be used; \"\${config_path_base}\" is no longer supported; in $CLOUDY_INIT_RULES" && return 5
  fi
  . "$PHP_FILE_RUNNER" "$CLOUDY_CORE_DIR/php/functions/handle_init.php" "$CLOUDY_INIT_RULES"

  if has_failed; then
    list_clear
    for reason in "${CLOUDY_FAILURES[@]}" ; do
      write_log_error "$reason"
      list_add_item "$reason"
    done
    echo_red_highlight "Some problems occurred"
    echo_red_list
    return 6
  fi

  return 0
}

# Performs an initialization (setup default config, etc.) and exits.
#
# You must set up an init command in your core config file.
# Then call this function from inside `on_boot`, e.g.
# [[ "$(get_command)" == "init" ]] && exit_with_init
# The translation service is not yet bootstrapped in on_pre_config, so if you
# want to alter the strings printed you can do something like this:
# @code
# if [[ "$(get_command)" == "init" ]]; then
#     CLOUDY_FAILED="Initialization failed."
#     CLOUDY_SUCCESS="Initialization complete."
#     exit_with_init
# fi
# @endcode
#
# @return nothing.
function exit_with_init() {
    handle_init || exit_with_failure "${CLOUDY_FAILED:-Initialization failed.}"
    exit_with_success "${CLOUDY_SUCCESS:-Initialization complete.}"
}

##
 # Empties caches in $CLOUDY_CORE_DIR (or other directory if provided) and exits.
 #
 # @return nothing.
 #
function exit_with_cache_clear() {
    local _clear
    local _stash
    event_dispatch "clear_cache" "$CLOUDY_CACHE_DIR" || exit_with_failure "Clearing caches failed."
    if dir_has_files "$CLOUDY_CACHE_DIR"; then

        # We should not delete cpm on general cache clear.
        if [ -d "$CLOUDY_CACHE_DIR/cpm" ]; then
            _stash=$(tempdir)
            mv "$CLOUDY_CACHE_DIR/cpm" "$_stash/cpm"
        fi
        _clear=$(rm -rv "$CLOUDY_CACHE_DIR/"*)
        status=$?
        if [[ "$_stash" ]]; then
            mv "$_stash/cpm" "$CLOUDY_CACHE_DIR/cpm"
        fi

        [ $status -eq 0 ] || exit_with_failure "Could not remove all cached files in $CLOUDY_CACHE_DIR"
        file_list=($_clear)
        for filepath in "${file_list[@]}"; do
           succeed_because "$(path_make_relative "$filepath" "$CLOUDY_CACHE_DIR")"
        done
        exit_with_success "Caches have been cleared."
    fi
    exit_with_success "Caches are clear."
}

# Echo the help screen and exit.
#
# @return 0 on success
# @return 1 otherwise.
function exit_with_help() {
    local help_command=$(_cloudy_get_master_command "$1")

    ## Print out the version string only.
    if has_option "version"; then
      echo $(get_version) && exit_with_success_code_only
    fi

    # Focused help_command, show info about single command.
    if [[ "$help_command" ]]; then
        _cloudy_validate_command $help_command || exit_with_failure "No help for that!"
        _cloudy_help_for_single_command $help_command
        exit_with_success "Use just \"help\" to list all commands"
    fi

    # Top-level just show all commands.
    _cloudy_help_commands
    exit_with_success "Use \"help <command>\" for specific info"
}

# Echo a success message plus success reasons and exit
#
# @param string The success message to use.
#
# @return 0.
function exit_with_success() {
    local message=$1

    # At this point the output can be hijacked by an event handler, for example
    # if the event handler wants to output JSON or some other encoding.
    event_dispatch "exit_with_success"

    _cloudy_exit_with_success "$(_cloudy_message "$message" "$CLOUDY_SUCCESS")"
}

# Exit without echoing anything with a 0 status code.
#
# @return nothing.
function exit_with_success_code_only() {
    CLOUDY_EXIT_STATUS=0 && _cloudy_exit
}

# Echo a success message (with elapsed time) plus success reasons and exit
#
# @param string The success message to use.
#
# @return 0.
function exit_with_success_elapsed() {
    local message=$1
    local duration=$SECONDS

    _cloudy_exit_with_success "$(_cloudy_message "$message" "$CLOUDY_SUCCESS" " in $(echo_elapsed).")"
}

# Add a warning message to be shown on success exit; not shown on failure exits.
#
# @param string The warning message.
# @param string A default value if $1 is empty.
#
# @code
#   warn_because "$reason" "Some default if $reason is empty"
# @endcode
#
# @todo Should this show if a failure exit?
#
# @return 1 if both $message and $default are empty; 0 if successful.
function warn_because() {
    local message="$1"
    local default="$2"

    [[ "$message" ]] || [[ "$default" ]] || return 0
    [[ "$message" ]] && CLOUDY_SUCCESSES=("${CLOUDY_SUCCESSES[@]}" "$(echo_yellow "$message")")
    [[ "$default" ]] && CLOUDY_SUCCESSES=("${CLOUDY_SUCCESSES[@]}" "$(echo_yellow "$default")")
    return 0
}

# Add a success reason to be shown on exit.
#
# @param string The reason for the success.
# @param string A default value if $1 is empty.
#
# @code
#   succeed_because "$reason" "Some default if $reason is empty"
# @endcode
#
# @return 1 if both $message and $default are empty; 0 if successful.
function succeed_because() {
    local message="$1"
    local default="$2"

    CLOUDY_EXIT_STATUS=0
    [[ "$message" ]] || [[ "$default" ]] || return 0
    [[ "$message" ]] && CLOUDY_SUCCESSES=("${CLOUDY_SUCCESSES[@]}" "$message")
    [[ "$default" ]] && CLOUDY_SUCCESSES=("${CLOUDY_SUCCESSES[@]}" "$default")
    return 0
}

# Checks if a variable has been evaluated into memory and points to an existing path.
#
# @param string The alias.  Or if not aliased, the config path used by `get_config`.
# @param string (Optional) The config path, if aliased.
# @option as=name - @deprecated
#
# Both of these aliase examples are the same, though the --as is an older syntax
# that has been deprecated.
#
# @code
#   exit_with_failure_if_empty_config 'database.host'
#
#   ## Using an alias...
#   exit_with_failure_if_empty_config 'host' 'database.host'
#
#   ## Aliased, deprecated syntax.
#   exit_with_failure_if_empty_config 'database.host' --as=host
# @endcode
#
# @return 0 if the variable exists and points to a file; exits otherwise with 1.
function exit_with_failure_if_config_is_not_path() {
    local alias=$1
    local config_path=$2

    parse_args "$@"
    if [ ${#parse_args__args[@]} -eq 1 ]; then
      alias=''
      config_path=$1
      if [[ "$parse_args__options__as" ]]; then
        alias="$parse_args__options__as"
        config_path="$1"
      fi
    else
      alias=$1
      config_path=$2
    fi

    if [[ "$parse_args__options__status" ]]; then
      CLOUDY_EXIT_STATUS=$parse_args__options__status
    fi

    if [[ "$alias" ]]; then
      value="$(eval "echo \$$alias")"
    else
      value="$(eval "echo \$${config_path//./_}")"
    fi

    exit_with_failure_if_empty_config $@

    # Make sure it's a path.
    [ ! -e "$value" ] && exit_with_failure "Failed because the path \"$value\" , does not exist; defined in configuration as $config_path."

    return 0
}

# Checks if a variable has been evaluated into memory yet or exits with failure.
#
# @param string The alias.  Or if not aliased, the config path used by `get_config`.
# @param string (Optional) The config path, if aliased.
# @option as=name - @deprecated
#
# Both of these aliase examples are the same, though the --as is an older syntax
# that has been deprecated.
#
# @code
#   exit_with_failure_if_empty_config 'database.host'
#
#   ## Using an alias...
#   exit_with_failure_if_empty_config 'host' 'database.host'
#
#   ## Aliased, deprecated syntax.
#   exit_with_failure_if_empty_config 'database.host' --as=host
# @endcode
#
# @return 0 if the variable is in memory.
function exit_with_failure_if_empty_config() {
    local alias=$1
    local config_path=$2

    parse_args "$@"
    if [ ${#parse_args__args[@]} -eq 1 ]; then
      alias=''
      config_path=$1
      if [[ "$parse_args__options__as" ]]; then
        alias="$parse_args__options__as"
        config_path="$1"
      fi
    else
      alias=$1
      config_path=$2
    fi

    if [[ "$parse_args__options__status" ]]; then
      CLOUDY_EXIT_STATUS=$parse_args__options__status
    fi

    local code
    local value
    local error

    if [[ "$alias" ]]; then
      code="eval \$(get_config_as \"$alias\" \"$config_path\")"
      error="\"$config_path\" as \"$alias\""
      value="$(eval "echo \$$alias")"
    else
      code="eval \$(get_config \"$config_path\")"
      error="\"$config_path\""
      value="$(eval "echo \$${config_path//./_}")"
    fi

    if [[ ! "$value" ]]; then
      write_log_error "Missing configuration value.  Trying to use $error. Has it been set in config? Is it being read into memory? e.g. $code"
      exit_with_failure "Failed due to missing configuration; please add \"$config_path\"."
    fi

    return 0
}

##
 # @option --status=N Optional, set the exit status, a number > 0
 #
function exit_with_failure() {
    parse_args "$@"

    local exit_message
    exit_message="$(_cloudy_message "${parse_args__args[@]}" "$CLOUDY_FAILED")"
    if [[ "$exit_message" != "$CLOUDY_FAILED" ]]; then
      write_log_emergency "$exit_message";
    fi

    [[ $CLOUDY_EXIT_STATUS -lt 2 ]] && CLOUDY_EXIT_STATUS=1
    CLOUDY_EXIT_STATUS=${parse_args__options__status:-$CLOUDY_EXIT_STATUS}

    # At this point the output can be hijacked by an event handler, for example
    # if the event handler wants to output JSON or some other encoding.
    event_dispatch "exit_with_failure"

    echo && echo_error "🔥 $exit_message"

    if [[ "$CLOUDY_LOG" ]]; then
      CLOUDY_FAILURES=("${CLOUDY_FAILURES[@]}" "More info: $CLOUDY_LOG")
    fi

    ## Write out the failure messages if any.
    if [ ${#CLOUDY_FAILURES[@]} -gt 0 ]; then
        echo_list__array=("${CLOUDY_FAILURES[@]}")
        echo_red_list
        for i in "${CLOUDY_FAILURES[@]}"; do
           write_log_error "Failed because: $i"
        done
    fi

    echo

    _cloudy_exit
}

# Exit without echoing anything with a non-success code.
#
# @option --status=N Optional, set the exit status, a number > 0
#
# @return nothing.
function exit_with_failure_code_only() {
    parse_args "$@"

    [[ $CLOUDY_EXIT_STATUS -lt 2 ]] && CLOUDY_EXIT_STATUS=1
    CLOUDY_EXIT_STATUS=${parse_args__options__status:-$CLOUDY_EXIT_STATUS}

    ## Write out the failure messages if any.
    if [ ${#CLOUDY_FAILURES[@]} -gt 0 ]; then
        for i in "${CLOUDY_FAILURES[@]}"; do
           write_log_error "Failed because: $i"
        done
    fi

    _cloudy_exit
}

# Test if a program is installed on the system.
#
# @param string The name of the program to check for.
#
# @return 0 if installed; 1 otherwise.
function is_installed() {
    local command=$1

    get_installed $command > /dev/null
    return $?
}

# Echo the path to an installed program.
#
# @param string The name of the program you need.
#
# @return 0 if .
function get_installed() {
    local command=$1

    command -v $command 2>/dev/null
}

##
 # Set the exit status to fail with no message.  Does not stop execution.
 #
 # Try not to use this because it gives no indication as to why
 #
 # @option --status=N Optional, set the exit status, a number > 0
 #
 # @see exit_with_failure
 #
function fail() {
    parse_args "$@"
    if [[ "$parse_args__options__status" ]]; then
      CLOUDY_EXIT_STATUS=$parse_args__options__status && return 0
    fi
    CLOUDY_EXIT_STATUS=1 && return 0
}

## Add a failure message to be shown on exit.
 #
 # @param string The reason for the failure.
 # @param string A default value if $1 is empty.
 #
 # @code
 #   fail_because "$message" "Some default if \$message is empty"
 # @endcode
 #
 # @return 1 if both $message and $default are empty. 0 otherwise.
 ##
function fail_because() {
    local message="$1"
    local default="$2"

    parse_args "$@"
    message="${parse_args__args[0]}"
    default="${parse_args__args[1]}"
    fail $@

    [[ "$message" ]] || [[ "$default" ]] || return 0
    [[ "$message" ]] && CLOUDY_FAILURES=("${CLOUDY_FAILURES[@]}" "$message")
    [[ "$default" ]] && CLOUDY_FAILURES=("${CLOUDY_FAILURES[@]}" "$default")
    return 0
}

# Determine if any failure reasons have been defined yet.
#
# @return 0 if one or more failure messages are present; 1 if not.
function has_failed() {
    [[ $CLOUDY_EXIT_STATUS -gt 0 ]] && return 0
    return 1
}

##
 # Echo the host portion an URL.
 #
function url_host() {
    local url_path="$1"
    echo "$url_path" | awk -F/ '{print $3}'
}

##
 # Add a cache-busting timestamp to an URL and echo the new url.
 #
function url_add_cache_buster() {
    local url="$1"

    if [[ $url == *"?"* ]]; then
        url="$url&$(date +%s)"
    else
        url="$url?$(date +%s)"
    fi
    echo $url
}

##
 # Dispatch that an event has occurred to all listeners.
 #
 # Additional arguments beyond $1 are passed on to the listeners.
 #
function event_dispatch() {
    local event_id=$1

    # Protect us from recursion.
    if [[ "$event_dispatch__event" ]] && [[ "$event_dispatch__event" == "$event_id" ]]; then
        write_log_error "Tried to dispatch $event_id while currently dispatching $event_id."
        return
    fi
    event_dispatch__event=$event_id
    write_log_info "Dispatching event: $event_id"

    shift
    local args
    local varname="_cloudy_event_listen__${event_id}__array"
    local listeners=$(eval "echo "\$$varname"")
    local has_on_event=false

    for value in "${listeners[@]}"; do
       [[ "$value" == "on_${event_id}" ]] && has_on_event=true && break
    done
    [[ "$has_on_event" == false ]] && listeners=("${listeners[@]}" "on_${event_id}")

    for listener in ${listeners[@]}; do
        _cloudy_trigger_event "$event_id" "$listener" "$@"
    done
    unset event_dispatch__event
}

##
 # Register an event listener.
 #
 # @param string The event id, e.g. "boot"
 # @param string The function name to call on the event.
 #
function event_listen() {
    local event_id="$1"
    local callback="${2:-on_$1}"

    local varname="_cloudy_event_listen__${event_id}__array"
    local listeners=$(eval "echo "\$$varname"")

    # Prevent multiple listeners of the same name.
    for value in "${listeners[@]}"; do
       [[ "$value" == "$callback" ]] && throw "Listener $callback has already been added; you must provide a different function name;$0;$FUNCNAME;$LINENO"
    done

    eval "$varname=(\"\${$varname[@]}\" $callback)"
}

#
# Filepaths
#

# Determine if a path is absolute (begins with /) or not.
#
# @param string The filepath to check
#
# @return 0 if absolute; 1 otherwise.
function path_is_absolute() {
    local path="$1"

    [[ "${path:0:1}" == '/' ]]
}

##
 # Check if a filepath is a YAML file.
 #
 # @param string Path to file in question.
 #
 # @return 0 If it is.
 # @return 1 If it is not a YAML file.
 ##
function path_is_yaml() {
  local path="$1"

  extension=$(path_extension "$path")
  [[ "$extension" == 'yml' ]] || [[ "$extension" == 'yaml' ]] || [[ "$extension" == 'YML' ]] || [[ "$extension" == 'YAML' ]]
}

# Echo the size of a file.
#
# @param string The path to the file.
function path_filesize() {
  local path="$1"

  stat -f%z "$path"
}

# Echo the last modified time of a file.
#
# @param string The path to the the file.
#
# @return 1 if the time cannot be determined.
function path_mtime() {
    local path=$1
    [ -f "$path" ] || return 1

     date -r "$path" +%s
}

##
 # Return the basename less the extension.
 #
function path_filename() {
    local path=$1

    filename=$(basename "$path")
    echo "${filename%.*}"
}

##
 # Return the extension of a file.
 #
function path_extension() {
    local path=$1

    local extension="${path##*.}"
    if [[ "$extension" == "$path" ]]; then
      extension=""
    fi
    echo "$extension"
}

# Echo a temporary directory filepath.
#
# If you do not provide $1 then a new temporary directory is created each time
# you call tempdir.  If you do provide $1 and call tempdir more than once with
# the same value for $1, the same directory will be returned each time--a shared
# directory within the system's temporary filesystem with the name passed as $1.
# It is a common pattern to pass $CLOUDY_NAME as the argument as this will
# create a folder based on the name of your script.
#
# @param string An optional directory name to use.
#
# @return 0 if successful
function tempdir() {
    local basename=${1}

    local path=$(mktemp -d 2>/dev/null || mktemp -d -t 'temp')
    [[ ! "$basename" ]] && echo $path && return 1
    local final="$(dirname $path)/$basename"
    [[ -d $final ]] && ! rmdir $path && return 1
    [[ ! -d $final ]] && ! mv $path $final && return 1
    echo $final && return 0
}

# Echo the uppercase version of a string.
#
# @param string The string to convert to uppercase.
#
# @return nothing.
function string_upper() {
    local string="$1"

    echo "$string" | tr [:lower:] [:upper:]
}

# Echo the string with it's first letter in uppercase.
#
# @param string The string to convert
# @echo The string with upper case first letter
# @return nothing.
function string_ucfirst() {
    local string="$1"

    echo "$(echo "${string:0:1}" | tr [:lower:] [:upper:])${string:1}"
}

# Echo the lowercase version of a string.
#
# @param string The string to convert to lowercase.
# @echo The lowercased string
# @return nothing.
function string_lower() {
    local string="$1"

    echo "$string" | tr [:upper:] [:lower:]
}

#
# Development
#

##
 # Echo the arguments sent to this is an eye-catching manner.
 #
 # Call as in the example below for better tracing.
 # @code
 #   debug "Some message to show|$0|$FUNCNAME|$LINENO"
 # @endcode
 #
function debug() {
    _cloudy_debug_helper "Debug;3;0;$@"
}

# $DESCRIPTION
#
# @param string $PARAM$
#
# @return 0 if $END$.
function echo_key_value() {
    local key=$1
    local value=$2
    echo "$(tty -s && tput setaf 0)$(tty -s && tput setab 7) $key $(tty -s && tput smso) "$value" $(tty -s && tput sgr0)"
}

# Echo an exception message and exit.
#
# @return 3.
function throw() {
    _cloudy_debug_helper "Exception;1;7;$@"
    exit 3
}

# Echo a message to the user to either enable and repeat, or view log for info.
#
# @param string Path to the logfile; usually you send $CLOUDY_LOG, which is the global path.
#
# @code
# fail_because "$(echo_see_log $CLOUDY_LOG)"
# @endcode
#
# @return nothing.
function echo_see_log() {
  local logfile="$1"

  if [[ ! "$logfile" ]]; then
    echo "For details enable logging and try again."
  else
    echo "See log for details: $logfile"
  fi
}

##
 # You may include 1 or two arguments; when 2, the first is a log label
 #
function write_log() {
    local args=("$@")

    if [ $# -eq 1 ]; then
        args=("log" "${args[@]}")
    fi
    _cloudy_write_log ${args[@]}
}

##
 # @link https://www.php-fig.org/psr/psr-3/
 #
function write_log_emergency() {
    local args=("emergency" "$@")
    _cloudy_write_log ${args[@]}
}

# Writes a log message using the alert level.
#
# $@ - Any number of strings to write to the log.
#
# @return 0 on success or 1 if the log cannot be written to.
function write_log_alert() {
    local args=("alert" "$@")
    _cloudy_write_log ${args[@]}
}

# Write to the log with level critical.
#
# @param string The message to write.
#
# @return 0 on success.
function write_log_critical() {
    local args=("critical" "$@")
    _cloudy_write_log ${args[@]}
}

# Write to the log with level error.
#
# @param string The message to write.
#
# @return 0 on success.
function write_log_error() {
    local args=("error" "$@")
    _cloudy_write_log ${args[@]}
}

# Write to the log with level warning.
#
# @param string The message to write.
#
# @return 0 on success.
function write_log_warning() {
    local args=("warning" "$@")
    _cloudy_write_log ${args[@]}
}

##
 # Log states that should only be thus during development or debugging.
 #
 # Adds a "... in dev only message to your warning"
 #
function write_log_dev_warning() {
    local args=("warning" "$@")
    _cloudy_write_log "${args[@]}  This should only be the case for development/debugging."
}

# Write to the log with level notice.
#
# @param string The message to write.
#
# @return 0 on success.
function write_log_notice() {
    local args=("notice" "$@")
    _cloudy_write_log ${args[@]}
}

# Write to the log with level info.
#
# @param string The message to write.
#
# @return 0 on success.
function write_log_info() {
    local args=("info" "$@")
    _cloudy_write_log ${args[@]}
}

# Write to the log with level debug.
#
# @param string The message to write.
#
# @return 0 on success.
function write_log_debug() {
    local args=("debug" "$@")
    _cloudy_write_log ${args[@]}
}

# Set the column headers for a table.
#
# $@ - Each argument is the column header value.
#
# @return nothing.
function table_set_header() {
    _cloudy_table_header=()
    local i=0
    local cell
    for cell in "$@"; do
        if [[ ${#cell} -gt "${_cloudy_table_col_widths[$i]}" ]]; then
            _cloudy_table_col_widths[$i]=${#cell}
        fi
        _cloudy_table_header=("${_cloudy_table_header[@]}" "$cell")
        let i++
    done
}

# Manually set the column widths
#
# A number for each column.  You should call this after adding all rows.
#
# @return nothing.
function table_set_column_widths() {
  local i=0
  for width in "$@"; do
    _cloudy_table_col_widths[$i]=$width
    let i++
  done
}

# Clear all rows from the table definition.
#
# @return nothing.
function table_clear() {
    _cloudy_table_rows=()
}

# Determine if the table definition has any rows.
#
# @return 0 if one or more rows in the definition; 1 if table is empty.
function table_has_rows() {
    [ ${#_cloudy_table_rows[@]} -gt 0 ]
}

##
 # Send any number of arguments, each is a column value for a single row.
 #
function table_add_row() {
    array_join__array=()
    local i=0
    local cell
    for cell in "$@"; do
        if [[ ${#cell} -gt "${_cloudy_table_col_widths[$i]}" ]]; then
            _cloudy_table_col_widths[$i]=${#cell}
        fi
        array_join__array=("${array_join__array[@]}" "$cell")
        let i++
    done

    _cloudy_table_rows=("${_cloudy_table_rows[@]}" "$(array_join '|')")
}

# Repeat a string N times.
#
# @param string The string to repeat.
# @param int The number of repetitions.
#
# @return nothing.
function string_repeat() {
    local string="$1"
    local repetitions=$2
    for ((i=0; i < $repetitions; i++)){ echo -n "$string"; }
}

# Echo a slim version of the table as it's been defined.
#
# @return nothing.
function echo_slim_table() {
    _cloudy_echo_aligned_columns --lpad=1 --top="" --lborder="" --mborder=":" --rborder=""
}

# Echo the table as it's been defined.
#
# @return nothing.
function echo_table() {
    _cloudy_echo_aligned_columns --lpad=1 --top="-" --lborder="|" --mborder="|" --rborder="|"
}

# Empties the YAML string from earlier builds, making ready anew.
#
# @return 0.
function yaml_clear() {
  yaml_content=''
  return 0
}

# Add a line to our YAML data.
#
# @param string A complete line with proper indents.
#
# @return 0.
function yaml_add_line() {
  local line="$1"

  if [[ ! "$yaml_content" ]]; then
    yaml_content=$(printf '%s\n' "$line")
  else
    yaml_content=$(printf '%s\n' "$yaml_content" "$line")
  fi

  return 0
}

yaml_content=''
# Sets the value of the YAML string.
#
# You can use this to convert YAML to JSON:
#   yaml_set "$yaml"
#   json=$(yaml_get_json)
#
# @param string The YAML value to set.
#
# @return 0
function yaml_set() {
  yaml_content="$1"
  return 0
}

# Echos the YAML string as YAML.
#
# @return 0
function yaml_get() {
  echo "$yaml_content"
}

# Echos the YAML string as JSON.
#
# @return 0
function yaml_get_json() {
  local json

  json=$(. "$PHP_FILE_RUNNER" "$CLOUDY_CORE_DIR/php/functions/invoke.php" "yaml_to_json" "$yaml_content")
  if [[ $? -ne 0 ]]; then
    write_log_error "yaml_get_json \"$yaml\" failed against YAML: $yaml_content"
    write_log_error "$json"
    return 1
  fi
  echo "$json"
}

##
 # Get a new UUID
 #
 # @echo A new UUID
 #
function create_uuid() {
  echo $(uuidgen)
}

##
 # Remove leading whitespace from string.
 #
 # @param string
 # @echo The left trimmed string
 ##
function ltrim() {
  local line="$1"
  echo "${line#"${line%%[![:space:]]*}"}"
}

##
 # Remove trailing whitespace from string.
 #
 # @param string
 # @echo The right trimmed string
 ##
function rtrim() {
  local line="$1"
  echo "${line%"${line##*[![:space:]]}"}"
}

##
 # Echo a string after removing leading and trailing quotes, as per YAML string.
 #
 # @param string
 #
 # @echo The string with the first and last single/double quote(s) removed.
 ##
function trim_quotes() {
    local string=$1

    string=${string#\'}
    string=${string#\"}
    string=${string%\'}
    string=${string%\"}

    echo "$string"
}

##
 # Take an absolute path and make it relative to a parent path if possible.
 #
 # @param string The absolute path.
 # @param string The absolute PARENT path.
 #
 # @echo The relative path if it worked; the original relative path if it didn't.
 # @return 0 If the path could be make relative.
 # @return 1 If there was a problem creating a relative path.

 # @code
 # result="$(path_make_relative '/some/great/path/bush.md' '/some/great')"
 # [ $? -eq 0 ] && made_relative=true || made_relative=false
 # @endcode
 ##
function path_make_relative() {
  local path="${1%%/}"
  local parent="${2%%/}"

  [[ "$path" == "$parent" ]] && echo '.' && return 0

  parent="$parent/"
  [[ "$path" != "$parent"* ]] && return 1
  path="${path#$parent}"
  if [ -e "$parent/$path" ]; then
    path="$(realpath "$parent/$path")"
    path="${path#$parent}"
  fi
  echo "${path%%/}"
  return 0
}

##
 # Take an relative path and make it absolute to a parent.
 #
 # @param string The relative path.
 # @param string The absolute PARENT path.
 #
 # @echo The absolute path if it worked, otherwise nothing.
 # @return 0 If the path could be make absolute.
 # @return 1 If $1 is not relative.
 # @return 2 If $2 is not absolute.
 # @return 3 If $1 is empty
 #
 # @code
 # # Use this pattern to only change path if it was able to be made absolute.
 # a=$(path_make_absolute "$path" "$absolute_prefix") && path="$a"
 # @endcode
 ##
function path_make_absolute() {
  local path="$1"
  local parent="$2"

  [[ ! "$path" ]] && return 3
  path_is_absolute "$path" && return 1
  ! path_is_absolute "$parent" && return 2
  path="${parent%%/}/${path%%/}"
  [ -e "$path" ] && echo "$(realpath "$path")" || echo "$path"
  return 0
}

##
 # Make a path output without leading $PWD if possible.
 #
 # Use this function when printing paths to the user as it will make paths
 # relative to the current working directory, shortening them, making them
 # "pretty".
 # @param string The path to possible shorten.
 #
 # @echo The original path or the relative to $PWD if possible
 # @return 0
 ##
function path_make_pretty() {
  local path="$1"

  p="$(path_make_relative "$path" "$PWD")" && path="$p"
  ! path_is_absolute "$path" && [[ "$path" != "." ]] && path="./$path"
  echo $path
  return 0
}

##
 # Remove dots but not symlinks from a path.
 #
 # @see realpath if you want to resolve symlinks.
 #
 # @param string The absolute path to make canonical.
 #
 # @echo The canonical path with symbolic links removed.
 # @return 0 If all is well
 # @return 1 If $1 does not exist.
 # @return 2 If $1 is empty.
 # @return 3 If $1 is not absolute.
 ##
function path_make_canonical() {
  local path="$1"

  [[ ! "$path" ]] && return 2
  ! path_is_absolute "$path" && return 3
  [[ ! -e "$path" ]] && return 1

  local _basename
  if [[ ! -d "$path" ]]; then
    _basename="$(basename "$path")"
    path="$(dirname "$path")"
  fi
  path="$(cd "$path"; pwd -L)"
  [[ "$_basename" ]] &&  path="${path%%/}/$_basename" || path="${path%%/}"
  echo "$path"
}

##
 # Replace path tokens with runtime values.
 #
 # @global string $CLOUDY_BASEPATH
 # @global string $CLOUDY_CORE_DIR
 # @global string $CLOUDY_PACKAGE_ID
 # @global string $HOME
 #
 # @param string The path containing one or more tokens
 #
 # @echo The path with values in place of tokens.
 ##
function path_resolve_tokens() {
  local path="$1"

  path="${path//\$CLOUDY_PACKAGE_ID/$CLOUDY_PACKAGE_ID}"
  path="${path//\$CLOUDY_BASEPATH/$CLOUDY_BASEPATH}"
  path="${path//\$CLOUDY_CORE_DIR/$CLOUDY_CORE_DIR}"
  path="${path/#\~\//$HOME/}"
  echo "$path"
}
