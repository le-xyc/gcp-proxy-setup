#!/bin/bash

required_tools=(gcloud terraform ansible)
missing_tools=()
for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing_tools+=("$tool")
    fi
done

if [ ${#missing_tools[@]} -gt 0 ]; then
    echo "Error: The following tools are not installed:"
    printf ' - %s\n' "${missing_tools[@]}"
    exit 1
fi

PROJECT=$(gcloud config get-value project)
REGION=$(gcloud config get-value compute/region)
ZONE=$(gcloud config get-value compute/zone)

required_vars=(PROJECT REGION ZONE)
missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "Error: The following gcloud configuration values or environment variables are not set:"
    printf ' - %s\n' "${missing_vars[@]}"
    exit 1
fi

if [[ ! -f ".env" ]]; then
    echo "Error: '.env' file not found in the current directory. Please create it and set the required variables."
    exit 1
fi

source .env

required_vars=(PROXY_USERNAME PROXY_PASSWORD)
missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "Error: The following environment variables are not set in .env:"
    printf ' - %s\n' "${missing_vars[@]}"
    exit 1
fi

cd ./terraform
terraform init
terraform apply \
    -var="project=$PROJECT" \
    -var="region=$REGION" \
    -var="zone=$ZONE" \
    -auto-approve

EXTERNAL_IP=$(terraform output -raw external_ip)
INSTANCE_NAME=$(terraform output -raw instance_name)
PROXY_PORT=$(terraform output -raw proxy_port)

TMP_KEY_PATH="$(mktemp -d)/temp_key"
ssh-keygen -t rsa -b 4096 -f "$TMP_KEY_PATH" -q -N ""

gcloud compute instances add-metadata "$INSTANCE_NAME" \
    --metadata "ssh-keys=$(whoami):$(cat "$TMP_KEY_PATH.pub")" \
    --zone "$ZONE" \
    --project "$PROJECT"

cd ..
ansible-playbook "./ansible/playbook.yml" \
    -i "$EXTERNAL_IP," \
    --private-key "$TMP_KEY_PATH" \
    --user "$(whoami)" \
    --extra-vars "proxy_username=$PROXY_USERNAME proxy_password=$PROXY_PASSWORD proxy_port=$PROXY_PORT" \
    --ssh-extra-args="-o StrictHostKeyChecking=no"

rm -rf "$(dirname "$TMP_KEY_PATH")"

echo "Proxy server setup complete!"
