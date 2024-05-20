#!/bin/bash

required_tools=(jq gcloud terraform ansible)
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

IFS=' ' read -r -a PROXIES_USERNAMES_ARRAY <<< "$PROXIES_USERNAMES"
IFS=' ' read -r -a PROXIES_PASSWORDS_ARRAY <<< "$PROXIES_PASSWORDS"

if [[ ${#PROXIES_USERNAMES_ARRAY[@]} -eq 0 ]] || [[ ${#PROXIES_PASSWORDS_ARRAY[@]} -eq 0 ]]; then
    echo "Error: Both PROXIES_USERNAMES and PROXIES_PASSWORDS must be set with at least one value in .env"
    exit 1
fi

if [[ ${#PROXIES_USERNAMES_ARRAY[@]} -ne ${#PROXIES_PASSWORDS_ARRAY[@]} ]]; then
    echo "Error: Number of usernames and passwords in .env must match."
    exit 1
fi

N_PROXIES=${#PROXIES_USERNAMES_ARRAY[@]}

cd ./terraform

TFVARS_PORTS=($(grep -E 'ports\s*=\s*\[([^]]+)\]' terraform.tfvars | cut -d'[' -f2 | cut -d']' -f1 | tr -d '" ' | tr ',' '\n'))
if [[ ${#TFVARS_PORTS[@]} -lt $N_PROXIES ]]; then
    echo "Error: Number of ports in terraform.tfvars (${#TFVARS_PORTS[@]}) should be at least the same as the number of usernames/passwords in .env ($N_PROXIES)."
    exit 1
fi

terraform init
terraform apply \
    -var="project=$PROJECT" \
    -var="region=$REGION" \
    -var="zone=$ZONE" \
    -var="n_proxies=$N_PROXIES" \
    -auto-approve

EXTERNAL_IPS=($(terraform output -json external_ips | jq -r '.[]'))
INSTANCES_NAMES=($(terraform output -json instances_names | jq -r '.[]'))
PROXIES_PORTS=($(terraform output -json proxies_ports | jq -r '.[]'))


cd ..
i=0
while [[ $i -lt $N_PROXIES ]]; do
    EXTERNAL_IP=${EXTERNAL_IPS[i]}
    INSTANCE_NAME=${INSTANCES_NAMES[i]}
    PROXY_PORT=${PROXIES_PORTS[i]}
    echo "Running setup for $INSTANCE_NAME..."
    echo "External IP Address: $EXTERNAL_IP"

    TMP_KEY_PATH="$(mktemp -d)/temp_key"
    ssh-keygen -t rsa -b 4096 -f "$TMP_KEY_PATH" -q -N ""

    gcloud compute instances add-metadata "$INSTANCE_NAME" \
        --metadata "ssh-keys=$(whoami):$(cat "$TMP_KEY_PATH.pub")" \
        --zone "$ZONE" \
        --project "$PROJECT"


    ansible-playbook "./ansible/playbook.yml" \
        -i "$EXTERNAL_IP," \
        --private-key "$TMP_KEY_PATH" \
        --user "$(whoami)" \
        --extra-vars "proxy_username=${PROXIES_USERNAMES_ARRAY[i]} proxy_password=${PROXIES_PASSWORDS_ARRAY[i]} proxy_port=$PROXY_PORT" \
        --ssh-extra-args="-o StrictHostKeyChecking=no"

    rm -rf "$(dirname "$TMP_KEY_PATH")"
    i=$((i+1))
done

echo "Proxy server setup complete!"
