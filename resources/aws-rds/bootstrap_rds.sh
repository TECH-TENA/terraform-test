#!/usr/bin/env bash
set -euo pipefail

export AWS_PAGER="" # Prevent AWS CLI paging

# ----------- LOGGING SETUP -----------
LOG_DIR="$(pwd)"
LOG_FILE="$LOG_DIR/bootstrap_rds.log"
MAX_RUNS=3

function rotate_log_runs() {
    if [ -f "$LOG_FILE" ]; then
        local total_runs
        total_runs=$(grep -c '^========== NEW RUN' "$LOG_FILE" || echo 0)
        if [ "$total_runs" -ge "$MAX_RUNS" ]; then
            local last_runs_lines
            last_runs_lines=$(grep -n '^========== NEW RUN' "$LOG_FILE" | tail -n "$MAX_RUNS" | cut -d: -f1)
            local first_line
            first_line=$(echo "$last_runs_lines" | head -n1)
            tail -n +"$first_line" "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
        fi
    fi
}
rotate_log_runs
echo "========== NEW RUN $(date +'%Y-%m-%d %H:%M:%S') ==========" >> "$LOG_FILE"

function log() {
    local level="$1"
    shift
    local msg="$*"
    echo "$(date +'%F %T') [$level] $msg" | tee -a "$LOG_FILE"
}
trap 'last_status=$?; if [ $last_status -ne 0 ]; then log "FATAL" "Script failed (exit $last_status). Last 20 log lines:"; tail -20 "$LOG_FILE"; fi' EXIT ERR

log "INFO" "Script started"

# ----------- YAML CONFIG LOCATION LOGIC -----------
DEFAULT_ENV_YAML_REL="../../environments/webforx.yaml"
CONFIG_OVERRIDE=""
ROOT_DIR="$(pwd)"
function find_yaml() {
    for arg in "$@"; do
        if [[ $arg == --config=* ]]; then
            CONFIG_OVERRIDE="${arg#--config=}"
        fi
    done
    if [[ -n "${WEBFORX_YAML_PATH:-}" ]]; then echo "$WEBFORX_YAML_PATH"; return; fi
    if [[ -n "$CONFIG_OVERRIDE" ]]; then echo "$CONFIG_OVERRIDE"; return; fi
    if [ -f "$DEFAULT_ENV_YAML_REL" ]; then echo "$DEFAULT_ENV_YAML_REL"; return; fi
    SEARCH="$(pwd)"
    while [ "$SEARCH" != "/" ]; do
        if [ -f "$SEARCH/webforx.yaml" ]; then echo "$SEARCH/webforx.yaml"; return; fi
        SEARCH="$(dirname "$SEARCH")"
    done
    FILE="$(find "$ROOT_DIR" -type f -name 'webforx.yaml' 2>/dev/null | head -n 1)"
    if [[ -n "$FILE" ]]; then echo "$FILE"; return; fi
    log "FATAL" "Could not find webforx.yaml. Use --config=/path/to/webforx.yaml."; exit 1
}
ENV_YAML_FILE="$(find_yaml "$@")"
log "INFO" "Using YAML config at: $ENV_YAML_FILE"

# ----------- AWS PROFILE / REGION LOGIC -----------
AVAILABLE_PROFILES=($(aws configure list-profiles))
ENV_PROFILE="$(yq '.global.environment' "$ENV_YAML_FILE" | tr -d '"')"
AWS_REGION_YAML="$(yq '.rds.config.aws_region_main' "$ENV_YAML_FILE" | tr -d '"')"
PROFILE_CANDIDATES=()
for p in "${AVAILABLE_PROFILES[@]}"; do
    if [[ "$p" == *"$ENV_PROFILE"* ]]; then PROFILE_CANDIDATES+=("$p"); fi
done
if [ "${#PROFILE_CANDIDATES[@]}" -eq 1 ]; then
    AWS_PROFILE="${PROFILE_CANDIDATES[0]}"
elif [ "${#PROFILE_CANDIDATES[@]}" -gt 1 ]; then
    if [[ "${CI:-}" == "true" || "${NONINTERACTIVE:-}" == "true" ]]; then
        log "FATAL" "Multiple AWS profiles match environment '$ENV_PROFILE' in non-interactive mode. Set AWS_PROFILE explicitly."; exit 2
    fi
    echo "Multiple AWS profiles match environment '$ENV_PROFILE':"
    select p in "${PROFILE_CANDIDATES[@]}"; do AWS_PROFILE="$p"; break; done
else
    if [ "${#AVAILABLE_PROFILES[@]}" -eq 1 ]; then
        AWS_PROFILE="${AVAILABLE_PROFILES[0]}"
        log "INFO" "Only one AWS profile found. Using $AWS_PROFILE"
    else
        echo "Available AWS profiles:"
        select p in "${AVAILABLE_PROFILES[@]}"; do AWS_PROFILE="$p"; break; done
    fi
fi
export AWS_PROFILE
export AWS_REGION="$AWS_REGION_YAML"
log "INFO" "Using AWS_PROFILE=$AWS_PROFILE AWS_REGION=$AWS_REGION"
AWS_REGION_PROFILE="$(aws configure get region --profile "$AWS_PROFILE")"
if [[ "$AWS_REGION_PROFILE" != "$AWS_REGION_YAML" ]]; then
    log "WARN" "YAML region is '$AWS_REGION_YAML', but profile region is '$AWS_REGION_PROFILE'."
    if [[ "${CI:-}" == "true" || "${NONINTERACTIVE:-}" == "true" ]]; then
        log "FATAL" "AWS region mismatch in CI/non-interactive mode. Aborting."; exit 2
    fi
    read -rp "Continue with '$AWS_REGION_PROFILE'? (y/N): " CONFIRM
    [[ "${CONFIRM,,}" == "y" ]] || exit 2
fi
aws sts get-caller-identity >/dev/null || { log "FATAL" "AWS profile $AWS_PROFILE is not configured or expired. Re-auth and retry."; exit 2; }
log "INFO" "AWS profile loaded"

# ----------- DEPENDENCY AND VERSION CHECK -----------
MIN_TF_VERSION="1.10.0"
MIN_YQ_VERSION="4.0.0"
for dep in aws terraform yq; do
    if ! command -v $dep >/dev/null 2>&1; then log "FATAL" "$dep not found. Please install with brew/apt/etc. and retry."; exit 3; fi
done
YQ_VERSION="$(yq --version | awk '{print $3}')"
TF_VERSION="$(terraform version -json | yq '.terraform_version' 2>/dev/null || terraform version | head -1 | grep -o '[0-9.]\+')"
if [[ "$(printf '%s\n' "$TF_VERSION" "$MIN_TF_VERSION" | sort -V | head -n1)" != "$MIN_TF_VERSION" ]]; then
    log "FATAL" "Terraform $MIN_TF_VERSION+ required for native lockfile. Found: $TF_VERSION."; exit 3
fi
if [[ "$(printf '%s\n' "$YQ_VERSION" "$MIN_YQ_VERSION" | sort -V | head -n1)" != "$MIN_YQ_VERSION" ]]; then
    log "FATAL" "yq $MIN_YQ_VERSION+ required. Found: $YQ_VERSION."; exit 3
fi

# ----------- YAML SCHEMA VALIDATION -----------
required_yaml_keys=(
    ".rds.config.aws_region_main"
    ".rds.config.name"
    ".rds.config.ssm_username_param"
    ".rds.config.ssm_password_param"
    ".rds.config.ssm_dbname_param"
    ".rds.config.engine"
    ".rds.config.engine_version"
    ".rds.config.instance_class"
    ".rds.config.allocated_storage"
    ".rds.config.private_subnet_ids"
    ".rds.config.app_security_group_id"
    ".rds.config.subnet_group_name"
    ".rds.config.monitoring_interval"
    ".rds.config.backup_retention_days"
    ".rds.kms_config.rotation_alias_name"
    ".rds.config.sns_topic_name"
    ".rds.config.notification_emails"
    ".tags"
    ".terraform_backend.s3_bucket"
    ".terraform_backend.use_lockfile"
)
MISSING_KEYS=()
for key in "${required_yaml_keys[@]}"; do
    val="$(yq "$key" "$ENV_YAML_FILE" 2>/dev/null || true)"
    if [[ -z "$val" || "$val" == "null" ]]; then MISSING_KEYS+=("$key"); fi
done
if [ ${#MISSING_KEYS[@]} -gt 0 ]; then
    log "FATAL" "YAML validation failed. Missing keys: ${MISSING_KEYS[*]}"; exit 10
fi
log "INFO" "YAML config keys validated."

# ----------- TERRAFORM BACKEND SETUP -----------
TF_BACKEND_BUCKET="$(yq '.terraform_backend.s3_bucket' "$ENV_YAML_FILE" | tr -d '"')"
USE_LOCKFILE="$(yq '.terraform_backend.use_lockfile // false' "$ENV_YAML_FILE" | tr -d '"')"
TF_BACKEND_KEY="webforx/rds/${ENV_PROFILE}/terraform.tfstate"
if ! aws s3api head-bucket --bucket "$TF_BACKEND_BUCKET" --region "$AWS_REGION" 2>/dev/null; then
    log "FATAL" "S3 backend bucket $TF_BACKEND_BUCKET does not exist in $AWS_REGION."; exit 11
fi
if [[ "$USE_LOCKFILE" == "true" ]]; then
    cat > "$ROOT_DIR/backend.tf" <<EOF
terraform {
  backend "s3" {
    bucket         = "$TF_BACKEND_BUCKET"
    key            = "$TF_BACKEND_KEY"
    region         = "$AWS_REGION"
    encrypt        = true
    use_lockfile   = true
  }
}
EOF
    log "INFO" "backend.tf configured for S3 with native lockfile at $TF_BACKEND_KEY."
else
    TF_BACKEND_TABLE="$(yq '.terraform_backend.dynamodb_table' "$ENV_YAML_FILE" | tr -d '"')"
    if ! aws dynamodb describe-table --table-name "$TF_BACKEND_TABLE" --region "$AWS_REGION" >/dev/null 2>&1; then
        log "FATAL" "DynamoDB lock table $TF_BACKEND_TABLE does not exist in $AWS_REGION."; exit 12
    fi
    cat > "$ROOT_DIR/backend.tf" <<EOF
terraform {
  backend "s3" {
    bucket         = "$TF_BACKEND_BUCKET"
    key            = "$TF_BACKEND_KEY"
    region         = "$AWS_REGION"
    dynamodb_table = "$TF_BACKEND_TABLE"
    encrypt        = true
  }
}
EOF
    log "INFO" "backend.tf configured for S3 + DynamoDB at $TF_BACKEND_KEY (legacy mode)."
fi

# ----------- EXTRACT VALUES FROM YAML -----------
RDS_NAME="$(yq '.rds.config.name' "$ENV_YAML_FILE" | tr -d '"')"
RDS_USERNAME_PARAM="$(yq '.rds.config.ssm_username_param' "$ENV_YAML_FILE" | tr -d '"')"
RDS_PASSWORD_PARAM="$(yq '.rds.config.ssm_password_param' "$ENV_YAML_FILE" | tr -d '"')"
RDS_DBNAME_PARAM="$(yq '.rds.config.ssm_dbname_param' "$ENV_YAML_FILE" | tr -d '"')"
SNS_TOPIC_NAME="$(yq '.rds.config.sns_topic_name' "$ENV_YAML_FILE" | tr -d '"')"
KMS_ALIAS="$(yq '.rds.kms_config.rotation_alias_name' "$ENV_YAML_FILE" | tr -d '"')"
TAGS="$(yq -o=json '.tags' "$ENV_YAML_FILE" 2>/dev/null || echo '{}')"
NOTIF_EMAILS=($(yq -r '.rds.config.notification_emails[]' "$ENV_YAML_FILE" 2>/dev/null || echo ''))
MATTERMOST_WEBHOOK="$(yq '.rds.config.mattermost_webhook_url' "$ENV_YAML_FILE" | tr -d '"')"

# ----------- SSM PARAMETERS (from YAML, no prompt) -----------
get_ssm_from_yaml_or_create() {
    local param="$1"
    local yaml_value="$2"
    local type="${3:-String}"
    local desc="${4:-RDS Automation Param}"
    if aws ssm get-parameter --name "$param" --region "$AWS_REGION" >/dev/null 2>&1; then
        ssm_value=$(aws ssm get-parameter --name "$param" --with-decryption --query 'Parameter.Value' --region "$AWS_REGION" --output text)
        log "INFO" "SSM parameter $param exists. Using existing value."
        echo "$ssm_value"
        return
    fi
    if [ -n "$yaml_value" ] && [ "$yaml_value" != "null" ]; then
        log "INFO" "SSM parameter $param missing. Creating with YAML value."
        aws ssm put-parameter --name "$param" --value "$yaml_value" --type "$type" --overwrite --description "$desc" --region "$AWS_REGION" >/dev/null
        echo "$yaml_value"
        return
    fi
    log "FATAL" "SSM parameter $param is missing and YAML value is empty or null. Please provide a valid value."; exit 5
}
RDS_USERNAME_YAML="$(yq '.rds.config.username' "$ENV_YAML_FILE" | tr -d '"')"
RDS_PASSWORD_YAML="$(yq '.rds.config.password' "$ENV_YAML_FILE" | tr -d '"')"
RDS_DBNAME_YAML="$(yq '.rds.config.db_name' "$ENV_YAML_FILE" | tr -d '"')"
RDS_USERNAME="$(get_ssm_from_yaml_or_create "$RDS_USERNAME_PARAM" "$RDS_USERNAME_YAML" "String" "RDS username")"
RDS_PASSWORD="$(get_ssm_from_yaml_or_create "$RDS_PASSWORD_PARAM" "$RDS_PASSWORD_YAML" "SecureString" "RDS password")"
RDS_DBNAME="$(get_ssm_from_yaml_or_create "$RDS_DBNAME_PARAM" "$RDS_DBNAME_YAML" "String" "RDS dbname")"

# ----------- SNS TOPIC LOGIC (Cross-platform, Bash 3/4/5 Safe) -----------
SNS_TOPIC_ARN=""
ALL_TOPICS=()
AWS_TOPICS_OUT=$(aws sns list-topics --region "$AWS_REGION" --query "Topics[].TopicArn" --output text 2>/dev/null || echo "")
if [ -n "$AWS_TOPICS_OUT" ]; then ALL_TOPICS=($AWS_TOPICS_OUT); fi
if [ "${#ALL_TOPICS[@]}" -gt 0 ]; then
    for arn in "${ALL_TOPICS[@]}"; do
        TOPIC_NAME="$(basename "$arn")"
        if [[ "$TOPIC_NAME" == "$SNS_TOPIC_NAME" ]]; then SNS_TOPIC_ARN="$arn"; break; fi
    done
fi
if [ -z "$SNS_TOPIC_ARN" ]; then
    SNS_TOPIC_ARN=$(aws sns create-topic --name "$SNS_TOPIC_NAME" --region "$AWS_REGION" --query 'TopicArn' --output text)
    log "INFO" "Created SNS topic: $SNS_TOPIC_ARN"
else
    log "INFO" "SNS topic $SNS_TOPIC_NAME exists: $SNS_TOPIC_ARN"
fi

# ----------- KMS KEY (ROTATION ALIAS, PENDING DELETION HANDLING) -----------
KMS_KEY_ID=""
if aws kms list-aliases --region "$AWS_REGION" --query "Aliases[?AliasName=='$KMS_ALIAS'].[TargetKeyId]" --output text | grep -q '.'; then
    KMS_KEY_ID=$(aws kms list-aliases --region "$AWS_REGION" --query "Aliases[?AliasName=='$KMS_ALIAS'].[TargetKeyId]" --output text)
    log "INFO" "KMS alias $KMS_ALIAS exists: $KMS_KEY_ID"
    KMS_KEY_STATUS=$(aws kms describe-key --key-id "$KMS_KEY_ID" --region "$AWS_REGION" --query 'KeyMetadata.KeyState' --output text)
    if [[ "$KMS_KEY_STATUS" == "PendingDeletion" ]]; then
        log "WARN" "KMS key $KMS_KEY_ID is pending deletion. Cancelling deletion..."
        if [[ "$ENV_PROFILE" == "production" ]]; then
            log "FATAL" "Refusing to cancel KMS deletion in production environment."; exit 14
        fi
        aws kms cancel-key-deletion --key-id "$KMS_KEY_ID" --region "$AWS_REGION"
        sleep 2
        aws kms enable-key --key-id "$KMS_KEY_ID" --region "$AWS_REGION" || true
        log "INFO" "Deletion cancelled and key re-enabled."
    fi
else
    KMS_KEY_ID=$(aws kms create-key --description "Webforx RDS Encryption Key" --region "$AWS_REGION" --query 'KeyMetadata.KeyId' --output text)
    aws kms create-alias --alias-name "$KMS_ALIAS" --target-key-id "$KMS_KEY_ID" --region "$AWS_REGION"
    aws kms enable-key-rotation --key-id "$KMS_KEY_ID" --region "$AWS_REGION"
    aws kms tag-resource --key-id "$KMS_KEY_ID" --tags "TagKey=Project,TagValue=Webforx" --region "$AWS_REGION"
    log "INFO" "Created KMS key and alias: $KMS_ALIAS"
fi

# ----------- CLEANUP LOCAL STATE -----------
log "INFO" "Cleaning up old Terraform state and .terraform directory..."
rm -rf .terraform terraform.tfstate* terraform.tfstate.backup || true

# ----------- AUTO-IMPORT FUNCTION (UNIVERSAL, REUSABLE) -----------
auto_import() {
    local tf_resource="$1"
    local aws_cmd="$2"
    local aws_id="$3"
    local human_desc="$4"
    if eval "$aws_cmd" >/dev/null 2>&1; then
        terraform import "$tf_resource" "$aws_id" 2>/dev/null && \
        log "INFO" "Imported pre-existing $human_desc ($aws_id) into state." || \
        log "WARN" "$human_desc ($aws_id) exists but import may have failed (check state)."
    else
        log "INFO" "$human_desc ($aws_id) does not exist or not accessible—will be created by Terraform."
    fi
}

# ----------- UNIVERSAL RESOURCE IMPORTS (IDEMPOTENT) -----------
log "INFO" "Auto-importing all supported AWS resources if needed..."

BUCKET_NAME="${RDS_NAME}-bucket"
SUBNET_GROUP_NAME="$(yq '.rds.config.subnet_group_name' "$ENV_YAML_FILE" | tr -d '"')"
MONITORING_ROLE_NAME="$(yq '.rds.config.monitoring_role_name' "$ENV_YAML_FILE" | tr -d '"')"

auto_import "module.rds_postgres_instance.aws_s3_bucket.rds_data_bucket" \
    "aws s3api head-bucket --bucket \"$BUCKET_NAME\" --region \"$AWS_REGION\"" \
    "$BUCKET_NAME" "S3 bucket"

auto_import "module.rds_postgres_instance.module.rds.module.db_instance.aws_db_instance.this[0]" \
    "aws rds describe-db-instances --db-instance-identifier \"$RDS_NAME\" --region \"$AWS_REGION\" | grep -q DBInstances" \
    "$RDS_NAME" "RDS instance"

auto_import "module.rds_postgres_instance.aws_db_subnet_group.main" \
    "aws rds describe-db-subnet-groups --db-subnet-group-name \"$SUBNET_GROUP_NAME\" --region \"$AWS_REGION\" | grep -q DBSubnetGroups" \
    "$SUBNET_GROUP_NAME" "DB subnet group"

auto_import "module.rds_postgres_instance.aws_sns_topic.alerts" \
    "[ -n \"$SNS_TOPIC_ARN\" ]" \
    "$SNS_TOPIC_ARN" "SNS topic"

auto_import "module.rds_postgres_instance.aws_kms_alias.rds_alias" \
    "aws kms list-aliases --region \"$AWS_REGION\" --query \"Aliases[?AliasName=='$KMS_ALIAS'].[TargetKeyId]\" --output text | grep -q '.'" \
    "$KMS_ALIAS" "KMS alias"

auto_import "module.rds_postgres_instance.module.rds.module.db_instance.aws_iam_role.enhanced_monitoring[0]" \
    "aws iam get-role --role-name \"$MONITORING_ROLE_NAME\" --region \"$AWS_REGION\" | grep -q '\"Role\"'" \
    "$MONITORING_ROLE_NAME" "IAM role for enhanced monitoring"

log "INFO" "Resource auto-import checks complete."

# ----------- TERRAFORM INIT/VALIDATE/PLAN -----------
terraform init -reconfigure | tee -a "$LOG_FILE"
terraform validate | tee -a "$LOG_FILE"
terraform plan -out=tfplan | tee -a "$LOG_FILE"

log "INFO" "Terraform plan created as 'tfplan'."
log "INFO" "Manual review required. To deploy, run: terraform apply tfplan"
if [ -n "$MATTERMOST_WEBHOOK" ]; then
    curl -X POST -H 'Content-Type: application/json' --data "{\"text\": \"[RDS Automation] Plan ready for review in $ENV_PROFILE environment. Manual 'terraform apply tfplan' required for deployment.\"}" "$MATTERMOST_WEBHOOK" >/dev/null 2>&1 || true
fi

# ----------- HANDLE --cleanup (DESTROY + deep cleanup) -----------
if [[ "${1:-}" == "--cleanup" ]]; then
    log "INFO" "Running Terraform destroy..."
    terraform destroy --auto-approve | tee -a "$LOG_FILE" || true

    # log "INFO" "Deleting SSM parameters if present..."
    # aws ssm delete-parameter --name "$RDS_USERNAME_PARAM" --region "$AWS_REGION" 2>/dev/null || true
    # aws ssm delete-parameter --name "$RDS_PASSWORD_PARAM" --region "$AWS_REGION" 2>/dev/null || true
    # aws ssm delete-parameter --name "$RDS_DBNAME_PARAM" --region "$AWS_REGION" 2>/dev/null || true

    log "INFO" "Deleting SNS topic if present..."
    aws sns delete-topic --topic-arn "$SNS_TOPIC_ARN" --region "$AWS_REGION" 2>/dev/null || true

    log "INFO" "Scheduling KMS key deletion if present..."
    if [[ "$ENV_PROFILE" == "production" ]]; then
        log "FATAL" "Refusing to schedule KMS deletion in production environment."; exit 15
    fi
    aws kms schedule-key-deletion --key-id "$KMS_KEY_ID" --pending-window-in-days 7 --region "$AWS_REGION" 2>/dev/null || true

    log "INFO" "Cleanup complete. Please verify no shared resources were affected."
    if [ -n "$MATTERMOST_WEBHOOK" ]; then
        curl -X POST -H 'Content-Type: application/json' --data "{\"text\": \"[RDS Automation] Sandbox cleanup and destroy completed for $ENV_PROFILE.\"}" "$MATTERMOST_WEBHOOK" >/dev/null 2>&1 || true
    fi
    exit 0
fi

log "INFO" "Script completed successfully."
log "INFO" "To apply the plan, run: terraform apply tfplan"
log "INFO" "To destroy resources, run: ./bootstrap_rds.sh --cleanup"
exit 0
