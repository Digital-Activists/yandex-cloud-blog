REGISTRY_NAME := blogicum
IMAGE_NAME := app

.PHONY: create-registry delete-registry clean-registry destroy plan apply clone-build-push

create-registry:
	yc container registry create --name $(REGISTRY_NAME)

delete-registry: clean-registry
	yc container registry delete --name $(REGISTRY_NAME)

clean-registry:
	@echo "🧹 Очистка образов в registry: $(REGISTRY_NAME)"
	@if ! command -v jq &> /dev/null; then \
		echo "❌ Требуется jq для парсинга JSON"; \
		exit 1; \
	fi
	@FOLDER_ID=$$(yc config get folder-id 2>/dev/null); \
	if [ -z "$$FOLDER_ID" ]; then \
		echo "❌ yc CLI не настроен или не указан folder_id"; \
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
	@FOLDER_ID=$$(yc config get folder-id 2>/dev/null); \
	CLOUD_ID=$$(yc config get cloud-id 2>/dev/null); \
	REGISTRY_ID=$$(yc container registry get $(REGISTRY_NAME) | awk '/^id:/ {print $$2}'); \
	terraform -chdir=terraform destroy \
		-var="token=$(YC_TOKEN)" \
		-var="app_image_url=cr.yandex/$${REGISTRY_ID}/${IMAGE_NAME}:latest" \
		-var="folder_id=$${FOLDER_ID}" \
		-var="cloud_id=$${CLOUD_ID}" \
		-var-file=variables.tfvars \
		-auto-approve

plan:
	@FOLDER_ID=$$(yc config get folder-id 2>/dev/null); \
	CLOUD_ID=$$(yc config get cloud-id 2>/dev/null); \
	REGISTRY_ID=$$(yc container registry get $(REGISTRY_NAME) | awk '/^id:/ {print $$2}'); \
	terraform -chdir=terraform plan \
		-var="token=$(YC_TOKEN)" \
		-var="app_image_url=cr.yandex/$${REGISTRY_ID}/${IMAGE_NAME}:latest" \
		-var="folder_id=$${FOLDER_ID}" \
		-var="cloud_id=$${CLOUD_ID}" \
		-var-file=variables.tfvars

apply:
	@FOLDER_ID=$$(yc config get folder-id 2>/dev/null); \
	CLOUD_ID=$$(yc config get cloud-id 2>/dev/null); \
	REGISTRY_ID=$$(yc container registry get $(REGISTRY_NAME) | awk '/^id:/ {print $$2}'); \
	terraform -chdir=terraform apply \
		-var="token=$(YC_TOKEN)" \
		-var="app_image_url=cr.yandex/$${REGISTRY_ID}/${IMAGE_NAME}:latest" \
		-var="folder_id=$${FOLDER_ID}" \
		-var="cloud_id=$${CLOUD_ID}" \
		-var-file=variables.tfvars \
		-auto-approve

clone-build-push:
	@REGISTRY_ID=$$(yc container registry get $(REGISTRY_NAME) | awk '/^id:/ {print $$2}'); \
	./scripts/build_and_push.sh git@github.com:Digital-Activists/yandex-cloud-blog-application.git cr.yandex/$${REGISTRY_ID}/${IMAGE_NAME}:latest