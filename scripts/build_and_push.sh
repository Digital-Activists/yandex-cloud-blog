#!/bin/bash

set -e # Выход при ошибке

# --- Глобальная переменная для хранения временной директории ---
TEMP_DIR=""

# --- Функция очистки ---
cleanup() {
	if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
		echo "🧹 Очистка временной директории: $TEMP_DIR"
		rm -rf "$TEMP_DIR"
		echo "✅ Временная директория удалена."
	else
		echo "⚠️ Временная директория не была создана или уже удалена."
	fi
}

# --- Функция вывода справки ---
usage() {
	echo "Использование: $0 <git_repo_url> <container_registry_url> [branch]"
	echo "branch (опционально): ветка Git для клонирования (по умолчанию: main)"
	echo "Пример: $0 https://github.com/user/repo.git cr.yandex/abc123/myapp:latest"
	exit 1
}

if [ "$#" -lt 2 ]; then
	usage
fi

GIT_REPO_URL="$1"
IMAGE_NAME="$2"
GIT_BRANCH="${3:-main}"  # по умолчанию main

# --- Устанавливаем trap на выход (включая ошибки) ---
trap cleanup EXIT

# --- Проверки ---
if ! command -v git &>/dev/null; then
	echo "❌ Ошибка: git не установлен."
	exit 1
fi

if ! command -v docker &>/dev/null; then
	echo "❌ Ошибка: docker не установлен."
	exit 1
fi

if ! docker info &>/dev/null; then
	echo "❌ Ошибка: Docker не запущен или пользователь не авторизован (требуется sudo или добавление в группу docker)."
	exit 1
fi

# --- Создание временной директории ---
TEMP_DIR=$(mktemp -d)
echo "📁 Создана временная директория: $TEMP_DIR"

# --- Клонирование репозитория с указанной веткой ---
CLONE_DIR="$TEMP_DIR/repo_clone"
echo "📦 Клонирую ветку '$GIT_BRANCH' репозитория: $GIT_REPO_URL"
git clone --depth 1 --branch "$GIT_BRANCH" --single-branch "$GIT_REPO_URL" "$CLONE_DIR"

# --- Переход в директорию репозитория ---
cd "$TEMP_DIR/repo_clone"

# --- Проверка наличия Dockerfile ---
if [ ! -f "Dockerfile" ]; then
	echo "❌ Ошибка: Dockerfile не найден в корне репозитория."
	exit 1
fi

# --- Сборка Docker-образа ---
echo "🔨 Собираю Docker-образ"
docker build -t "$IMAGE_NAME" .

# --- Пуш в Container Registry ---
echo "📤 Пушу образ в: $IMAGE_NAME"
docker push "$IMAGE_NAME"

echo "✅ Образ успешно собран и загружен: $IMAGE_NAME"

# trap cleanup EXIT выполнит очистку автоматически
echo "✅ Скрипт завершён успешно."
