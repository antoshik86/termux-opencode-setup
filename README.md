# Termux opencode Setup

Готовая сборка Termux + opencode + PLUR + инструменты для разработки на Android.

## Состав

| Компонент | Описание |
|---|---|
| **Termux** | Эмулятор терминала для Android (F-Droid) |
| **opencode** | AI-ассистент для кодинга в терминале |
| **Node.js** | JavaScript-рантайм |
| **Python** | Язык программирования |
| **Git / GitHub CLI** | Контроль версий |
| **PLUR MCP** | Персистентная память для агентов |
| **glibc** | GNU C Library (требуется для opencode) |
| **12 скиллов opencode** | agent-army, dictionary, skeleton-key и др. |

## Быстрая установка

```bash
pkg update && pkg upgrade -y
pkg install -y git
git clone https://github.com/antoshik86/termux-opencode-setup
cd termux-opencode-setup
bash setup.sh
```

## Установка вручную (если автоскрипт не сработал)

### 1. Установить Termux

Скачать с **F-Droid** (не Google Play!):
https://f-droid.org/packages/com.termux/

### 2. Дать разрешения

После запуска Termux выполнить:
```bash
termux-setup-storage
```
Нажать **Allow**.

### 3. Обновить пакеты

```bash
pkg update && pkg upgrade -y
```

### 4. Установить инструменты

```bash
pkg install -y git curl gh nodejs python make openssh glibc-repo
pkg update
pkg install -y glibc glibc-runner
```

### 5. Установить opencode

```bash
npm install -g opencode-ai
```

Проверка: `opencode --version`

### 6. Установить PLUR

```bash
npm install -g @plur-ai/mcp
```

### 7. Скопировать конфиги

```bash
cp configs/bashrc ~/.bashrc
mkdir -p ~/.config/opencode
cp configs/opencode.jsonc ~/.config/opencode/
cp configs/termux.properties ~/.termux/termux.properties
termux-reload-settings
```

### 8. Установить скиллы opencode

```bash
cat skills.txt | while read skill; do
  git clone "https://github.com/opencode-ai/skill-${skill}" \
    ~/.config/opencode/skills/${skill}
done
```

### 9. Настроить SSH для GitHub (опционально)

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub
```
Ключ добавить на https://github.com/settings/keys

### 10. Перезагрузить Termux

Проверить:
```bash
opencode --version   # opencode
node --version       # Node.js
python3 --version    # Python
gh --version         # GitHub CLI
```

## Структура репозитория

```
termux-opencode-setup/
├── README.md         # Эта инструкция
├── setup.sh          # Автоустановщик
├── configs/
│   ├── bashrc        # Конфиг оболочки
│   ├── opencode.jsonc # Конфиг opencode
│   └── termux.properties # Внешний вид Termux
└── skills.txt        # Список скиллов opencode
```
