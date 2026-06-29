#!/data/data/com.termux/files/usr/bin/bash
set -e

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

# 4. opencode (пропускаем, если уже установлен из бинарника)
echo "[4/8] Установка opencode..."
if command -v opencode &>/dev/null; then
  echo "  opencode уже установлен: $(opencode --version)"
elif [ -f ~/.opencode/bin/opencode ]; then
  echo "  opencode уже установлен в ~/.opencode"
else
  npm install -g opencode-ai
fi

# 5. PLUR
echo "[5/8] Установка PLUR..."
npm install -g @plur-ai/mcp

# 6. Конфиги
echo "[6/8] Копирование конфигов..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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
