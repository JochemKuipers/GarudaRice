#!/usr/bin/env bash
# Recover Dr460nized multi-monitor panels/dock after sleep, hotplug, or
# Display Configuration dragging monitors into a corner-only touch layout.
#
# Symptoms this fixes:
#   - window-buttons applet dead on the secondary
#   - dock icons vanish while the app is open (esp. Dolphin)
#   - plasmashell log: "requesting unexisting screen geometry N"
#
# Usage:
#   ./fix-multimonitor.sh           # fix layout + plasmashell + panels
#   ./fix-multimonitor.sh --check   # diagnose only
#   ./fix-multimonitor.sh --no-restart
set -euo pipefail

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

CHECK_ONLY=0
NO_RESTART=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    --no-restart) NO_RESTART=1 ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) die "Unknown option: $1 (try --help)" ;;
  esac
  shift
done

have kscreen-doctor || die "kscreen-doctor missing (plasma-desktop / libkscreen)"
have qdbus6 || die "qdbus6 missing"
have python3 || die "python3 missing"

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
[[ -S "${DBUS_SESSION_BUS_ADDRESS#unix:path=}" ]] || die "No session bus — run from your graphical session"

plasma_eval() {
  qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"
}

# Parse enabled outputs → name|w|h|x|y|priority (priority 1 = primary)
parse_outputs() {
  python3 - <<'PY'
import re, subprocess
text = subprocess.check_output(['kscreen-doctor', '-o'], text=True, stderr=subprocess.DEVNULL)
text = re.sub(r'\x1b\[[0-9;]*m', '', text)
outs, cur = [], None
for line in text.splitlines():
    m = re.match(r'Output:\s*\d+\s+(\S+)', line)
    if m:
        if cur:
            outs.append(cur)
        cur = {'name': m.group(1), 'enabled': False, 'x': 0, 'y': 0, 'w': 0, 'h': 0, 'priority': 99}
        continue
    if not cur:
        continue
    if re.search(r'\benabled\b', line) and 'disabled' not in line:
        cur['enabled'] = True
    m = re.search(r'Geometry:\s*(-?\d+),(-?\d+)\s+(\d+)x(\d+)', line)
    if m:
        cur['x'], cur['y'] = int(m.group(1)), int(m.group(2))
        cur['w'], cur['h'] = int(m.group(3)), int(m.group(4))
    m = re.search(r'priority\s+(\d+)', line, re.I)
    if m:
        cur['priority'] = int(m.group(1))
if cur:
    outs.append(cur)
for o in outs:
    if not o['enabled'] or o['w'] <= 0:
        continue
    print(f"{o['name']}|{o['w']}|{o['h']}|{o['x']}|{o['y']}|{o['priority']}")
PY
}

# True if two axis-aligned rects share a positive-length edge (not just a corner)
share_edge() {
  python3 - "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" <<'PY'
import sys
x1,y1,w1,h1,x2,y2,w2,h2 = map(int, sys.argv[1:])
r1 = (x1, y1, x1+w1, y1+h1)
r2 = (x2, y2, x2+w2, y2+h2)
# vertical edge shared
if r1[2] == r2[0] or r2[2] == r1[0]:
    top, bot = max(r1[1], r2[1]), min(r1[3], r2[3])
    sys.exit(0 if bot - top > 0 else 1)
# horizontal edge shared
if r1[3] == r2[1] or r2[3] == r1[1]:
    left, right = max(r1[0], r2[0]), min(r1[2], r2[2])
    sys.exit(0 if right - left > 0 else 1)
sys.exit(1)
PY
}

layout_ok() {
  local -a lines=()
  mapfile -t lines < <(parse_outputs)
  local n=${#lines[@]}
  (( n >= 2 )) || return 0
  # Every non-primary output must share an edge with *some* other enabled output
  # (connected component via edges). Corner-only = broken for Plasma.
  local i j
  declare -A ok=()
  for ((i=0; i<n; i++)); do
    IFS='|' read -r _n _w _h _x _y _p <<<"${lines[$i]}"
    for ((j=0; j<n; j++)); do
      (( i == j )) && continue
      IFS='|' read -r n2 w2 h2 x2 y2 _p2 <<<"${lines[$j]}"
      if share_edge "$_x" "$_y" "$_w" "$_h" "$x2" "$y2" "$w2" "$h2"; then
        ok[$i]=1
        break
      fi
    done
  done
  for ((i=0; i<n; i++)); do
    [[ -n ${ok[$i]+x} ]] || return 1
  done
  return 0
}

# Row layout: primary at 0,0; others left→right by current x, vertically centered on primary
fix_layout() {
  mapfile -t lines < <(parse_outputs)
  (( ${#lines[@]} >= 2 )) || { log "Only one display — nothing to align"; return 0; }

  # Pick primary = lowest kscreen priority value
  local best_p=999999 primary=""
  declare -A W H X Y P
  local line name w h x y p
  for line in "${lines[@]}"; do
    IFS='|' read -r name w h x y p <<<"$line"
    W[$name]=$w; H[$name]=$h; X[$name]=$x; Y[$name]=$y; P[$name]=$p
    if (( p < best_p )); then best_p=$p; primary=$name; fi
  done
  [[ -n $primary ]] || die "Could not detect primary output"

  local -a rest=()
  for name in "${!W[@]}"; do
    [[ $name == "$primary" ]] && continue
    rest+=("$name")
  done
  # Sort remaining by current X (stable physical left-to-right intent)
  IFS=$'\n' rest=($(for n in "${rest[@]}"; do printf '%s %s\n' "${X[$n]}" "$n"; done | sort -n | awk '{print $2}'))
  unset IFS

  local px=0 py=0
  local args=("output.${primary}.position.${px},${py}")
  local cursor_x=${W[$primary]}
  local name ny
  for name in "${rest[@]}"; do
    # Vertically center on primary
    ny=$(( (${H[$primary]} - ${H[$name]}) / 2 ))
    (( ny < 0 )) && ny=0
    args+=("output.${name}.position.${cursor_x},${ny}")
    cursor_x=$(( cursor_x + ${W[$name]} ))
  done

  log "Aligning outputs into one shared-edge row (primary=$primary)"
  log "  kscreen-doctor ${args[*]}"
  kscreen-doctor "${args[@]}"
  sleep 1
}

print_status() {
  log "Displays:"
  parse_outputs | while IFS='|' read -r name w h x y p; do
    printf '    %s  %dx%d @ %d,%d  (priority %s)\n' "$name" "$w" "$h" "$x" "$y" "$p"
  done
  if layout_ok; then
    log "Layout: shared edges OK"
  else
    warn "Layout: discontinuous (corner-only / floating) — Plasma per-screen widgets will glitch"
  fi
  log "Plasma panels:"
  # qdbus often collapses JS print() newlines — use a record separator
  plasma_eval '
var ps = panels(), out = [];
for (var i = 0; i < ps.length; i++) {
  var p = ps[i];
  out.push("id=" + p.id + " screen=" + p.screen + " loc=" + p.location + " h=" + p.height);
}
print(out.join("\n"));
' 2>/dev/null | tr -d '\r' | while IFS= read -r line || [[ -n $line ]]; do
    [[ -z $line ]] && continue
    # If still one line, split on "id="
    if [[ $line == id=*id=* ]]; then
      echo "$line" | sed 's/id=/\nid=/g' | sed '/^$/d' | sed 's/^/    /'
    else
      printf '    %s\n' "$line"
    fi
  done || warn "plasmashell not responding"
}

ensure_windowbuttons_config() {
  local cfg="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  [[ -f $cfg ]] || return 0
  python3 - "$cfg" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = path.read_text().splitlines(True)
out = []
i = 0
patched = 0
want = {'filterByScreen': 'true', 'perScreenActive': 'true'}

while i < len(lines):
    line = lines[i]
    is_general = (
        line.startswith('[')
        and '[Applets][' in line
        and line.rstrip().endswith('[Configuration][General]')
    )
    if not is_general:
        out.append(line)
        i += 1
        continue

    header = line
    i += 1
    body = []
    while i < len(lines) and not lines[i].startswith('['):
        body.append(lines[i])
        i += 1

    body_txt = ''.join(body)
    # window-buttons blocks always have selectedPlugin + visibility
    if 'selectedPlugin=' not in body_txt or 'visibility=' not in body_txt:
        out.append(header)
        out.extend(body)
        continue

    keys = {}
    order = []
    for bl in body:
        if '=' in bl and not bl.lstrip().startswith('#'):
            k, v = bl.split('=', 1)
            keys[k] = v.rstrip('\n')
            order.append(k)

    changed = False
    for k, v in want.items():
        if keys.get(k) != v:
            keys[k] = v
            if k not in order:
                order.append(k)
            changed = True

    out.append(header)
    for k in order:
        out.append(f'{k}={keys[k]}\n')
    if changed:
        patched += 1

if patched:
    path.write_text(''.join(out))
    print(f'patched {patched} window-buttons applet(s)')
else:
    print('window-buttons filterByScreen/perScreenActive already set')
PY
}

# Prefer: one top + one bottom on screen 0, one top + one bottom on screen 1.
# If both pairs sit on screen 0 (common after reconnect), move one of each to 1.
repair_panels() {
  log "Checking panel screen pins"
  plasma_eval '
function locName(l) {
  // Plasma JS location is a string in evaluateScript ("top"/"bottom"/...)
  return "" + l;
}
var ps = panels();
var tops = [], bottoms = [];
for (var i = 0; i < ps.length; i++) {
  var p = ps[i];
  var loc = locName(p.location);
  if (loc === "top") tops.push(p);
  else if (loc === "bottom") bottoms.push(p);
}
print("tops=" + tops.length + " bottoms=" + bottoms.length);

function ensurePair(list, label) {
  if (list.length < 2) {
    print("skip " + label + " (need >=2, have " + list.length + ")");
    return;
  }
  // Prefer keeping lowest id on screen 0 (usually the original primary)
  list.sort(function(a,b){ return a.id - b.id; });
  var primary = list[0];
  var secondary = list[1];
  if (primary.screen !== 0) {
    primary.screen = 0;
    print("pinned " + label + " id=" + primary.id + " -> screen 0");
  } else {
    print("ok " + label + " id=" + primary.id + " on screen 0");
  }
  if (secondary.screen !== 1) {
    secondary.screen = 1;
    print("pinned " + label + " id=" + secondary.id + " -> screen 1");
  } else {
    print("ok " + label + " id=" + secondary.id + " on screen 1");
  }
  // Any further copies: park on screen 1 (better than stacking on primary)
  for (var i = 2; i < list.length; i++) {
    if (list[i].screen !== 1) {
      list[i].screen = 1;
      print("pinned extra " + label + " id=" + list[i].id + " -> screen 1");
    }
  }
}
ensurePair(tops, "top");
ensurePair(bottoms, "dock");
' 2>/dev/null | tr -d '\r' || warn "panel repair script failed"
}

restart_plasmashell() {
  log "Restarting plasmashell"
  if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
    systemctl --user restart plasma-plasmashell.service
  else
    kquitapp6 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true
    sleep 2
    nohup plasmashell --replace >/dev/null 2>&1 &
  fi
  # Wait until dbus is back
  local i
  for i in $(seq 1 30); do
    if plasma_eval 'print("ok")' 2>/dev/null | grep -q ok; then
      return 0
    fi
    sleep 0.5
  done
  warn "plasmashell did not come back on dbus quickly — check manually"
}

# --- main ---
print_status

if (( CHECK_ONLY )); then
  exit 0
fi

if layout_ok; then
  log "Layout already continuous — skipping kscreen move"
else
  fix_layout
fi

ensure_windowbuttons_config

if (( NO_RESTART == 0 )); then
  restart_plasmashell
else
  log "Skipping plasmashell restart (--no-restart)"
fi

repair_panels
echo
print_status
log "Done. Focus a maximized window on each screen and click Dolphin on the secondary dock to verify."
