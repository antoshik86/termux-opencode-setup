#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_VERSION="2.0"

# Не спрашивать логин/пароль от GitHub
export GIT_ASKPASS=echo

# Найти папку с configs/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
while [ ! -d "$SCRIPT_DIR/configs" ] && [ "$SCRIPT_DIR" != "/" ]; do
  SCRIPT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
done
if [ ! -d "$SCRIPT_DIR/configs" ]; then
  echo "Ошибка: не найдена папка configs/ в репозитории"
  exit 1
fi

# Автообновление — git pull если это git-репозиторий
if [ -d "$SCRIPT_DIR/.git" ]; then
  cd "$SCRIPT_DIR"
  git remote update 2>/dev/null || true
  behind=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
  if [ "$behind" -gt 0 ]; then
    echo "→ Доступно обновление скрипта. Обновляю..."
    git pull --ff-only 2>&1 | tail -1
    echo "→ Перезапусти скрипт заново: bash setup.sh"
    exit 0
  fi
  cd - >/dev/null
fi

# Проверка что все нужные файлы на месте
for f in configs/bashrc configs/opencode.jsonc configs/opencode-wrapper.sh configs/termux.properties skills.txt; do
  if [ ! -f "$SCRIPT_DIR/$f" ]; then
    echo "Ошибка: не найден файл $f в репозитории"
    echo "Скачай свежую версию: git pull"
    exit 1
  fi
done

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "  ${RED}✖ $1${NC}"; }
info() { echo -e "  ${CYAN}→ $1${NC}"; }
header() { echo -e "\n${CYAN}=== $1 ===${NC}"; }

echo -e "${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║     Termux opencode Setup v$SCRIPT_VERSION      ║"
echo "║     https://github.com/antoshik86   ║"
echo "║     termux-opencode-setup           ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

MIN_SPACE_MB=500
ERRORS=0

# Сохраняем весь вывод в лог-файл
LOG_FILE="$HOME/opencode-install.log"
echo "=== Termux opencode Setup v$SCRIPT_VERSION ===" > "$LOG_FILE"
echo "Дата: $(date)" >> "$LOG_FILE"
echo "Устройство: $(getprop ro.product.model 2>/dev/null || echo '?')" >> "$LOG_FILE"
echo "Android: $(getprop ro.build.version.release 2>/dev/null || echo '?')" >> "$LOG_FILE"
echo "Архитектура: $(uname -m 2>/dev/null || echo '?')" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
# Дублируем вывод в лог
exec > >(tee -a "$LOG_FILE") 2>&1

# --------------------------------------------------
header "Проверка системы"

# Проверка, что мы в Termux
if [ ! -d /data/data/com.termux ]; then
  fail "Этот скрипт должен запускаться в Termux на Android!"
  fail "Открой приложение Termux на телефоне и запусти заново."
  exit 1
fi
ok "Termux обнаружен"

# Проверка разрешений storage
if [ ! -d ~/storage ]; then
  warn "Нет доступа к файлам. Выполни: termux-setup-storage"
  warn "(на экране телефона нажми РАЗРЕШИТЬ / ALLOW)"
  echo ""
  info "Жду подтверждения... (нажми Enter когда дашь разрешение)"
  read -r
  if [ ! -d ~/storage ]; then
    fail "Доступ к файлам не получен. Попробуй перезапустить Termux."
    exit 1
  fi
fi
ok "Доступ к файлам есть"

# Проверка места
available_kb=$(df -k /data/data/com.termux/files/home | tail -1 | awk '{print $4}')
available_mb=$((available_kb / 1024))
if [ "$available_mb" -lt "$MIN_SPACE_MB" ]; then
  fail "Мало места на телефоне!"
  fail "Доступно: ${available_mb} MB, нужно минимум ${MIN_SPACE_MB} MB"
  fail "Освободи место (удали фото/видео/приложения) и запусти скрипт снова."
  exit 1
fi
ok "Места достаточно: ${available_mb} MB свободно"

# Проверка интернета
if ! ping -c 1 github.com &>/dev/null && ! ping -c 1 8.8.8.8 &>/dev/null; then
  fail "Нет интернета! Подключи Wi-Fi или мобильный интернет."
  exit 1
fi
ok "Интернет работает"

# --------------------------------------------------
header "1. Обновление пакетов Termux"

if pkg update -y 2>&1 | tail -3; then
  ok "Список пакетов обновлён"
else
  warn "Не удалось обновить список пакетов (возможно проблема с зеркалом)"
  warn "Попробую продолжить..."
fi

if pkg upgrade -y 2>&1 | tail -3; then
  ok "Пакеты обновлены"
else
  warn "Не все пакеты обновились, продолжаю..."
fi

# --------------------------------------------------
header "2. Установка базовых инструментов"

pkg install -y git curl gh nodejs python make openssh file 2>&1 | tail -1
ok "Git, curl, Node.js, Python, gh, make, openssh, file установлены"

# Настраиваем git на использование GitHub токена (чтобы не было rate limit)
if command -v gh &>/dev/null; then
  gh auth setup-git 2>/dev/null || true
fi

# --------------------------------------------------
header "3. Установка glibc (нужна для запуска opencode)"

pkg install -y glibc-repo 2>&1 | tail -1
pkg update 2>&1 | tail -1
pkg install -y glibc glibc-runner 2>&1 | tail -1

GLIBC_LIBDIR="/data/data/com.termux/files/usr/glibc/lib"
GLIBC_LOADER="$GLIBC_LIBDIR/ld-linux-aarch64.so.1"

if [ -x "$GLIBC_LOADER" ]; then
  ok "glibc установлен: $("$GLIBC_LOADER" --version 2>&1 | head -1)"
else
  fail "glibc не установился!"
  fail "Попробуй перезапустить Termux и выполнить вручную:"
  fail "  pkg install -y glibc-repo"
  fail "  pkg update"
  fail "  pkg install -y glibc glibc-runner"
  exit 1
fi

# --------------------------------------------------
header "4. Установка opencode"

install_opencode_wrapper() {
  local wrapper_src="$SCRIPT_DIR/configs/opencode-wrapper.sh"
  local bin_dir="$HOME/.opencode/bin"
  mkdir -p "$bin_dir"
  # Переименовываем бинарник → opencode-bin (чтоб не конфликтовал с обёрткой)
  if [ -x "$bin_dir/opencode" ] && [ ! -f "$bin_dir/opencode-bin" ]; then
    if file "$bin_dir/opencode" 2>/dev/null | grep -q "ELF"; then
      mv "$bin_dir/opencode" "$bin_dir/opencode-bin"
    fi
  fi
  # Ставим обёртку как opencode
  cp "$wrapper_src" "$bin_dir/opencode"
  chmod +x "$bin_dir/opencode"
  # Добавляем ~/.opencode/bin в PATH, если ещё нет
  if ! grep -q '\.opencode/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> "$HOME/.bashrc"
  fi
  # Если старый бинарник лежит в другом месте PATH — удаляем
  local old_bin
  old_bin=$(command -v opencode 2>/dev/null || true)
  if [ -n "$old_bin" ] && [ "$old_bin" != "$bin_dir/opencode" ] && [ -x "$old_bin" ]; then
    if file "$old_bin" 2>/dev/null | grep -q "ELF"; then
      rm -f "$old_bin" 2>/dev/null || true
    fi
  fi
  ok "Обёртка glibc установлена (бинарник → opencode-bin, обёртка → opencode)"
}

# Пробуем скачать бинарник (быстрее чем npm install)
info "Скачиваю последнюю версию opencode..."
mkdir -p ~/.opencode/bin

TEMP_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
TEMP_FILE="$TEMP_DIR/opencode.tar.gz"
BIN_URL="https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-arm64.tar.gz"

BINARY_OK=false

if curl -L --connect-timeout 10 --speed-time 30 --speed-limit 10000 \
  -o "$TEMP_FILE" "$BIN_URL" 2>&1; then
  tar xzf "$TEMP_FILE" -C ~/.opencode/bin/ opencode 2>/dev/null && \
  chmod +x ~/.opencode/bin/opencode
  rm -f "$TEMP_FILE"

  if [ -x ~/.opencode/bin/opencode ]; then
    ok "Бинарник opencode скачан"
    BINARY_OK=true
  else
    warn "Не удалось распаковать бинарник"
  fi
else
  warn "Не удалось скачать бинарник"
  rm -f "$TEMP_FILE"
fi

if [ "$BINARY_OK" = true ]; then
  # Пробуем запустить через glibc-загрузчик
  if "$GLIBC_LOADER" --library-path "$GLIBC_LIBDIR" \
    ~/.opencode/bin/opencode --version &>/dev/null; then
    ok "opencode работает через glibc"
  else
    warn "Бинарнику нужна glibc-обёртка"
    install_opencode_wrapper
  fi
else
  info "Бинарник не подошёл — пробую установить через npm..."
  if npm install -g opencode-ai 2>&1 | tail -5; then
    ok "opencode установлен через npm"
  else
    # Иногда npm ругается на cpu — игнорируем и пробуем запустить что поставилось
    if command -v opencode &>/dev/null; then
      ok "opencode установлен через npm"
    else
      warn "npm не смог установить opencode-ai"
      warn ""
      warn "Попробуй вручную установить последнюю версию:"
      warn "  curl -L https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-arm64.tar.gz"
      warn "    | tar xz -C ~/.opencode/bin/ opencode"
      warn "  chmod +x ~/.opencode/bin/opencode"
      warn "  source ~/.bashrc"
      info "  и перезапусти скрипт: bash setup.sh"
      ERRORS=$((ERRORS+1))
    fi
  fi
fi

# Проверка что opencode реально работает
export PATH="$HOME/.opencode/bin:$PATH"
if command -v opencode &>/dev/null; then
  ver=$(opencode --version 2>/dev/null || echo "?")
  ok "opencode готов: $ver"
else
  if [ -x "$HOME/.opencode/bin/opencode" ]; then
    ver=$("$HOME/.opencode/bin/opencode" --version 2>/dev/null || echo "?")
    ok "opencode готов: $ver"
  else
    warn "opencode не найден в PATH. После установки перезапусти Termux."
    ERRORS=$((ERRORS+1))
  fi
fi

# --------------------------------------------------
header "5. Установка PLUR (память для opencode)"

if npm install -g @plur-ai/mcp 2>&1 | tail -3; then
  ok "PLUR установлен"
else
  warn "PLUR не установился (не критично, можно доставить позже: npm install -g @plur-ai/mcp)"
fi

# --------------------------------------------------
header "6. Настройка конфигов"

cp "$SCRIPT_DIR/configs/bashrc" ~/.bashrc 2>/dev/null && ok "bashrc скопирован" || warn "bashrc не скопирован"
mkdir -p ~/.config/opencode
cp "$SCRIPT_DIR/configs/opencode.jsonc" ~/.config/opencode/ 2>/dev/null && ok "opencode.jsonc скопирован" || warn "opencode.jsonc не скопирован"
mkdir -p ~/.termux
cp "$SCRIPT_DIR/configs/termux.properties" ~/.termux/termux.properties 2>/dev/null && ok "termux.properties скопирован" || warn "termux.properties не скопирован"

# Применяем настройки Termux
termux-reload-settings 2>/dev/null && ok "Настройки Termux применены (появились кнопки ESC, TAB, CTRL)" || warn "Не удалось применить настройки"

# --------------------------------------------------
header "7. Установка скиллов opencode"

SKILL_OK=0
SKILL_FAIL=0
while IFS= read -r skill; do
  if [ -n "$skill" ]; then
    SKILL_DIR="$HOME/.config/opencode/skills/${skill}"
    if [ -d "$SKILL_DIR" ]; then
      ok "  $skill (уже есть)"
      SKILL_OK=$((SKILL_OK+1))
    else
      if git clone --depth 1 "https://github.com/opencode-ai/skill-${skill}" "$SKILL_DIR" 2>/dev/null; then
        ok "  $skill"
        SKILL_OK=$((SKILL_OK+1))
      else
        warn "  $skill (не удалось скачать — пропускаю)"
        SKILL_FAIL=$((SKILL_FAIL+1))
      fi
      # Маленькая пауза между клонированиями — чтобы GitHub не банил
      sleep 0.5
    fi
  fi
done < "$SCRIPT_DIR/skills.txt"
ok "Скиллов установлено: $SKILL_OK, ошибок: $SKILL_FAIL"

# --------------------------------------------------
header "8. Проверка установки"

check() {
  local cmd="$1" label="$2"
  if command -v "$cmd" &>/dev/null; then
    local ver
    ver=$("$cmd" --version 2>&1 | head -1)
    ok "$label: $ver"
  elif [ -x "$HOME/.opencode/bin/opencode" ]; then
    local ver
    ver=$("$HOME/.opencode/bin/opencode" --version 2>&1 | head -1)
    ok "$label: $ver"
  elif [ -x "$HOME/.opencode/bin/opencode-bin" ]; then
    local ver
    ver=$("$HOME/.opencode/bin/opencode-bin" --version 2>&1 | head -1)
    ok "$label: $ver (бинарник, без обёртки)"
  else
    warn "$label: НЕ НАЙДЕН"
    ERRORS=$((ERRORS+1))
  fi
}

check opencode   "opencode"
check node       "Node.js"
check python3    "Python 3"
check gh         "GitHub CLI"

# --------------------------------------------------
echo ""
echo -e "${GREEN}══════════════════════════════════════${NC}"
echo -e "${GREEN}  Установка завершена!${NC}"
echo -e "${GREEN}══════════════════════════════════════${NC}"
echo ""

if [ "$ERRORS" -gt 0 ]; then
  warn "Завершилось с $ERRORS ошибками"
  echo ""
  echo "  ========== ЛОГ ОШИБКИ =========="
  echo "  Устройство: $(getprop ro.product.model 2>/dev/null || echo '?')"
  echo "  Android: $(getprop ro.build.version.release 2>/dev/null || echo '?')"
  echo ""
  echo "  Скопируй весь текст выше и отправь разработчику"
  echo "  (Telegram, WhatsApp, — как удобно)"
  echo ""
  echo "  Лог сохранён в файле:"
  echo "    cat ~/opencode-install.log"
  echo "  ================================="
  echo ""
fi

echo "  Теперь просто напиши: opencode"
echo "  Первый вопрос: привет"
echo ""
echo "  Запускаю opencode через 3 секунды..."
echo "  (нажми Ctrl+C чтобы отменить)"
sleep 3

export PATH="$HOME/.opencode/bin:$PATH"
if command -v opencode &>/dev/null; then
  echo ""
  opencode
elif [ -x "$HOME/.opencode/bin/opencode-bin" ]; then
  echo ""
  echo "  (запускаю бинарник напрямую, без обёртки)"
  "$HOME/.opencode/bin/opencode-bin"
else
  warn "Не удалось запустить opencode автоматически"
  warn "Закрой Termux и открой заново, потом напиши: opencode"
fi

echo ""
echo "  Если opencode не запускается:"
echo "    - Закрой Termux и открой заново"
echo "    - Выполни: source ~/.bashrc"
echo "    - Выполни: $HOME/.opencode/bin/opencode --version"
echo ""
