#!/bin/bash

# Pipeline independent script that can be used for uploading test results to `Blob Storage`

resource_group_name="$1"
azure_storage_account="$2"
azure_storage_container="$3"
local_source_path="$4"
local_source_file_pattern="${5:-**/*.*}"

echo "Azure Details:"
echo "Resource group name = $resource_group_name"

echo "-----"
echo "Upload Details:"
echo "Storage Account Name = $azure_storage_account"
echo "Container Name = $azure_storage_container"
echo "Source Filepath = $local_source_path"
echo "Source Filepattern = $local_source_file_pattern"

echo "======="

echo "Retrieving Storage Account Key"
export ACCOUNT_KEY=$(az storage account keys list -g $resource_group_name -n $azure_storage_account --query '[1].value')

echo "Uploading Artefact"
az storage blob upload-batch --account-name $azure_storage_account --account-key $ACCOUNT_KEY  -d $azure_storage_container -s $local_source_path --pattern $local_source_file_pattern

echo "Done"
