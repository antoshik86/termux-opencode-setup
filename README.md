# Termux opencode Setup

[![Release](https://img.shields.io/github/v/release/antoshik86/termux-opencode-setup)](https://github.com/antoshik86/termux-opencode-setup/releases/latest)

Готовая сборка Termux + opencode + PLUR + инструменты для разработки на Android.

Эта инструкция проведёт тебя шаг за шагом от установки Termux до готовой рабочей среды с ИИ-ассистентом.

⚠️ **Важно:** Termux использует библиотеку Bionic (как в Android), а opencode собран под glibc (как в обычном Linux). Поэтому opencode нужно запускать через специальную прослойку — glibc-загрузчик. В этой сборке всё настроено автоматически.

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

## Подготовка (обязательно для всех способов)

Сначала установи Termux и дай ему доступ к файлам.

### 1. Установить Termux

Скачай Termux из **F-Droid**. Google Play не подходит — там старая версия.

- Скачай F-Droid: https://f-droid.org/F-Droid.apk — установи
- Открой F-Droid, найди **Termux**, нажми **Install**
- Версия должна быть **0.119.0-beta.3** или новее

> ❗ Если Termux уже стоит из Google Play — удали и поставь из F-Droid.

### 2. Дать разрешения

Открой Termux. Введи:

```bash
termux-setup-storage
```

На экране телефона появится запрос — нажми **Allow** (Разрешить).

> ✅ После этого появится папка `storage/` — ссылка на твои файлы.

Готово. Теперь выбирай способ установки:

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

## Способ 2: Установка с релиза (без npm, быстрее)

Если не хочешь ждать `npm install` — opencode ставится сразу из готового бинарника.

**ВАЖНО:** Бинарник из GitHub releases собран под обычный Linux (glibc).
Termux использует другую libc (Bionic).
Поэтому бинарник нужно запускать через glibc-загрузчик.
Скрипт `opencode-wrapper.sh` делает это автоматически + сбрасывает `LD_PRELOAD`.

```bash
# Шаг 1 — обновление + базовые пакеты
pkg update && pkg upgrade -y
pkg install -y git curl glibc-repo glibc glibc-runner

# Шаг 2 — скачать сборку
git clone https://github.com/antoshik86/termux-opencode-setup
cd termux-opencode-setup

# Шаг 3 — скачать последний релиз opencode
# Нужна glibc-версия (не musl!)
mkdir -p ~/.opencode/bin
curl -L https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-arm64.tar.gz \
  | tar xz -C ~/.opencode/bin/ opencode
chmod +x ~/.opencode/bin/opencode

# Шаг 4 — установить скрипт-обёртку вместо прямой ссылки
# Обёртка сама найдёт glibc-загрузчик и запустит через него
cp configs/opencode-wrapper.sh ~/.opencode/bin/opencode-wrapper
chmod +x ~/.opencode/bin/opencode-wrapper

# Шаг 5 — добавить в PATH команду opencode
echo 'alias opencode="$HOME/.opencode/bin/opencode-wrapper"' >> ~/.bashrc
source ~/.bashrc

# Шаг 6 — запустить остальной установщик (конфиги, скиллы, PLUR)
# setup.sh увидит, что opencode уже есть, и не будет ставить через npm
bash setup.sh
```

---

## Способ 3: Ручная установка (подробно)

Если ты уже прошёл раздел **Подготовка** выше — Termux стоит, разрешения даны. Теперь делай шаг за шагом.

### Шаг 1. Обновить пакеты

Введи (можно скопировать и вставить — нажми и держи на экране, выбери Paste):

```bash
pkg update && pkg upgrade -y
```

Будет идти загрузка — подожди, пока не вернётся курсор.

> ⏳ Если спросит "Do you want to continue?" — нажми `y` и Enter.

### Шаг 2. Установить базовые инструменты

```bash
pkg install -y git curl gh nodejs python make openssh
```

Подожди, пока всё скачается и установится.

### Шаг 3. Установить glibc (обязательно)

```bash
pkg install -y glibc-repo
pkg update
pkg install -y glibc glibc-runner
```

> ❗ Без этого шага opencode не запустится. Если получил ошибку — попробуй выйти из Termux (смахиванием) и открыть заново.

### Шаг 4. Установить opencode

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
>
> ❌ Если пишет "cannot execute: required file not found" — бинарник не может найти glibc.
> **Решение:** запускай через `opencode-wrapper.sh` (см. Способ 2).
> Или установи через npm: `npm install -g opencode-ai`.

### Шаг 5. Установить PLUR (память для opencode)

```bash
npm install -g @plur-ai/mcp
```

### Шаг 6. Скопировать конфиги

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

### Шаг 7. Установить скиллы opencode

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

### Шаг 8. Проверить, что всё работает

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

## Обновление opencode

Когда выходит новая версия — обновляйся.

### Если ставил через npm (Способ 1 или 3)

```bash
npm update -g opencode-ai
opencode --version
```

### Если ставил бинарник (Способ 2)

```bash
# Скачать новую версию поверх старой
curl -L https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-arm64.tar.gz \
  | tar xz -C ~/.opencode/bin/ opencode
chmod +x ~/.opencode/bin/opencode

# Обёртку обновлять не надо — она просто запускает бинарник
opencode --version
```

### Обновление всей сборки

```bash
cd ~/termux-opencode-setup
git pull
bash setup.sh
```

setup.sh сам заметит, что opencode уже есть, и обновит только конфиги/скиллы.

---

## Если что-то пошло не так

| Проблема | Решение |
|---|---|
| `pkg: command not found` | Ты не в Termux, а в обычном терминале Android. Открой приложение Termux. |
| `opencode: command not found` | Закрой и открой Termux заново. Или выполни: `export PATH="$HOME/.opencode/bin:\$PATH"` |
| `Cannot read properties of null` | Не установлен glibc. Вернись к Шагу 3. |
| `cannot execute: required file not found` | Бинарник собран под обычный Linux, а Termux использует Bionic. Нужно запускать через glibc-загрузчик. Решение: используй `opencode-wrapper.sh` (см. Способ 2) или ставь через `npm install -g opencode-ai`. |
| `Permission denied` | Не дал разрешения. Выполни `termux-setup-storage` и нажми Allow. |

---

## Релизы

Все версии и готовые бинарники — на странице релизов:
https://github.com/antoshik86/termux-opencode-setup/releases

В каждом релизе:
| Файл | Описание |
|---|---|
| `opencode-v{version}-linux-arm64.tar.gz` | Бинарник под Linux ARM64 (glibc). **Его нужно скачивать.** |
| `setup.sh` | Автоустановщик |

> Бинарники opencode (не musl!) можно брать с официальных релизов:
> `https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-arm64.tar.gz`
>
> musl-версия НЕ подходит для Termux. Нужна именно glibc.

---

## Структура репозитория

```
termux-opencode-setup/
├── README.md                 # Эта инструкция (ты читаешь её)
├── setup.sh                  # Автоустановщик — запусти и забудь
├── configs/
│   ├── bashrc                # Настройки терминала
│   ├── opencode.jsonc        # Настройки opencode
│   ├── opencode-wrapper.sh   # Скрипт для запуска glibc-бинарника в Termux
│   └── termux.properties     # Клавиатура и внешний вид Termux
└── skills.txt                # Список скиллов для установки
```
