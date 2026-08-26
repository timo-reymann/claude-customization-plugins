# claude-customization-plugins

A marketplace of Claude Code plugins that add output styles and hooks.

## Add the marketplace

Run this command.

```
claude plugin marketplace add timo-reymann/claude-customization-plugins
```

If you have a local clone, you can use the local path instead.

```
claude plugin marketplace add /path/to/claude-customization-plugins
```

## Plugins

### concise-output-styles

This plugin adds two output styles.

- `STE`. The style makes Claude write prose in ASD-STE100 Simplified
  Technical English.
- `ELI5`. The style makes Claude explain each topic in simple words, with
  everyday examples, like an explanation for a five year old child.

Install the plugin with this command.

```
claude plugin install concise-output-styles@claude-customization-plugins
```

An output style does not turn on by itself. Select it with the `/output-style`
command, or with the config menu.

The plugin also has a setup skill, `concise-output-styles-setup`. Ask Claude
to set up a style, and it will guide you through the install and the
`/output-style` selection step.

### comment-style-hook

This plugin adds a `PostToolUse` hook. The hook runs after each `Write` or
`Edit` tool call and checks the comments in the changed code. It flags a
comment that restates the code, or a comment that spans more than two lines.

Install the plugin with this command.

```
claude plugin install comment-style-hook@claude-customization-plugins
```

The hook turns on as soon as you install the plugin. It runs on every `Write`
or `Edit` tool call, with no extra step from you.
