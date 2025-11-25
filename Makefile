yc-create-registry:
	yc container registry create --name my-registry

yc-delete-registry:
	yc container registry delete --name my-registry

REGISTRY_NAME := django-app
FOLDER_ID := $(shell yc config get folder-id 2>/dev/null)

.PHONY: clean-registry destroy

# Удаляет все образы из указанного registry
clean-registry:
	@echo "🧹 Очистка образов в registry: $(REGISTRY_NAME)"
	@if [ -z "$(FOLDER_ID)" ]; then \
		echo "❌ yc CLI не настроен или не указан folder_id"; \
		exit 1; \
	fi
	@if ! command -v jq &> /dev/null; then \
		echo "❌ Требуется jq для парсинга JSON"; \
		exit 1; \
	fi
	@yc container registry get --name $(REGISTRY_NAME) >/dev/null || (echo "❌ Registry '$(REGISTRY_NAME)' не найден"; exit 1)
	@echo "🔍 Получение списка образов..."
	@IMAGES=$$(yc container image list --registry-name $(REGISTRY_NAME) --format json | jq -r '.[].id'); \
	if [ -z "$$IMAGES" ]; then \
		echo "✅ Образов не найдено — реестр пуст"; \
	else \
		echo "🗑️ Удаление образов..."; \
		for img in $$IMAGES; do \
			echo "  - Удаляю $$img"; \
			yc container image delete "$$img" --async || echo "  ⚠️ Не удалось удалить $$img"; \
		done; \
	fi

# Выполняет очистку и затем terraform destroy
destroy: clean-registry
	@echo "🔨 Запуск terraform destroy..."
	terraform -chdir=terraform destroy -auto-approve -var-file=variables.tfvars

plan:
	terraform -chdir=terraform plan -var-file=variables.tfvars -auto-approve

apply:
	terraform -chdir=terraform apply -var-file=variables.tfvars -auto-approve