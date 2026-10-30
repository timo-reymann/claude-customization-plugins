#!/usr/bin/env bash
# Claude Code setup for the claude-customization-plugins marketplace.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/timo-reymann/claude-customization-plugins/main/setup.sh)
set -eo pipefail

###############################################################################
#                                                                             #
# Bash TUI Toolkit                                                            #
# by Timo Reymann                                                             #
#                                                                             #
# version: 1.10.3                                                             #
# bundle:  bundle                                                             #
# github:  https://github.com/timo-reymann/bash-tui-toolkit                   #
#                                                                             #
# --------------------------------------------------------------------------- #
#                                                                             #
# Copyright (C) 2023 Timo Reymann (mail@timo-reymann.de)                      #
#                                                                             #
# Licensed under the Apache License, Version 2.0 (the "License");             #
# you may not use this file except in compliance with the License.            #
# You may obtain a copy of the License at                                     #
#                                                                             #
#         http://www.apache.org/licenses/LICENSE-2.0                          #
#                                                                             #
# Unless required by applicable law or agreed to in writing, software         #
# distributed under the License is distributed on an "AS IS" BASIS,           #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    #
# See the License for the specific language governing permissions and         #
# limitations under the License.                                              #
#                                                                             #
###############################################################################
_read_stdin() {
    read $@ </dev/tty
}
_get_cursor_row() {
    local IFS=';'
    _read_stdin -sdR -p $'\E[6n' ROW COL
    echo "${ROW#*[}"
}
_cursor_blink_on() { echo -en "\033[?25h" >&2; }
_cursor_blink_off() { echo -en "\033[?25l" >&2; }
_cursor_to() { echo -en "\033[$1;$2H" >&2; }
_key_input() {
    local ESC=$'\033'
    local IFS=''
    _read_stdin -rsn1 a
    if [[ "$ESC" == "$a" ]]; then
        _read_stdin -rsn2 b
    fi
    local input="${a}${b}"
    case "$input" in
        "$ESC[A" | "${ESC}OA" | "k") echo up ;;
        "$ESC[B" | "${ESC}OB" | "j") echo down ;;
        "$ESC[C" | "${ESC}OC" | "l") echo right ;;
        "$ESC[D" | "${ESC}OD" | "h") echo left ;;
        '') echo enter ;;
        ' ') echo space ;;
    esac
}
_new_line_foreach_item() {
    count=0
    while [[ $count -lt $1  ]]; do
        echo "" >&2
        ((count++))
    done
}
_prompt_text() {
    echo -en "\033[32m?\033[0m\033[1m ${1}\033[0m " >&2
}
_decrement_selected() {
    local selected=$1
    ((selected--))
    if [ "${selected}" -lt 0 ]; then
        selected=$(($2 - 1))
    fi
    echo -n $selected
}
_increment_selected() {
    local selected=$1
    ((selected++))
    if [ "${selected}" -ge "${opts_count}" ]; then
        selected=0
    fi
    echo -n $selected
}
input() {
    _prompt_text "$1"
                       echo -en "\033[36m\c" >&2
    _read_stdin -r text
    echo -n "${text}"
}
confirm() {
    trap "_cursor_blink_on; stty echo; exit" 2
    _cursor_blink_off
    _prompt_text "$1 (y/N)"
    echo -en "\033[36m\c " >&2
    local start_row
                     start_row=$(_get_cursor_row)
    local current_row
                       current_row=$((start_row - 1))
    local result=""
    echo -n " " >&2
    while true; do
        echo -e "\033[1D\c " >&2
        _read_stdin -n1 result
        case "$result" in
          y | Y)
               echo -n 1
                          break
                                 ;;
          n | N)
               echo -n 0
                          break
                                 ;;
          *) _cursor_to "${current_row}" ;;
        esac
    done
    echo -en "\033[0m" >&2
    echo "" >&2
}
list() {
    _prompt_text "$1 "
    local opts=("${@:2}")
    local opts_count=$(($# - 1))
    _new_line_foreach_item "${#opts[@]}"
    local lastrow
                   lastrow=$(_get_cursor_row)
    local startrow
                    startrow=$((lastrow - opts_count + 1))
    trap "_cursor_blink_on; stty echo; exit" 2
    _cursor_blink_off
    local selected=0
    while true; do
        local idx=0
        for opt in "${opts[@]}"; do
            _cursor_to $((startrow + idx))
            if [ "$idx" -eq "$selected" ]; then
                printf "\033[0m\033[36m❯\033[0m \033[36m%s\033[0m" "$opt" >&2
            else
                printf "  %s" "$opt" >&2
            fi
            ((idx++))
        done
        case $(_key_input) in
            enter) break  ;;
            up) selected=$(_decrement_selected "${selected}" "${opts_count}")  ;;
            down) selected=$(_increment_selected "${selected}" "${opts_count}")  ;;
        esac
    done
    echo -en "\n" >&2
    _cursor_to "${lastrow}"
    _cursor_blink_on
    echo -n "${selected}"
}
checkbox() {
    _prompt_text "$1"
    local opts
                opts=("${@:2}")
    local opts_count
                      opts_count=$(($# - 1))
    _new_line_foreach_item "${#opts[@]}"
    local lastrow
                   lastrow=$(_get_cursor_row)
    local startrow
                    startrow=$((lastrow - opts_count + 1))
    trap "_cursor_blink_on; stty echo; exit" 2
    _cursor_blink_off
    local selected=0
    local checked=()
    local idx=0
    for opt in "${opts[@]}"; do
        if [[ "$opt" =~ @#.*#@ ]]; then
            checked+=("$idx")
            opt_strip="${opt/@#/}"
            opt_strip="${opt_strip/\#@/}"
            opts["$idx"]="${opt_strip}"
        fi
        ((idx++))
    done
    while true; do
        local idx=0
        for opt in "${opts[@]}"; do
            _cursor_to $((startrow + idx))
            local icon="◯"
            for item in "${checked[@]}"; do
                if [ "$item" == "$idx" ]; then
                    icon="◉"
                    break
                fi
            done
            if [ "$idx" -eq "$selected" ]; then
                printf "%s \e[0m\e[36m❯\e[0m \e[36m%-50s\e[0m" "$icon" "$opt" >&2
            else
                printf "%s   %-50s" "$icon" "$opt" >&2
            fi
            ((idx++))
        done
        case $(_key_input) in
            enter) break ;;
            space)
                local found=0
                for item in "${checked[@]}"; do
                    if [ "$item" == "$selected" ]; then
                        found=1
                        break
                fi
            done
                if [ $found -eq 1 ]; then
                    checked=("${checked[@]/$selected/}")
            else
                    checked+=("${selected}")
            fi
                ;;
            up) selected=$(_decrement_selected "${selected}" "${opts_count}")  ;;
            down) selected=$(_increment_selected "${selected}" "${opts_count}")  ;;
        esac
    done
    _cursor_to "${lastrow}"
    _cursor_blink_on
    IFS="" echo -n "${checked[@]}"
}
password() {
    _prompt_text "$1"
    echo -en "\033[36m" >&2
    local password=''
    local IFS=
    while _read_stdin -r -s -n1 char; do
        [[ -z "${char}" ]] && {
                                printf '\n' >&2
                                                 break
        }
        if [ "${char}" == $'\x7f' ]; then
            if [ "${#password}" -gt 0 ]; then
                password="${password%?}"
                echo -en '\b \b' >&2
            fi
        else
            password+=$char
            echo -en '*' >&2
        fi
    done
    echo -en "\e[0m" >&2
    echo -n "${password}"
}
editor() {
    tmpfile=$(mktemp)
    _prompt_text "$1"
    echo "" >&2
    ${EDITOR:-vi} "${tmpfile}" >/dev/tty
    echo -en "\033[36m" >&2
    cat "${tmpfile}" | sed -e 's/^/  /' >&2
    echo -en "\033[0m" >&2
    cat "${tmpfile}"
}
with_validate() {
    while true; do
        local val
                   val="$(eval "$1")"
        if ($2 "$val" >/dev/null); then
            echo "$val"
            break
        else
            show_error "$($2 "$val")"
        fi
    done
}
range() {
    local min="$2"
    local current="$3"
    local max="$4"
    local selected="${current}"
    local max_len_current
                         max_len_current=0
    if [[ "${#min}" -gt "${#max}" ]]; then
        max_len_current="${#min}"
    else
        max_len_current="${#max}"
    fi
    local padding
                 padding="$(printf "%-${max_len_current}s" "")"
    local start_row
                   start_row=$(_get_cursor_row)
    local current_row
                     current_row=$((start_row - 1))
    trap "_cursor_blink_on; stty echo; exit" 2
    _cursor_blink_off
    _check_range() {
        val=$1
        if [[ "$val" -gt "$max" ]]; then
            val=$min
        elif [[ "$val" -lt "$min" ]]; then
            val=$max
        fi
        echo "$val"
    }
    while true; do
        _prompt_text "$1"
        printf "\033[37m%s\033[0m \033[1;90m❮\033[0m \033[36m%s%s\033[0m \033[1;90m❯\033[0m \033[37m%s\033[0m\n" "$min" "${padding:${#selected}}" "$selected" "$max" >&2
        case $(_key_input) in
        enter)
            break
            ;;
        left)
            selected="$(_check_range $((selected - 1)))"
            ;;
        right)
            selected="$(_check_range $((selected + 1)))"
            ;;
        esac
        _cursor_to "$current_row"
    done
    echo "$selected"
}
validate_present() {
    if [ "$1" != "" ]; then return 0; else
                                           echo "Please specify the value"
                                                                            return 1
    fi
}
show_error() {
    echo -e "\033[91;1m✘ $1\033[0m" >&2
}
show_success() {
    echo -e "\033[92;1m✔ $1\033[0m" >&2
}
LOG_ERROR=3
LOG_WARN=2
LOG_INFO=1
LOG_DEBUG=0
parse_log_level() {
    local level="$1"
    local parsed
    case "${level}" in
      info | INFO)   parsed=$LOG_INFO  ;;
      debug | DEBUG) parsed=$LOG_DEBUG  ;;
      warn | WARN)   parsed=$LOG_WARN  ;;
      error | ERROR) parsed=$LOG_ERROR  ;;
      *)             parsed=-1  ;;
    esac
    export LOG_LEVEL="${parsed}"
}
log() {
    local level="$1"
    local message="$2"
    local color=""
    if [[ $level -lt ${LOG_LEVEL:-$LOG_INFO} ]]; then
        return
    fi
    case "${level}" in
      "$LOG_INFO")
        level="INFO"
        color='\033[1;36m'
        ;;
      "$LOG_DEBUG")
        level="DEBUG"
        color='\033[1;34m'
        ;;
      "$LOG_WARN")
        level="WARN"
        color='\033[0;33m'
        ;;
      "$LOG_ERROR")
        level="ERROR"
        color='\033[0;31m'
        ;;
    esac
    echo -e "[${color}$(printf '%-5s' "${level}")\033[0m] \033[1;35m$(date +'%Y-%m-%dT%H:%M:%S')\033[0m ${message}"
}
detect_os() {
    case "$OSTYPE" in
        solaris*) echo "solaris"  ;;
        darwin*)  echo "macos"  ;;
        linux*)   echo "linux"  ;;
        bsd*)     echo "bsd"  ;;
        msys*)    echo "windows"  ;;
        cygwin*)  echo "windows"  ;;
        *)        echo "unknown"  ;;
    esac
}
get_opener() {
    local cmd
    case "$(detect_os)" in
        macos)  cmd="open"  ;;
        linux)   cmd="xdg-open"  ;;
        windows) cmd="start"  ;;
        *)       cmd=""  ;;
    esac
    echo "$cmd"
}
open_link() {
    cmd="$(get_opener)"
    if [ "$cmd" == "" ]; then
        echo "Your platform is not supported for opening links."
        echo "Please open the following URL in your preferred browser:"
        echo " ${1}"
        return 1
    fi
    $cmd "$1"
    if [[ $? -eq 1 ]]; then
        echo "Failed to open your browser."
        echo "Please open the following URL in your browser:"
        echo "${1}"
        return 1
    fi
    return 0
}
###############################################################################
#                          end bash-tui-toolkit bundle                      #
###############################################################################

MARKETPLACE="claude-customization-plugins"
MARKETPLACE_SOURCE="timo-reymann/claude-customization-plugins"

if ! command -v claude >/dev/null 2>&1; then
    show_error "The claude CLI was not found in PATH. Install Claude Code first."
    exit 1
fi

log "$LOG_INFO" "Adding the ${MARKETPLACE} marketplace"
GIT_CONFIG_GLOBAL=/dev/null claude plugin marketplace add "${MARKETPLACE_SOURCE}"

styles=("STE - ASD-STE100 Simplified Technical English" "ELI5 - explain like I'm five" "None")
choice=$(list "Which output style do you want?" "${styles[@]}")
case "$choice" in
    0) style="STE" ;;
    1) style="ELI5" ;;
    2) style="" ;;
esac

if [ -n "$style" ]; then
    log "$LOG_INFO" "Installing concise-output-styles"
    claude plugin install "concise-output-styles@${MARKETPLACE}"

    log "$LOG_INFO" "Running the concise-output-styles setup skill to enable ${style}"
    claude --print "Use the concise-output-styles-setup skill to enable the ${style} output style for me." \
        --allowedTools "Edit,Write,Read" >/dev/null

    show_success "Enabled the ${style} output style. Run /clear or start a new session for it to take effect."
fi

want_hook=$(confirm "Enable the comment-style-hook plugin (flags restated or overlong comments)?")
if [ "$want_hook" = "1" ]; then
    log "$LOG_INFO" "Installing comment-style-hook"
    claude plugin install "comment-style-hook@${MARKETPLACE}"
    show_success "Installed comment-style-hook. It runs on every Write/Edit tool call."
fi

want_md_hook=$(confirm "Enable the markdown-line-length-hook plugin (wraps generated Markdown at 118 characters)?")
if [ "$want_md_hook" = "1" ]; then
    log "$LOG_INFO" "Installing markdown-line-length-hook"
    claude plugin install "markdown-line-length-hook@${MARKETPLACE}"
    show_success "Installed markdown-line-length-hook. It runs on every Write/Edit tool call on a Markdown file."
fi

want_bsd_hook=$(confirm "Enable the macos-bsd-hook plugin (blocks grep -P and sed -i, which fail on macOS)?")
if [ "$want_bsd_hook" = "1" ]; then
    log "$LOG_INFO" "Installing macos-bsd-hook"
    claude plugin install "macos-bsd-hook@${MARKETPLACE}"
    show_success "Installed macos-bsd-hook. It runs on every Bash tool call."
fi

show_success "Setup complete."
