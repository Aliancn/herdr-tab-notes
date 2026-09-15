# herdr-tab-notes

One plain Markdown scratchpad per [Herdr](https://herdr.dev) tab. One key opens it in a
narrow split on the right of the focused pane; the same key closes it. Nothing else:
no daemon, no build step, no sync. The point is to write down what the agents in this
tab are supposed to do next, so the intent survives a switch to another project.

```
┌──────────────────────────────────────┬────────────┐
│ claude (working)                     │ # dev · pr │
│                                      │            │
│                                      │ - [ ] ask  │
│                                      │   for the  │
│                                      │   diff     │
│                                      │ - [x] rerun│
└──────────────────────────────────────┴────────────┘
```

## Install

```bash
herdr plugin install yang3kc/herdr-tab-notes
# or, from a clone:
herdr plugin link /path/to/herdr-tab-notes
```

Bind a key in `~/.config/herdr/config.toml` and reload:

```toml
[[keys.command]]
key = "prefix+n"
type = "plugin_action"
command = "tabnotes.toggle"
description = "toggle tab notes"
```

```bash
herdr server reload-config
```

Requires `nvim` and `jq` on `PATH` (both are on Homebrew: `brew install neovim jq`).

## Use

- `prefix+n` opens the note for the focused tab in a 40-column split on the right and
  focuses it. `prefix+n` again closes it. The action is also in Herdr's plugin action
  list as "Tab notes: toggle the notes pane for this tab".
- The editor is Neovim with its own small config (`init.vim`, loaded with `--clean`,
  so your personal Neovim setup is not touched). Every change is saved immediately.
  - `q` saves and closes the pane.
  - `Ctrl+S` saves (normal and insert mode).
  - `Ctrl+X` toggles a `- [ ]` checkbox on the current line, or turns the line into one.
- A new note starts with a heading made from the workspace and tab labels.

## Where the notes live

`~/.local/state/herdr/plugins/tabnotes/notes/<workspace>_<tab>.md`, one file per tab,
named by Herdr's stable tab id (for example `w1M_t9.md`). Files are never deleted by
the plugin; a note for a closed tab stays there until you remove it.

## Options

Create `~/.config/herdr/plugins/config/tabnotes/config.env` (the directory is printed by
`herdr plugin config-dir tabnotes`) with any of:

```sh
NOTES_DIR="$HOME/notes/herdr"      # keep the files somewhere else, e.g. inside a vault
NOTES_COLS=48                      # width of the notes pane in columns (default 40)
NOTES_EDITOR="nvim"                # use your own editor command instead of the bundled config
```

## How it works

- `toggle.sh` is a plugin action. Herdr passes the focused workspace, tab, and pane in
  `HERDR_PLUGIN_CONTEXT_JSON`. If `state/open/<tab>` names a pane that still exists, the
  action closes it; otherwise it calls `herdr plugin pane open` with `--placement split
  --direction right --target-pane <focused pane>`.
- `pane.sh` is the pane entry point. It creates the note file if needed, writes its own
  pane id to `state/open/<tab>`, renames the pane to `notes`, shrinks the split to
  `NOTES_COLS` columns with `herdr pane resize`, and runs the editor. When the editor
  exits the marker is removed and Herdr closes the pane.

## License

MIT
