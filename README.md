# Termux opencode Setup

Готовая сборка Termux + opencode + PLUR + инструменты для разработки на Android.

Эта инструкция проведёт тебя шаг за шагом от установки Termux до готовой рабочей среды с ИИ-ассистентом.

---

## Что входит в сборку

| Компонент | Зачем нужен |
|---|---|
| **Termux** | Эмулятор терминала на телефоне (как cmd на Windows) |
| **opencode** | AI-ассистент для кода прямо в терминале |
| **Node.js** | Чтобы запускать opencode и другие JS-программы |
| **Python** | Язык для скриптов и автоматизации |
| **Git + GitHub CLI** | Работа с кодом на GitHub |
| **PLUR MCP** | Постоянная память: opencode помнит контекст между сессиями |
| **glibc** | Библиотека, без которой opencode не работает |
| **12 скиллов** | Доп. возможности: автогенерация кода, парсинг сайтов, поиск и т.д. |

---

## Способ 1: Быстрая установка (автомат)

Всё сделается само. Просто скопируй и вставь команды по одной:

```bash
# Шаг 1 — ставим Git
pkg update && pkg upgrade -y
pkg install -y git

# Шаг 2 — скачиваем сборку
git clone https://github.com/antoshik86/termux-opencode-setup

# Шаг 3 — заходим в папку
cd termux-opencode-setup

# Шаг 4 — запускаем установщик
bash setup.sh
```

**Что произойдёт:** скрипт сам обновит пакеты, установит opencode, Node.js, Python, glibc, PLUR, скопирует конфиги и установит 12 скиллов. Ничего нажимать не надо — всё само.

---

## Способ 2: Ручная установка (подробно)

Делай шаг за шагом. Если что-то пошло не так — ищи совет в конце шага.

### Шаг 1. Установить Termux

Скачай Termux из **F-Droid** (Google Play не подходит — там старая версия):

- Сначала установи F-Droid: https://f-droid.org/F-Droid.apk
- Открой F-Droid, найди **Termux** и нажми **Install**
- Версия должна быть **0.119.0-beta.3** или новее

> ❗ Если установил из Google Play — удали и скачай из F-Droid. Иначе opencode не запустится.

### Шаг 2. Дать доступ к файлам

Запусти Termux. Появится чёрный экран с мигающим курсором. Введи:

```bash
termux-setup-storage
```

На экране телефона появится запрос — нажми **Allow** (Разрешить).

> ✅ После этого в домашней папке появится каталог `storage/` — это ссылка на твои фото, музыку, загрузки.

### Шаг 3. Обновить пакеты

Введи (можно скопировать и вставить — нажми и держи на экране, выбери Paste):

```bash
pkg update && pkg upgrade -y
```

Будет идти загрузка — подожди, пока не вернётся курсор.

> ⏳ Если спросит "Do you want to continue?" — нажми `y` и Enter.

### Шаг 4. Установить базовые инструменты

```bash
pkg install -y git curl gh nodejs python make openssh
```

Подожди, пока всё скачается и установится.

### Шаг 5. Установить glibc (обязательно)

```bash
pkg install -y glibc-repo
pkg update
pkg install -y glibc glibc-runner
```

> ❗ Без этого шага opencode не запустится. Если получил ошибку — попробуй выйти из Termux (смахиванием) и открыть заново.

### Шаг 6. Установить opencode

```bash
npm install -g opencode-ai
```

Подожди 1-2 минуты.

Проверь, что установилось:

```bash
opencode --version
```

Должно показать `1.17.11` или похожий номер.

> ❌ Если пишет "command not found" — закрой Termux и открой заново. Если не помогло, выполни: `export PATH="$HOME/.opencode/bin:$PATH"`

### Шаг 7. Установить PLUR (память для opencode)

```bash
npm install -g @plur-ai/mcp
```

### Шаг 8. Скопировать конфиги

Сначала скачай файлы из этого репозитория (если ещё не скачал):

```bash
git clone https://github.com/antoshik86/termux-opencode-setup
cd termux-opencode-setup
```

Теперь скопируй конфиги:

```bash
cp configs/bashrc ~/.bashrc
mkdir -p ~/.config/opencode
cp configs/opencode.jsonc ~/.config/opencode/
mkdir -p ~/.termux
cp configs/termux.properties ~/.termux/termux.properties
termux-reload-settings
```

> 💡 `termux-reload-settings` применит настройки клавиатуры (появятся кнопки ESC, TAB, CTRL сверху).

### Шаг 9. Установить скиллы opencode

```bash
cat skills.txt | while read skill; do
  git clone "https://github.com/opencode-ai/skill-${skill}" \
    ~/.config/opencode/skills/${skill}
done
```

Скиллы — это плагины, которые расширяют возможности opencode. Всего их 12:

| Скилл | Что делает |
|---|---|
| `agent-army` | Запускает несколько агентов параллельно |
| `caveman-mode` | Экономит токены, сокращая текст |
| `dictionary` | Личный словарь терминов |
| `hunger-games` | Выбирает лучшую идею из нескольких |
| `juicy-cookie` | Система наград для агента |
| `method-actor` | Назначает персонажа агенту |
| `plur-memory` | Постоянная память между сессиями |
| `skeleton-key` | Парсит сайты без API |
| `skillception` | Создаёт новые скиллы |
| `sorting-hat` | Выбирает модель по задаче |
| `soul-transplant` | Создаёт твой профиль |
| `treasure-map` | Проектирует архитектуру кода |

### Шаг 10. Проверить, что всё работает

```bash
opencode --version    # opencode — ИИ-ассистент
node --version        # Node.js
python3 --version     # Python
gh --version          # GitHub CLI
```

Все должны показать версии без ошибок.

---

## Что дальше

Открой Termux и напиши:

```bash
opencode
```

Начни с простого вопроса: `"привет"` — opencode ответит и будет готов помогать.

---

## Если что-то пошло не так

| Проблема | Решение |
|---|---|
| `pkg: command not found` | Ты не в Termux, а в обычном терминале Android. Открой приложение Termux. |
| `opencode: command not found` | Закрой и открой Termux заново. Или выполни: `export PATH="$HOME/.opencode/bin:\$PATH"` |
| `Cannot read properties of null` | Не установлен glibc. Вернись к Шагу 5. |
| `Permission denied` | Не дал разрешения. Выполни `termux-setup-storage` и нажми Allow. |

---

## Структура репозитория

```
termux-opencode-setup/
├── README.md            # Эта инструкция (ты читаешь её)
├── setup.sh             # Автоустановщик — запусти и забудь
├── configs/
│   ├── bashrc           # Настройки терминала
│   ├── opencode.jsonc   # Настройки opencode
│   └── termux.properties # Клавиатура и внешний вид Termux
└── skills.txt           # Список скиллов для установки
```
