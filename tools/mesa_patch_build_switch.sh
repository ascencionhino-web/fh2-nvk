#!/usr/bin/env bash
# Parchea build-switch.sh de mesa-switch para que la parte Rust (NAK) salga en AArch64.
# prototype2-nx lo hace exportando MESA_SWITCH_RUST_TARGET y agregando el target de rustup; el script de masseffect-nx
# (que usamos para el resto) no lo hace, y sin eso libnak_rs.a sale en x86 y el enlazador dice "incompatible".
# Uso: mesa_patch_build_switch.sh <ruta/build-switch.sh>   (idempotente)
set -euo pipefail
F="$1"
D="$(cd "$(dirname "$F")" && pwd)"
# Herramientas de Rust que corren en el PC (proc-macros como paste/syn): deben usar el rustc real, no el wrapper de
# /usr/local/libexec (que esta primero en PATH y fuerza AArch64). Es el papel del mesa-native.ini de prototype2.
cat > "$D/mesa-native.ini" <<'INI'
[binaries]
rust = ['/root/.cargo/bin/rustc']
INI
if ! grep -q MESA_SWITCH_RUST_TARGET "$F"; then
  sed -i -e 's|^run() { docker exec "\$CONTAINER_NAME"|run() { docker exec -e MESA_SWITCH_RUST_TARGET=aarch64-unknown-linux-gnu "$CONTAINER_NAME"|' "$F"
  grep -q MESA_SWITCH_RUST_TARGET "$F" || { echo "ERROR: no se pudo parchear run() en $F" >&2; exit 1; }
  sed -i -e 's|^    --cross-file switch_cross_file.txt \\$|    --cross-file switch_cross_file.txt --native-file /project/mesa-native.ini \\|' "$F"
  grep -q 'native-file /project/mesa-native.ini' "$F" || { echo "ERROR: no se pudo agregar --native-file en $F" >&2; exit 1; }
  sed -i -e '/^run() { docker exec/a run "rustup target add aarch64-unknown-linux-gnu"' "$F"
  echo "== build-switch.sh parcheado: Rust -> aarch64-unknown-linux-gnu"
fi
