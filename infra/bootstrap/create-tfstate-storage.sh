#!/usr/bin/env bash
#
# Creates the storage account that holds Terraform state.
#
# Why a script: Terraform cannot store its state in a place that does not
# exist yet, so this one-time bootstrap uses the Azure CLI. It is safe to
# run more than once.
#
# These resources are tagged managed-by=bootstrap-script, not terraform,
# because Terraform does not create them (a deliberate exception to ADR 0002).

set -euo pipefail

# Git Bash on Windows rewrites arguments that start with "/", such as Azure
# resource IDs, which breaks az commands.
export MSYS_NO_PATHCONV=1

LOCATION="uksouth"
RG_NAME="rg-portfolio-tfstate-uks-001"
CONTAINER_NAME="tfstate"
OWNER_TAG="apra"

# Read values from the signed-in Azure session. tr -d '\r' removes the
# carriage returns Windows adds to CLI output.
SUB_ID="$(az account show --query id --output tsv | tr -d '\r')"
SUB_NAME="$(az account show --query name --output tsv | tr -d '\r')"
USER_ID="$(az ad signed-in-user show --query id --output tsv | tr -d '\r')"

# A short suffix derived from the subscription ID keeps the globally unique
# storage name stable, so re-running the script finds the same account.
SUFFIX="$(printf '%s' "$SUB_ID" | sha256sum | cut -c1-4)"
SA_NAME="stportfoliotfstuks${SUFFIX}"

echo "Subscription    : ${SUB_NAME}"
echo "Resource group  : ${RG_NAME}"
echo "Storage account : ${SA_NAME}"
read -r -p "Create these in the subscription above? (y/N) " ANSWER
[[ "$ANSWER" == "y" ]] || { echo "Cancelled."; exit 1; }

# Intentionally unquoted below so the shell splits it into separate tags.
TAGS="project=portfolio environment=shared owner=${OWNER_TAG} managed-by=bootstrap-script"

echo "Creating resource group..."
az group create --name "$RG_NAME" --location "$LOCATION" --tags $TAGS --output none

echo "Creating storage account..."
az storage account create \
  --name "$SA_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --https-only true \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --tags $TAGS \
  --output none

echo "Turning on versioning and soft delete..."
az storage account blob-service-properties update \
  --account-name "$SA_NAME" \
  --resource-group "$RG_NAME" \
  --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 14 \
  --enable-container-delete-retention true --container-delete-retention-days 14 \
  --output none

SA_ID="$(az storage account show --name "$SA_NAME" --resource-group "$RG_NAME" \
  --query id --output tsv | tr -d '\r')"

echo "Granting you data access (shared keys are disabled)..."
EXISTING="$(az role assignment list --assignee "$USER_ID" --scope "$SA_ID" \
  --role "Storage Blob Data Contributor" --query "length(@)" --output tsv | tr -d '\r')"
if [[ "$EXISTING" == "0" ]]; then
  az role assignment create \
    --assignee-object-id "$USER_ID" \
    --assignee-principal-type User \
    --role "Storage Blob Data Contributor" \
    --scope "$SA_ID" \
    --output none
fi

echo "Creating container (role changes can take a few minutes to apply)..."
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  if az storage container create --name "$CONTAINER_NAME" \
      --account-name "$SA_NAME" --auth-mode login --output none 2>/dev/null; then
    break
  fi
  if [[ "$attempt" == "10" ]]; then
    echo "Could not create the container. Wait a few minutes and run the script again."
    exit 1
  fi
  echo "  not ready yet, retrying in 20 seconds (attempt ${attempt}/10)..."
  sleep 20
done

echo "Adding a delete lock to the resource group..."
az lock create --name "lock-tfstate" --lock-type CanNotDelete \
  --resource-group "$RG_NAME" --output none

echo
echo "Done. Use these values in the Terraform backend:"
echo "  resource_group_name  = ${RG_NAME}"
echo "  storage_account_name = ${SA_NAME}"
echo "  container_name       = ${CONTAINER_NAME}"