# Yandex Cloud Blog

Итоговый проект по курсу виртуализации и облачных технологий от Яндекс

## Обзор

### Terraform

```txt
terraform/
├── application.tf    - Конфигурация виртуальных машин
├── database.tf       - Конфигурация базы данных
├── main.tf
├── net.tf            - Конфигурация сети
├── storage.tf        - Конфигурация Object Storage
└── variables.tf      - Используемые переменные
```

## Развертывание

1. Создайте токен:

```sh
export YC_TOKEN=$(yc iam create-token --impersonate-service-account-id <id_сервисного_аккаунта>)
```

2. Создайте registry:

```sh
make create-registry
```

3. Загрузите образ в registry:

```sh
make clone-build-push
```

4. Запустите terraform:

```sh
terraform -chdir=terraform init # init нужно выполнить единожды

make apply
```

## Удаление

*Перед вызовом destroy вручную удалите все папки и файлы из Object Storage бакета.*

```sh
make destroy
make delete-registry
```

## Tips and Tricks

### Cloud-init

#### Чтобы быстро понять, завершился ли cloud-init успешно:

```sh
cloud-init status --long
```

#### Основные логи

Полный лог выполнения:

```sh
cat /var/log/cloud-init.log
```

Вывод команд из runcmd и bootcmd:

```sh
cat /var/log/cloud-init-output.log
```
