#!/usr/bin/env bash
# Deny GNU-only grep and sed syntax on macOS, where the system tools are BSD (no grep -P, no sed -i without suffix).

[ "$(uname -s)" = "Darwin" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

cmd=$(jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

# "grep" must start a word, so egrep and ggrep do not match. The [^|;&]* part stops at a pipe or a list separator.
start='(^|[|;&(`[:space:]]|/)grep'
perl_flag="${start}([[:space:]]+[^|;&]*)?[[:space:]]+(-[A-Za-z]*P[A-Za-z]*|--perl-regexp)([[:space:]]|\$)"
lookaround="${start}[[:space:]]+[^|;&]*\\(\\?<?[=!]"
sed_start='(^|[|;&(`[:space:]]|/)sed'
sed_inplace="${sed_start}[[:space:]]+([^|;&]*[[:space:]])?(-[A-Za-z]*i|--in-place)[[:space:]]+[^|;&[:space:]]"
sed_bsd_inplace="-i[[:space:]]+(''|\"\")([[:space:]]|\$)"

if [[ $cmd =~ $perl_flag ]]; then
  found="the -P (PCRE) flag"
elif [[ $cmd =~ $lookaround ]]; then
  found="a lookaround pattern"
elif [[ $cmd =~ $sed_inplace ]] && ! [[ $cmd =~ $sed_bsd_inplace ]]; then
  found="sed -i without a backup suffix"
  hint="Use the Edit tool, or 'sed -i '' ...', or 'gsed -i ...'."
else
  exit 0
fi

reason="macOS tools are BSD, not GNU. This command uses ${found}, which BSD does not support. Do not write a Python script. ${hint:-Use 'rg' (add -P for PCRE), or 'ggrep -P', or the Grep tool. For a plain pattern, use 'grep -E'.}"

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
