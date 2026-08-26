---
name: concise-output-styles-setup
description: Use when the user asks to set up, enable, or turn on a concise output style such as STE or ELI5, or asks how to select one after they install the concise-output-styles plugin.
---

# concise-output-styles setup

Use this skill to help the user turn on an output style from the
`concise-output-styles` plugin, such as `STE` or `ELI5`.

## Steps

1. Confirm the plugin is installed. Run `claude plugin list` and check for
   `concise-output-styles` in the output.
2. If the plugin is not in the list, tell the user to add the marketplace and
   install the plugin.
   ```
   claude plugin marketplace add /Users/phpe/workspace/claude-customization-plugins
   claude plugin install concise-output-styles@claude-customization-plugins
   ```
3. Ask the user which style they want: `STE` for ASD-STE100 Simplified
   Technical English, or `ELI5` for simple, everyday language.
4. Tell the user to select the style. They can run the `/output-style`
   command and pick it from the list, or set it in a settings file with
   `"outputStyle": "STE"` or `"outputStyle": "ELI5"`.
5. Confirm the style is active. Ask the user to check that new prose replies
   match the style rules.

## Notes

- The output style does not turn on when the plugin installs. The user must
  select it.
- The comment-style hook is in a separate plugin, `comment-style-hook`. This
  skill does not cover that plugin.
