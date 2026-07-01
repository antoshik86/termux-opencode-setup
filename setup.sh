#!/data/data/com.termux/files/usr/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Termux opencode Setup ==="
echo ""

# 1. Обновление пакетов
echo "[1/8] Обновление пакетов..."
pkg update -y && pkg upgrade -y

# 2. Установка базовых пакетов
echo "[2/8] Установка инструментов..."
pkg install -y git curl gh nodejs python make openssh

# 3. Установка glibc (нужен для opencode)
echo "[3/8] Установка glibc..."
pkg install -y glibc-repo
pkg update
pkg install -y glibc glibc-runner

# 4. opencode
echo "[4/8] Установка opencode..."

install_opencode_wrapper() {
  local wrapper_src="$SCRIPT_DIR/configs/opencode-wrapper.sh"
  local wrapper_dst="$HOME/.opencode/bin/opencode-wrapper"
  mkdir -p "$HOME/.opencode/bin"
  cp "$wrapper_src" "$wrapper_dst"
  chmod +x "$wrapper_dst"
  if ! grep -q "opencode-wrapper" "$HOME/.bashrc" 2>/dev/null; then
    echo 'alias opencode="$HOME/.opencode/bin/opencode-wrapper"' >> "$HOME/.bashrc"
  fi
  echo "  opencode-wrapper установлен"
}

if command -v opencode &>/dev/null; then
  opener=$(command -v opencode)
  if file "$opener" 2>/dev/null | grep -q "ELF"; then
    if ! "$opener" --version &>/dev/null; then
      echo "  opencode найден, но не запускается (ошибка required file not found)"
      echo "  Устанавливаю обёртку для glibc..."
      install_opencode_wrapper
    else
      echo "  opencode уже работает: $("$opener" --version 2>/dev/null || echo "?")"
    fi
  else
    echo "  opencode уже установлен (npm): $(opencode --version 2>/dev/null || echo "?")"
  fi
elif [ -f ~/.opencode/bin/opencode ]; then
  echo "  opencode найден в ~/.opencode/bin"
  install_opencode_wrapper
else
  echo "  Устанавливаю opencode через npm..."
  npm install -g opencode-ai
fi

# 5. PLUR
echo "[5/8] Установка PLUR..."
npm install -g @plur-ai/mcp

# 6. Конфиги
echo "[6/8] Копирование конфигов..."
cp "$SCRIPT_DIR/configs/bashrc" ~/.bashrc
mkdir -p ~/.config/opencode
cp "$SCRIPT_DIR/configs/opencode.jsonc" ~/.config/opencode/
mkdir -p ~/.termux
cp "$SCRIPT_DIR/configs/termux.properties" ~/.termux/termux.properties

# 7. Скиллы opencode
echo "[7/8] Установка скиллов opencode..."
while IFS= read -r skill; do
  if [ -n "$skill" ]; then
    echo "  -> $skill"
    git clone "https://github.com/opencode-ai/skill-${skill}" \
      ~/.config/opencode/skills/${skill} 2>/dev/null || echo "  уже есть"
  fi
done < "$SCRIPT_DIR/skills.txt"

# 8. Перезагрузка Termux
echo "[8/8] Применение настроек..."
termux-reload-settings

echo ""
echo "=== Готово! ==="
echo "Проверь установку:"
echo "  opencode --version"
echo "  node --version"
echo "  python3 --version"
