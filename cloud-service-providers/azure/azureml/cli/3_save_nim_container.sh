#!/bin/bash
set -x 

source config.sh

CONTAINER_NAME="${acr_registry_name}.azurecr.io/${image_name}"
SKIP_CONTAINER_CREATION=false

for i in "$@"; do
  case $i in
    --skip_container_creation) SKIP_CONTAINER_CREATION=true ;;
    -*|--*) echo "Unknown option $i"; exit 1 ;;
  esac
done

if $SKIP_CONTAINER_CREATION; then
  # Confirm if the container is already present
  if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q $CONTAINER_NAME; then
    echo "Docker image ${CONTAINER_NAME} is present."
  else
    echo "Docker image ${CONTAINER_NAME} is not present."
    exit 1
  fi
else
  # Fetch NIM container
  docker login nvcr.io -u \$oauthtoken -p $ngc_api_key
  docker pull $ngc_container

  # Create AzureML dockerfile with NIM inside
  dockerfile_content="FROM ${ngc_container}
  EXPOSE 8000
  USER root
  CMD echo \"NGC API KEY: $NGC_API_KEY\" && bash /opt/nim/start-server.sh"
  echo "$dockerfile_content" > Dockerfile
  chmod a+rwx create_dockerfile.sh
  echo "NIM Dockerfile has been created."

  # Login into ACR registry and upload the NIM container
  echo "Logging into Azure Container Registry"
  az acr login --name $acr_registry_name --resource-group $resource_group
  echo "Building the new docker image and tagging it"
  docker build -t $CONTAINER_NAME -f Dockerfile .
  rm Dockerfile
fi

echo "Pushing the image to ACR"
docker push $CONTAINER_NAME
