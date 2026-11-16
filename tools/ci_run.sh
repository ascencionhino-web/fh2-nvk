#!/usr/bin/env bash
# Ejecuta un comando y, si falla, publica las lineas de error como anotacion de GitHub (se leen en el resumen de la
# ejecucion y por API) en vez de obligar a abrir el registro. Uso: ci_run.sh <titulo> <comando...>
set -uo pipefail
T="$1"; shift
LOG="$(mktemp)"
"$@" 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
if [ "$rc" -ne 0 ]; then
  esc() { sed -e 's/%/%25/g' -e 's/\r//g' | cut -c1-260 | awk '{printf "%s%%0A",$0}'; }
  ERR="$(grep -nE -i 'error|fatal|undefined reference|FAILED|cannot|denied|incompatible|not found' "$LOG" | tail -14 | esc)"
  TAIL="$(tail -n 8 "$LOG" | esc)"
  echo "::error title=$T fallo (codigo $rc)::LINEAS CON ERROR:%0A${ERR}%0AFINAL DEL REGISTRO:%0A${TAIL}" | cut -c1-60000
fi
exit "$rc"
