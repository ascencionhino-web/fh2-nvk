#!/usr/bin/env bash
# Compila el driver NVK de Mesa para Switch (Docker). Resultado: out/mesa-sdk/opt/devkitpro/portlibs/switch/lib/libvulkan.a
# Usa el script de masseffect-nx, pero con el parche de Mesa de prototype2-nx (que ya aplicó setup_deps.sh).
# Primera vez: ~1 hora o mas y ~15 GB de disco.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REF="$ROOT/reference"
OUT="$ROOT/out/mesa-sdk"
mkdir -p "$OUT" "$ROOT/out"
[ -d "$REF/mesa-switch-src/.git" ] || { echo "Falta reference/mesa-switch-src: corre tools/setup_deps.sh mesa" >&2; exit 1; }

PATCHED="$ROOT/out/build_mesa_docker.sh"
# Docker crea los archivos como root: el mv final (y el chown) se hacen con sudo si hace falta.
sed -e "s|^PATCH=.*|PATCH=\"$ROOT/out/mesa-switch-fh2.patch\"|" \
    -e 's|^mv "\$SRC/builddir-switch/libvulkan_merged.a" "\$LIBDIR/libvulkan.a"|sudo mv -f "$SRC/builddir-switch/libvulkan_merged.a" "$LIBDIR/libvulkan.a"|' \
    -e "s|^  \./build-switch\.sh\$|  bash \"$ROOT/tools/mesa_patch_build_switch.sh\" build-switch.sh \&\& ./build-switch.sh|" \
    "$REF/masseffect-nx/mesa/build_mesa_docker.sh" > "$PATCHED"
grep -q 'mesa_patch_build_switch' "$PATCHED" || { echo "ERROR: no se pudo enganchar el parche de build-switch.sh" >&2; exit 1; }
chmod +x "$PATCHED"
grep -q '^sudo mv -f' "$PATCHED" || { echo "ERROR: no se pudo parchear el mv del script de Mesa" >&2; exit 1; }
SRC="$REF/mesa-switch-src" OUT="$OUT" bash "$PATCHED"
sudo chown -R "$(id -u):$(id -g)" "$OUT" "$REF/mesa-switch-src" 2>/dev/null || true

# Comprobacion: el archivo debe traer los parches NVK (mismo chequeo que build_nro.sh de masseffect-nx).
nm="/opt/devkitpro/devkitA64/bin/aarch64-none-elf-nm"
docker run --rm -v "$OUT:/mesa:ro" devkitpro/devkita64:latest bash -c \
  "$nm --defined-only /mesa/opt/devkitpro/portlibs/switch/lib/libvulkan.a | grep -Eq ' [BD] nvk_switch_draw\$'" \
  && echo "OK: libvulkan.a contiene los parches NVK" \
  && docker run --rm -v "$OUT:/mesa:ro" devkitpro/devkita64:latest bash -c \
     "$nm --defined-only /mesa/opt/devkitpro/portlibs/switch/lib/libvulkan.a | grep -Eq ' [BD] nvk_fh2_barreras\$'" \
  && echo "OK: libvulkan.a trae las barreras de FH2" \
  && docker run --rm -v "$OUT:/mesa:ro" devkitpro/devkita64:latest bash -c \
     "$nm --defined-only /mesa/opt/devkitpro/portlibs/switch/lib/libvulkan.a | grep -Eq ' [BD] nvk_fh2_barreras_razones\$'" \
  && echo "OK: libvulkan.a trae las razones del modo 3" \
  || { echo "ERROR: libvulkan.a no trae los parches NVK" >&2; exit 1; }

# Todos los miembros del archivo deben ser AArch64 (si la parte Rust sale en x86, el enlazador del NRO dice "incompatible").
docker run --rm -v "$OUT:/mesa:ro" devkitpro/devkita64:latest bash -c '
  set -e; mkdir /tmp/x; cd /tmp/x
  /opt/devkitpro/devkitA64/bin/aarch64-none-elf-ar x /mesa/opt/devkitpro/portlibs/switch/lib/libvulkan.a
  bad=0; n=0
  for f in *.o; do n=$((n+1)); readelf -h "$f" 2>/dev/null | grep -q "Machine:.*AArch64" || { echo "NO AArch64: $f"; bad=$((bad+1)); }; done
  echo "miembros revisados: $n, no AArch64: $bad"; [ "$n" -gt 0 ] && [ "$bad" -eq 0 ]' \
  && echo "OK: todos los miembros de libvulkan.a son AArch64" \
  || { echo "ERROR: libvulkan.a trae miembros que no son AArch64" >&2; exit 1; }
