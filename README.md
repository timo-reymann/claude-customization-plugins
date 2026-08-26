# claude-customization-plugins

A marketplace of Claude Code plugins that add output styles and hooks.

## Quick setup

Run this one-liner for an interactive setup. It adds the marketplace, asks
whether you want a concise output style (and which one), asks whether you
want the comment-style hook, and installs what you pick.

```
bash <(curl -fsSL https://raw.githubusercontent.com/timo-reymann/claude-customization-plugins/main/setup.sh)
```

The script bundles [bash-tui-toolkit](https://github.com/timo-reymann/bash-tui-toolkit)
for its prompts, so it has no extra dependencies beyond `bash` and the
`claude` CLI.

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

An output style does not turn on by itself. Select it with the `/config`
command, then pick **Output style** from the menu. You can also set the
`outputStyle` field in a settings file, for example `"outputStyle": "STE"`.
A style change takes effect after `/clear`, or in a new session.

The plugin also has a setup skill, `concise-output-styles-setup`. Ask Claude
to set up a style, and it will guide you through the install and the
`/config` selection step.

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

## License

This repo uses the Unlicense. See the [LICENSE](LICENSE) file.
