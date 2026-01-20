# Terraform: VPC + EKS (modules) + remote_state + kubectl (WSL)

Цей репозиторій містить модульний Terraform-проєкт, який:
- створює **VPC** через офіційний модуль `terraform-aws-modules/vpc/aws`
- створює **EKS** через офіційний модуль `terraform-aws-modules/eks/aws`
- підключає EKS до VPC через **`terraform_remote_state`**
- дає доступ до кластера одразу після `terraform apply` через **kubectl**

> ⚠️ **Увага про вартість:** EKS і NAT Gateway **платні**. Після перевірки результату **обовʼязково виконайте `terraform destroy`**.

---

## Структура проєкту

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tf
├── backend.tf
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tf
│   ├── backend.tf
│   ├── providers.tf
│   └── terraform.tfvars
└── eks/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tf
    ├── backend.tf
    ├── providers.tf
    └── terraform.tfvars
```

---

## Передумови

Робота виконувалась у **WSL (Ubuntu)**.

Потрібно мати:
- активний AWS акаунт із підключеним білінгом
- IAM користувача для Terraform (Access Key + Secret Key)
- встановлені інструменти: **AWS CLI**, **Terraform**, **kubectl**

---

## 1) IAM користувач для Terraform

1. AWS Console → **IAM** → **Users** → **Create user**
   - Name: `terraform-user`
   - Console access: **вимкнено** (не потрібно для CLI/Terraform)

2. Permissions → **Attach policies directly**
   - `AdministratorAccess` (для навчального завдання)

3. `terraform-user` → **Security credentials** → **Access keys** → **Create access key**
   - Use case: `Command Line Interface (CLI)`

Збережіть:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

## 2) Налаштування AWS CLI у WSL

Очистити старі налаштування (якщо були):
```bash
rm -f ~/.aws/credentials ~/.aws/config
```

Налаштувати:
```bash
aws configure
```

Перевірити доступ:
```bash
aws sts get-caller-identity
```

Щоб AWS CLI не відкривав pager (і не “зависав” у виводі):
```bash
aws configure set cli_pager ""
```

---

## 3) Встановлення Terraform (рекомендований спосіб)

> Не використовуємо snap. Встановлюємо з офіційного репозиторію HashiCorp.

```bash
sudo apt-get update
sudo apt-get install -y gnupg software-properties-common wget

wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y terraform

terraform -version
```

---

## 4) Встановлення kubectl

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

kubectl version --client
```

---

## 5) Backend для Terraform state (S3 + DynamoDB lock)

Використовується:
- **S3 bucket** — зберігання `terraform.tfstate`
- **DynamoDB table** — lock для state, щоб уникати конфліктів

### 5.1 DynamoDB таблиця (lock)

Назва таблиці:
- `tf-locks-eks`

```bash
aws dynamodb create-table   --table-name tf-locks-eks   --attribute-definitions AttributeName=LockID,AttributeType=S   --key-schema AttributeName=LockID,KeyType=HASH   --billing-mode PAY_PER_REQUEST   --region eu-central-1
```

Перевірка статусу:
```bash
aws dynamodb describe-table   --table-name tf-locks-eks   --region eu-central-1   --query "Table.TableStatus"   --output text
```

Очікувано: `ACTIVE`

### 5.2 S3 bucket для state

Bucket створювався з префіксом:
- `prokop-tfstate-eks-<timestamp>`

Перевірка наявних bucket:
```bash
aws s3 ls | grep '^prokop-tfstate-eks-'
```

---

## 6) Важливо: коротка назва кластера (обмеження IAM)

AWS має обмеження на довжину `name_prefix` для IAM Role у node group.
Щоб уникнути помилки, використовується коротка назва кластера:

✅ `prk-eks-dev`

Це значення має бути **однаковим** у:
- `vpc/terraform.tfvars` → `cluster_name`
- `eks/terraform.tfvars` → `cluster_name`

---

## 7) Деплой: спочатку VPC, потім EKS (через remote_state)

> Важливо: `terraform apply` виконується **окремо** у каталозі `vpc/` і **окремо** у `eks/`.

---

### 7.1 VPC

`vpc/providers.tf`:
```hcl
provider "aws" {}
```

Приклад `vpc/terraform.tfvars`:
```hcl
name            = "prk-eks-dev"
cidr            = "10.0.0.0/16"
azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
public_subnets  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
cluster_name    = "prk-eks-dev"
```

Запуск:
```bash
cd vpc
terraform init -reconfigure
terraform apply
```

Перевірка state у S3 (опційно):
```bash
aws s3 ls "s3://<YOUR_TF_BUCKET>/mlops_hws/vpc/"
```

---

### 7.2 EKS

`eks/providers.tf`:
```hcl
provider "aws" {}
```

Приклад `eks/terraform.tfvars`:
```hcl
use_remote_state            = true
remote_state_bucket         = "<YOUR_TF_BUCKET>"
remote_state_key            = "mlops_hws/vpc/terraform.tfstate"
remote_state_region         = "eu-central-1"
remote_state_dynamodb_table = "tf-locks-eks"

region       = "eu-central-1"
cluster_name = "prk-eks-dev"
```

Запуск:
```bash
cd ../eks
terraform init -reconfigure
terraform apply
```

---

## 8) Підключення до кластера та перевірка через kubectl

Оновити kubeconfig:
```bash
aws eks --region eu-central-1 update-kubeconfig --name prk-eks-dev
```

Перевірити ноди:
```bash
kubectl get nodes
```

Показати node group для кожної ноди:
```bash
kubectl get nodes -L eks.amazonaws.com/nodegroup
```

Перевірити системні поди:
```bash
kubectl get pods -A
```

---

## 9) Видалення ресурсів (обовʼязково)

Щоб припинити нарахування коштів — видаліть інфраструктуру у правильному порядку:

1) **Спочатку EKS**
```bash
cd eks
terraform destroy
```

2) **Потім VPC**
```bash
cd ../vpc
terraform destroy
```

---

## 10) Швидкі підказки (Troubleshooting)

### AWS CLI “завис” у виводі
Вимкніть pager:
```bash
aws configure set cli_pager ""
```

### `InvalidClientTokenId`
Невірні ключі або некоректно налаштований профіль:
```bash
aws configure
aws sts get-caller-identity
```

### Помилка `name_prefix length ...`
Занадто довга назва кластера → використайте коротке `cluster_name = "prk-eks-dev"` у VPC та EKS.

---

## Підтвердження результату (приклад)

Очікуваний результат:
- 2 ноди у статусі `Ready`
- 2 node groups (CPU та GPU логічно)
- системні поди `kube-system` у статусі `Running`
