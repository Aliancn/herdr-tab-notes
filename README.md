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

Bind a key in `~/.config/herdr/config.toml` and reload. `prefix+n` is Herdr's default
for "next tab", so pick a free one; `prefix+f` is free in the default layout:

```toml
[[keys.command]]
key = "prefix+f"
type = "plugin_action"
command = "tabnotes.toggle"
description = "toggle tab notes"
```

```bash
herdr server reload-config
```

Requires `nvim` and `jq` on `PATH` (both are on Homebrew: `brew install neovim jq`).

## Use

- `prefix+f` opens the note for the focused tab in a 40-column split on the right and
  focuses it. `prefix+f` again closes it. The action is also in Herdr's plugin action
  list as "Tab notes: toggle the notes pane for this tab".
- The editor is Neovim with its own small config (`init.vim`, loaded with `--clean`,
  so your personal Neovim setup is not touched). Every change is saved immediately.
  - `q` saves and closes the pane.
  - `Ctrl+S` saves (normal and insert mode).
  - `Ctrl+X` toggles a `- [ ]` checkbox on the current line, or turns the line into one.
  - `Ctrl+C` copies the whole note to the system clipboard. In visual mode it copies
    the selection.
- Every yank (`yy`, `yip`, a selection and `y`) also goes to the system clipboard.
  The text is sent through the terminal with OSC 52, and Herdr forwards it to the
  machine you sit at. A yank on a saved SSH machine reaches your local clipboard.
  Deletes stay in Neovim's registers. `p` pastes the last yank or delete from the
  pane; to paste text from another app, use the terminal's paste key (`Cmd+V`).
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

## Remote machines

Herdr runs plugin actions on the server of the machine you are viewing, and it does not
copy plugins to SSH hosts. So `prefix+f` on a tab that lives on a saved SSH machine
needs the plugin on that machine as well. On each remote:

```bash
herdr plugin install yang3kc/herdr-tab-notes --yes   # --yes: the prompt needs a TTY otherwise
# add the same [[keys.command]] block to that machine's ~/.config/herdr/config.toml
herdr server reload-config
```

`nvim` and `jq` must be on the remote's `PATH` too. Each machine keeps its own notes in its
own state directory; nothing is synced between machines. After a plugin update, run the
install command again on each remote.

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
