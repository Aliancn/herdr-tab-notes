#!/bin/bash
# Toggle the notes pane for the focused tab.
# Runs as a herdr plugin action (no TTY). The focused tab and pane come from
# HERDR_PLUGIN_CONTEXT_JSON. pane.sh records its own pane id in
# $HERDR_PLUGIN_STATE_DIR/open/<tab-key>; if that pane still exists, close it,
# otherwise open a new right split next to the focused pane.
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
state="${HERDR_PLUGIN_STATE_DIR:?}"
ctx="${HERDR_PLUGIN_CONTEXT_JSON:-}"
[ -n "$ctx" ] || ctx="{}"
tab=$(jq -r '.tab_id // empty' <<<"$ctx");            [ -n "$tab" ]  || tab="${HERDR_TAB_ID:-}"
pane=$(jq -r '.focused_pane_id // empty' <<<"$ctx");  [ -n "$pane" ] || pane="${HERDR_PANE_ID:-}"
ws_label=$(jq -r '.workspace_label // empty' <<<"$ctx")
tab_label=$(jq -r '.tab_label // empty' <<<"$ctx")
if [ -z "$tab" ] || [ -z "$pane" ]; then
  herdr notification show "Tab notes: no focused tab or pane" >/dev/null 2>&1
  exit 1
fi
key="${tab//:/_}"
open="$state/open/$key"
mkdir -p "$state/open"

if [ -f "$open" ]; then
  np=$(cat "$open")
  if [ -n "$np" ] && herdr pane get "$np" >/dev/null 2>&1; then
    herdr pane close "$np" >/dev/null
    rm -f "$open"
    exit 0
  fi
  rm -f "$open"   # stale marker from a pane that is already gone
fi

[ -f "${HERDR_PLUGIN_CONFIG_DIR:-/nonexistent}/config.env" ] && . "$HERDR_PLUGIN_CONFIG_DIR/config.env"
cols="${NOTES_COLS:-40}"   # width of the notes pane in columns

herdr plugin pane open --plugin tabnotes --entrypoint notes --placement split \
  --target-pane "$pane" --direction right --focus \
  --env "TABNOTES_TAB=$tab" --env "TABNOTES_WS_LABEL=$ws_label" --env "TABNOTES_TAB_LABEL=$tab_label" \
  --env "TABNOTES_COLS=$cols" >/dev/null
