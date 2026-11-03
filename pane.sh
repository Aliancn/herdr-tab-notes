#!/bin/bash
# Entry point of the notes pane. Opens the tab's Markdown file in the editor,
# records this pane as the open notes pane for the tab, and clears the record
# when the editor exits (the pane closes with it).
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
root="${HERDR_PLUGIN_ROOT:?}"
state="${HERDR_PLUGIN_STATE_DIR:?}"
[ -f "${HERDR_PLUGIN_CONFIG_DIR:-/nonexistent}/config.env" ] && . "$HERDR_PLUGIN_CONFIG_DIR/config.env"

tab="${TABNOTES_TAB:-${HERDR_TAB_ID:-}}"
[ -n "$tab" ] || { echo "tabnotes: no tab id" >&2; sleep 3; exit 1; }
key=$(printf '%s' "$tab" | LC_ALL=C tr -c 'A-Za-z0-9_-' '_')
[ -n "$key" ] || key="tab"
notes_dir="${NOTES_DIR:-$state/notes}"
file="$notes_dir/$key.md"
if ! mkdir -p "$notes_dir" "$state/open"; then
  echo "tabnotes: cannot create $notes_dir" >&2
  sleep 3
  exit 1
fi

if [ ! -f "$file" ]; then
  title="${TABNOTES_WS_LABEL:-}"
  [ -n "${TABNOTES_TAB_LABEL:-}" ] && title="$title · ${TABNOTES_TAB_LABEL}"
  [ -n "$title" ] || title="$tab"
  printf '# %s\n\n' "$title" > "$file"
fi

echo "${HERDR_PANE_ID:-}" > "$state/open/$key"
trap 'rm -f "$state/open/$key"' EXIT

# Narrow the split. The new pane starts at half of the target pane's width;
# shrink it from its left edge to NOTES_COLS columns (resize amounts are a
# fraction of the whole terminal width).
if [ -n "${HERDR_PANE_ID:-}" ]; then
  herdr pane rename "$HERDR_PANE_ID" "notes" >/dev/null 2>&1 || true
  want="${TABNOTES_COLS:-40}"
  case "$want" in
    ''|*[!0-9]*) want=40 ;;
  esac
  [ "$want" -ge 20 ] || want=20
  if command -v jq >/dev/null 2>&1; then
    read -r total mine < <(herdr pane layout --pane "$HERDR_PANE_ID" 2>/dev/null \
      | jq -r --arg id "$HERDR_PANE_ID" '.result.layout | "\(.area.width) \((.panes[] | select(.pane_id == $id) | .rect.width) // 0)"')
    if [ "${total:-0}" -gt 0 ] && [ "${mine:-0}" -gt "$want" ]; then
      delta=$(awk -v t="$total" -v m="$mine" -v w="$want" 'BEGIN { printf "%.4f", (m - w) / t }')
      herdr pane resize --direction right --amount "$delta" --pane "$HERDR_PANE_ID" >/dev/null 2>&1 || true
    fi
  fi
fi

# Neovim reads these from the environment in init.vim. Keep the defaults light
# so the pane matches Herdr's light themes; override in config.env.
colorscheme="${NOTES_COLORSCHEME:-default}"
case "$colorscheme" in
  ''|*[!A-Za-z0-9_-]*) colorscheme=default ;;
esac
background="${NOTES_BACKGROUND:-light}"
case "$background" in
  light|dark) ;;
  *) background=light ;;
esac
spell="${NOTES_SPELL:-0}"
case "$spell" in
  0|1) ;;
  *) spell=0 ;;
esac
export TABNOTES_COLORSCHEME="$colorscheme"
export TABNOTES_BACKGROUND="$background"
export TABNOTES_SPELL="$spell"

if [ -n "${NOTES_EDITOR:-}" ]; then
  eval "$NOTES_EDITOR \"\$file\""
else
  if ! command -v nvim >/dev/null 2>&1; then
    echo "tabnotes: nvim is not on PATH; set NOTES_EDITOR or install nvim" >&2
    sleep 3
    exit 1
  fi
  nvim --clean -u "$root/init.vim" "$file"
fi
