REGISTRY_NAME := blogicum
IMAGE_NAME := app

REGISTRY_ID := $(shell yc container registry get $(REGISTRY_NAME) | awk '/^id:/ {print $$2}')
FOLDER_ID := $(shell yc config get folder-id)
CLOUD_ID := $(shell yc config get cloud-id)

create-registry:
	yc container registry create --name $(REGISTRY_NAME)

delete-registry: clean-registry
	yc container registry delete --name $(REGISTRY_NAME)

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
		sleep 30; \
	fi

destroy:
	terraform -chdir=terraform destroy \
		-var="token=$(YC_TOKEN)" \
		-var="app_image_url=cr.yandex/$(REGISTRY_ID)/${IMAGE_NAME}:latest" \
		-var="folder_id=$(FOLDER_ID)" \
		-var="cloud_id=$(CLOUD_ID)" \
		-var-file=variables.tfvars \
		-auto-approve

plan:
	terraform -chdir=terraform plan \
		-var="token=$(YC_TOKEN)" \
		-var="app_image_url=cr.yandex/$(REGISTRY_ID)/${IMAGE_NAME}:latest" \
		-var="folder_id=$(FOLDER_ID)" \
		-var="cloud_id=$(CLOUD_ID)" \
		-var-file=variables.tfvars

apply:
	terraform -chdir=terraform apply \
		-var="token=$(YC_TOKEN)" \
		-var="app_image_url=cr.yandex/$(REGISTRY_ID)/${IMAGE_NAME}:latest" \
		-var="folder_id=$(FOLDER_ID)" \
		-var="cloud_id=$(CLOUD_ID)" \
		-var-file=variables.tfvars \
		-auto-approve

clone-build-push:
	./scripts/build_and_push.sh git@github.com:Digital-Activists/yandex-cloud-blog-application.git cr.yandex/${REGISTRY_ID}/${IMAGE_NAME}:latest