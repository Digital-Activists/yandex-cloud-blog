# Yandex Cloud Blog

Итоговый проект по курсу виртуализации и облачных технологий от Яндекс

## Обзор

```txt
 terraform
├── 󱁢 application.tf    - Конфигурация виртуальных машин
├── 󱁢 database.tf       - Конфигурация базы данных
├── 󱁢 main.tf
├── 󱁢 net.tf            - Конфигурация сети
├── 󱁢 storage.tf        - Конфигурация Object Storage
└── 󱁢 variables.tf      - Используемые переменные
```

## Terraform

### Развертывание

```sh
cd terraform

terraform init

terraform plan -var-file=<my-variables.tfvars>

terraform apply -var-file=<my-variables.tfvars>
```

### Удаление

```sh
terraform destroy -var-file=<my-variables.tfvars>
```
