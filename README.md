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

1. Создайте registry:

```sh
make yc-create-registry
```

2. Загрузите образ в registry:

```sh
chmod +x ./scripts/build_and_push.sh
./scripts/build_and_push.sh <repository> <registry> [branch]
```

3. Запустите terraform:

```sh
cd terraform

terraform init

terraform plan -var-file=<my-variables.tfvars>

terraform apply -var-file=<my-variables.tfvars>
```

## Удаление

```sh
terraform destroy -var-file=<my-variables.tfvars>
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
