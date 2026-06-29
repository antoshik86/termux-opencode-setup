#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== Termux opencode Setup ==="
echo ""

# 1. Обновление пакетов
echo "[1/7] Обновление пакетов..."
pkg update -y && pkg upgrade -y

# 2. Установка базовых пакетов
echo "[2/7] Установка инструментов..."
pkg install -y git curl gh nodejs python make openssh glibc-repo glibc glibc-runner

# 3. opencode
echo "[3/7] Установка opencode..."
npm install -g opencode-ai

# 4. PLUR
echo "[4/7] Установка PLUR..."
npm install -g @plur-ai/mcp

# 5. Конфиги
echo "[5/7] Копирование конфигов..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cp "$SCRIPT_DIR/configs/bashrc" ~/.bashrc
mkdir -p ~/.config/opencode
cp "$SCRIPT_DIR/configs/opencode.jsonc" ~/.config/opencode/
mkdir -p ~/.termux
cp "$SCRIPT_DIR/configs/termux.properties" ~/.termux/termux.properties

# 6. Скиллы opencode
echo "[6/7] Установка скиллов opencode..."
while IFS= read -r skill; do
  if [ -n "$skill" ]; then
    echo "  -> $skill"
    git clone "https://github.com/opencode-ai/skill-${skill}" \
      ~/.config/opencode/skills/${skill} 2>/dev/null || echo "  уже есть"
  fi
done < "$SCRIPT_DIR/skills.txt"

# 7. Перезагрузка Termux
echo "[7/7] Применение настроек..."
termux-reload-settings

echo ""
echo "=== Готово! ==="
echo "Проверь установку:"
echo "  opencode --version"
echo "  node --version"
echo "  python3 --version"
