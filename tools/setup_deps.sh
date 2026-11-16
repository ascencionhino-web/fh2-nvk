#!/usr/bin/env bash
# fh2-nvk: descarga Mesa para Switch (danfromtico/mesa-switch), el script de compilacion de masseffect-nx y el parche de
# prototype2-nx, fijados a un commit, y aplica los parches (el de prototype2-nx y el de FH2: patches/fh2-nvk.patch).
#   tools/setup_deps.sh mesa
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REF="$ROOT/reference"
ME_URL=https://github.com/nebadasSwifty/masseffect-nx.git
ME_PIN=a85b0b419ec3e332165ae1617c980bd399856a44
P2_URL=https://github.com/penettrator/prototype2-nx.git
P2_PIN=7371f849f1d49c2cccacbd0e5aef113335d2d9f1
MESA_URL=https://github.com/danfromtico/mesa-switch.git
MESA_PIN=d4a00ea0ab3f59afb967cc5d779e4263d237bd77
mkdir -p "$REF"
fetch() {
  local d="$REF/$1"
  if [ ! -d "$d/.git" ]; then git init -q "$d"; git -C "$d" remote add origin "$2"; fi
  if [ "$(git -C "$d" rev-parse HEAD 2>/dev/null || true)" != "$3" ]; then
    echo "== fetch $1 @ ${3:0:10}"
    git -C "$d" fetch -q --depth 1 origin "$3"
    git -C "$d" checkout -q -f "$3"
  fi
}
apply() {
  if git -C "$1" apply --reverse --check "$2" 2>/dev/null; then echo "== parche ya aplicado: $(basename "$2")"
  else echo "== aplicando $(basename "$2")"; git -C "$1" apply "$2"; fi
}
fetch prototype2-nx "$P2_URL" "$P2_PIN"
fetch masseffect-nx "$ME_URL" "$ME_PIN"
fetch mesa-switch-src "$MESA_URL" "$MESA_PIN"
apply "$REF/mesa-switch-src" "$REF/prototype2-nx/patches/mesa-switch.patch"
apply "$REF/mesa-switch-src" "$ROOT/patches/fh2-nvk.patch"
echo OK
