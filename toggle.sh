#!/bin/bash
# Toggle the notes pane for the focused tab.
# Runs as a herdr plugin action (no TTY). The focused tab and pane come from
# HERDR_PLUGIN_CONTEXT_JSON. pane.sh records its own pane id in
# $HERDR_PLUGIN_STATE_DIR/open/<tab-key>; if that pane still exists, close it,
# otherwise open a new right split next to the focused pane.
set -u

# Keep the usual Homebrew paths first for GUI-launched Herdr servers; fall
# back to whatever PATH the caller already has.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

state="${HERDR_PLUGIN_STATE_DIR:?}"
ctx="${HERDR_PLUGIN_CONTEXT_JSON:-}"
[ -n "$ctx" ] || ctx="{}"

if ! command -v jq >/dev/null 2>&1; then
  herdr notification show "Tab notes: jq is required" >/dev/null 2>&1
  exit 1
fi

tab=$(jq -r '.tab_id // empty' <<<"$ctx");            [ -n "$tab" ]  || tab="${HERDR_TAB_ID:-}"
pane=$(jq -r '.focused_pane_id // empty' <<<"$ctx");  [ -n "$pane" ] || pane="${HERDR_PANE_ID:-}"
ws_label=$(jq -r '.workspace_label // empty' <<<"$ctx")
tab_label=$(jq -r '.tab_label // empty' <<<"$ctx")
if [ -z "$tab" ] || [ -z "$pane" ]; then
  herdr notification show "Tab notes: no focused tab or pane" >/dev/null 2>&1
  exit 1
fi

# Herdr tab ids are normally w1:t9. Normalize anything else so a tab id can
# never escape the notes directory.
key=$(printf '%s' "$tab" | LC_ALL=C tr -c 'A-Za-z0-9_-' '_')
[ -n "$key" ] || key="tab"
open="$state/open/$key"
if ! mkdir -p "$state/open"; then
  herdr notification show "Tab notes: cannot create state directory" >/dev/null 2>&1
  exit 1
fi

# Serialize rapid toggles. A pane only writes its marker after it starts, so
# without this two quick presses can open two notes panes for the same tab.
lock="$state/toggle.lock"
if ! mkdir "$lock" 2>/dev/null; then
  lock_pid=$(cat "$lock/pid" 2>/dev/null || true)
  if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
    exit 0
  fi
  rm -rf "$lock" 2>/dev/null || true
  mkdir "$lock" 2>/dev/null || exit 0
fi
printf '%s\n' "$$" > "$lock/pid"
trap 'rm -rf "$lock"' EXIT

if [ -f "$open" ]; then
  np=$(cat "$open")
  if [ -n "$np" ] && herdr pane get "$np" >/dev/null 2>&1; then
    if herdr pane close "$np" >/dev/null 2>&1; then
      rm -f "$open"
      exit 0
    fi
    herdr notification show "Tab notes: failed to close the notes pane" >/dev/null 2>&1
    exit 1
  fi
  rm -f "$open"   # stale marker from a pane that is already gone
fi

[ -f "${HERDR_PLUGIN_CONFIG_DIR:-/nonexistent}/config.env" ] && . "$HERDR_PLUGIN_CONFIG_DIR/config.env"
cols="${NOTES_COLS:-40}"
case "$cols" in
  ''|*[!0-9]*) cols=40 ;;
esac
[ "$cols" -ge 20 ] || cols=20

if ! resp=$(herdr plugin pane open --plugin tabnotes --entrypoint notes --placement split \
  --target-pane "$pane" --direction right --focus \
  --env "TABNOTES_TAB=$tab" --env "TABNOTES_WS_LABEL=$ws_label" --env "TABNOTES_TAB_LABEL=$tab_label" \
  --env "TABNOTES_COLS=$cols" 2>/dev/null); then
  herdr notification show "Tab notes: failed to open the notes pane" >/dev/null 2>&1
  exit 1
fi

# Record the new pane before releasing the lock. pane.sh writes the same id
# once it starts; this closes the race where a second toggle arrives before
# the pane has started and sees no marker.
new_pane=$(jq -r '.result.plugin_pane.pane.pane_id // .plugin_pane.pane.pane_id // .result.pane.pane_id // .result.pane_id // empty' <<<"$resp" 2>/dev/null)
if [ -n "$new_pane" ]; then
  printf '%s\n' "$new_pane" > "$open"
else
  # Fallback: give pane.sh a moment to publish its own marker.
  i=0
  while [ "$i" -lt 20 ] && [ ! -s "$open" ]; do
    sleep 0.05
    i=$((i + 1))
  done
fi
