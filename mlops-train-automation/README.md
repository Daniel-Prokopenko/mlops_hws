# MLOps Train Automation (Terraform + Lambda + Step Functions + GitLab CI)

## Project structure
```
mlops-train-automation/
├── terraform/
│  ├── main.tf
│  ├── variables.tf
│  └── lambda/
│    ├── validate.py
│    ├── log_metrics.py
│    ├── validate.zip
│    └── log_metrics.zip
├── .gitlab-ci.yml
└── README.md
```

## Build Lambda archives
```bash
cd terraform/lambda
zip -r validate.zip validate.py
zip -r log_metrics.zip log_metrics.py
cd ../../
```

## Deploy infrastructure with Terraform
```bash
cd terraform
terraform init
terraform apply -auto-approve
terraform output -raw state_machine_arn
```

## Run Step Function manually
```bash
AWS_REGION="eu-central-1"
STATE_MACHINE_ARN="arn:aws:states:...:stateMachine:..."

aws stepfunctions start-execution   --region "$AWS_REGION"   --state-machine-arn "$STATE_MACHINE_ARN"   --name "manual-train-$(date +%s)"   --input '{"source":"manual","commit":"local"}'
```

## GitLab CI
Job `train-model` runs on push and calls `aws stepfunctions start-execution`.

### Required GitLab CI variables
- AWS_REGION
- STATE_MACHINE_ARN
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

### Example JSON input
```json
{"source":"gitlab-ci","commit":"abcd1234"}
```
