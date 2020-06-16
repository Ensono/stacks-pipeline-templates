#!/bin/bash

# Pipeline independent script that can be used for uploading test results to `Blob Storage`

resource_group_name="$1"
local_source_filename="$2"
azure_storage_account="$3"
azure_storage_container="$4"
azure_storage_target_filename="$5"

echo "Azure Details:"
echo "Resource group name = $resource_group_name"

echo "-----"
echo "Upload Details:"
echo "Storage Account Name = $azure_storage_account"
echo "Container Name = $azure_storage_container"
echo "Source Filepath = $local_source_filename"
echo "Target Filename = $azure_storage_target_filename"

echo "======="

echo "Retrieving Storage Account Key"
export ACCOUNT_KEY=$(az storage account keys list -g $resource_group_name -n $azure_storage_account --query '[1].value')

echo "Uploading Artefact"
az storage blob upload --account-name $azure_storage_account --account-key $ACCOUNT_KEY  --container-name $azure_storage_container --name $azure_storage_target_filename --file $local_source_filename

echo "Done"
