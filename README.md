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

## Fork notes

This repository is a maintained fork of
[yang3kc/herdr-tab-notes](https://github.com/yang3kc/herdr-tab-notes)
(MIT, Copyright (c) 2026 Kaicheng Yang).

Changes in this fork:

- Serialize rapid toggles with a lock, and record the new pane id before
  releasing it, so double-pressing the key cannot open two notes panes.
- Sanitize tab ids before using them as file names.
- Default to a light Neovim theme (`background=light`, `colorscheme default`)
  so the pane matches light Herdr themes. Override with `NOTES_BACKGROUND` and
  `NOTES_COLORSCHEME`.
- Optional spell checking with `NOTES_SPELL=1`.
- Dependency checks for `jq` / `nvim`, clearer errors, and a sample
  `config.env.example`.
- Leave `q`, `Ctrl+S` and `Ctrl+C` at Neovim defaults: close the pane with the
  Herdr toggle or `:q`, rely on autosave, and keep stock interrupt/cancel
  behavior. Yanking still copies through OSC 52.
- Fix the markdown buffer's 2-space indent (the ftplugin otherwise resets it to
  4) and scope "open at the end" to `*.md` instead of every buffer.
- Optional `NOTES_USER_CONFIG=1`: load your normal Neovim config and overlay
  only the tabnotes behavior, so the pane keeps your theme and statusline
  instead of the bundled minimal look.

## Install

```bash
herdr plugin install Aliancn/herdr-tab-notes
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

Requires `jq` on `PATH`; `nvim` is required unless you set `NOTES_EDITOR` (both are on
Homebrew: `brew install neovim jq`).

## Use

- `prefix+f` opens the note for the focused tab in a `NOTES_COLS`-column split
  (default 40) on the right and focuses it. `prefix+f` again closes it. The action
  is also in Herdr's plugin action list as "Tab notes: toggle the notes pane for
  this tab".
- The editor is Neovim. By default it uses a small bundled config (`init.vim`,
  loaded with `--clean`, so your personal Neovim setup is not touched). Set
  `NOTES_USER_CONFIG=1` to load your normal Neovim config instead and overlay
  only the tabnotes behavior: the pane then keeps your theme, statusline and
  options, while autosave, OSC 52 yanks, checkbox toggling and screen-line
  motions still work. Every change is saved immediately in either mode.
  - `Ctrl+X` toggles a `- [ ]` checkbox on the current line, or turns the line into one.
  - In the bundled config, `q`, `Ctrl+S` and `Ctrl+C` keep Neovim defaults. Close
    the pane with `prefix+f` or `:q`; `q` records macros again, and `Ctrl+C`
    cancels/interrupts as usual. With `NOTES_USER_CONFIG=1`, your own mappings
    apply instead (for example a `Ctrl+S` save mapping from your config).
- Every yank (`yy`, `yip`, a selection and `y`) also goes to the system clipboard.
  The text is sent through the terminal with OSC 52, and Herdr forwards it to the
  machine you sit at. A yank on a saved SSH machine reaches your local clipboard.
  Deletes stay in Neovim's registers. `p` pastes the last yank or delete from the
  pane; to paste text from another app, use the terminal's paste key (`Cmd+V`).
- A new note starts with a heading made from the workspace and tab labels.

## Key mappings

`init.vim` keeps stock Neovim behavior except for:

| Mode | Key | Action |
| --- | --- | --- |
| Normal | `j` / `k`, `Down` / `Up` | move by screen line |
| Normal | `0` / `$` | screen line start / end |
| Normal / Insert | `Ctrl+X` | toggle a Markdown checkbox |
| Visual | `j` / `k`, `Down` / `Up` | move by screen line |
| Insert | `Down` / `Up` | move by screen line |

`q`, `Ctrl+S`, and `Ctrl+C` are not remapped.

## Where the notes live

`~/.local/state/herdr/plugins/tabnotes/notes/<workspace>_<tab>.md`, one file per tab,
named by Herdr's stable tab id (for example `w1M_t9.md`). Tab ids are reduced to
letters, digits, `_` and `-` before they are used as file names. Files are never
deleted by the plugin; a note for a closed tab stays there until you remove it.

Set `NOTES_DIR` to keep the files somewhere else, for example inside a notes vault.

## Options

Create `~/.config/herdr/plugins/config/tabnotes/config.env` (the directory is printed by
`herdr plugin config-dir tabnotes`) with any of:

```sh
NOTES_DIR="$HOME/notes/herdr"      # keep the files somewhere else, e.g. inside a vault
NOTES_COLS=48                      # width of the notes pane in columns (default 40)
NOTES_EDITOR="nvim"                # use your own editor command instead of the bundled config
NOTES_USER_CONFIG=1                # load your normal Neovim config + overlay tabnotes behavior
NOTES_BACKGROUND="light"           # light (default) or dark
NOTES_COLORSCHEME="default"        # any installed Neovim colorscheme
NOTES_SPELL=1                      # enable spell checking (default 0)
```

`NOTES_BACKGROUND` and `NOTES_COLORSCHEME` only apply to the bundled config; with
`NOTES_USER_CONFIG=1` your own colorscheme wins. `NOTES_EDITOR` takes precedence
over `NOTES_USER_CONFIG` when both are set.

The file is sourced by the plugin, so it is shell code; only put your own settings in
it. A commented example is in `config.env.example`.

## Remote machines

Herdr runs plugin actions on the server of the machine you are viewing, and it does not
copy plugins to SSH hosts. So `prefix+f` on a tab that lives on a saved SSH machine
needs the plugin on that machine as well. On each remote:

```bash
herdr plugin install Aliancn/herdr-tab-notes --yes   # --yes: the prompt needs a TTY otherwise
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
  --direction right --target-pane <focused pane>`. A small directory lock serializes
  rapid toggles.
- `pane.sh` is the pane entry point. It creates the note file if needed, writes its own
  pane id to `state/open/<tab>`, renames the pane to `notes`, shrinks the split to
  `NOTES_COLS` columns with `herdr pane resize`, and runs the editor. When the editor
  exits the marker is removed and Herdr closes the pane. With `NOTES_USER_CONFIG=1`
  it starts `nvim` normally and sources `init-user.vim`, which overlays the tabnotes
  behavior on your config.

## License

MIT. See [LICENSE](LICENSE). Upstream copyright (c) 2026 Kaicheng Yang; fork
modifications copyright (c) 2026 Aliancn.
