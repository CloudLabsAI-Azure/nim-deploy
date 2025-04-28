#!/bin/bash
set -e  # Exit on error
set -x  # Print commands

source config.sh

# Make sure endpoint name conforms to Azure ML requirements
# Strip any disallowed characters and ensure proper length
sanitized_endpoint_name=$(echo "${endpoint_name}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
if [[ ${#sanitized_endpoint_name} -gt 32 ]]; then
  sanitized_endpoint_name="${sanitized_endpoint_name:0:32}"
fi
# Ensure it doesn't end with a hyphen
sanitized_endpoint_name=$(echo "$sanitized_endpoint_name" | sed 's/-$//')
# Ensure it starts with a letter
if [[ ! $sanitized_endpoint_name =~ ^[a-z] ]]; then
  sanitized_endpoint_name="ml-${sanitized_endpoint_name}"
fi

echo "Original endpoint name: ${endpoint_name}"
echo "Sanitized endpoint name: ${sanitized_endpoint_name}"

# Create new endpoint in this workspace
cp azureml_files/endpoint.yml actual_endpoint_aml.yml

# Use the appropriate sed command based on the OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS version
  sed -i '' "s/endpoint_name_placeholder/${sanitized_endpoint_name}/g" actual_endpoint_aml.yml
else
  # Linux version
  sed -i "s/endpoint_name_placeholder/${sanitized_endpoint_name}/g" actual_endpoint_aml.yml
fi

echo "Creating Online Endpoint ${sanitized_endpoint_name}"
az ml online-endpoint create -f actual_endpoint_aml.yml --resource-group $resource_group --workspace-name $workspace

# Keep the original file for debugging if there's an error
if [ $? -eq 0 ]; then
  rm actual_endpoint_aml.yml
  echo "Endpoint created successfully!"
else
  echo "Error creating endpoint. Check actual_endpoint_aml.yml for issues."
  cat actual_endpoint_aml.yml
fi
