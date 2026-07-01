#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ============================================================
# opencode-wrapper.sh
# Запускает opencode в Termux через glibc-загрузчик.
# Решает ошибку "cannot execute: required file not found".
# ============================================================

# Где лежит бинарник opencode
OPENCODE_BIN="${OPENCODE_BIN:-$HOME/.opencode/bin/opencode}"

# Путь к glibc в Termux
GLIBC_LIBDIR="/data/data/com.termux/files/usr/glibc/lib"
GLIBC_LOADER="$GLIBC_LIBDIR/ld-linux-aarch64.so.1"

# Сбросить LD_PRELOAD — Termux ставит свою прослойку для bionic,
# она ломает запуск glibc-программ
unset LD_PRELOAD

if [[ ! -x "$OPENCODE_BIN" ]]; then
  echo "Ошибка: бинарник opencode не найден по пути $OPENCODE_BIN" >&2
  echo "Скачай его: https://github.com/antoshik86/termux-opencode-setup/releases" >&2
  exit 1
fi

if [[ -x "$GLIBC_LOADER" ]]; then
  exec "$GLIBC_LOADER" --library-path "$GLIBC_LIBDIR" "$OPENCODE_BIN" "$@"
else
  echo "Ошибка: glibc не установлен. Выполни: pkg install glibc-repo glibc glibc-runner" >&2
  exit 1
fi
