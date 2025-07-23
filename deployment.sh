#!/bin/bash

# Set your deployment path
path="/home/smartiam/deployment"

# Prompt user for repo URL, version, and optional customization name
read -p "Enter the full Git repository URL: " repo_url
repo_name=$(basename -s .git "${repo_url}")
read -p "Enter the version name (branch/tag): " version
read -p "Do you want to provide a customization name for the Docker build? (yes/no): " customization_choice

if [ "${customization_choice}" == "yes" ]; then
  read -p "Enter the customization name: " customization_name
else
  customization_name=""
fi

# Deployment function
function deploy() {
  cd "${path}" || { echo "Deployment path not found: ${path}"; exit 1; }

  if [ -d "${repo_name}" ]; then
    echo "Repository ${repo_name} already exists. Pulling latest changes..."
    cd "${repo_name}" || exit 1
    git fetch --all
    git checkout main 2>/dev/null || echo "Main branch not found, continuing..."
    git pull origin main 2>/dev/null || echo "Failed to pull main, continuing..."
    git checkout "${version}" || { echo "Version ${version} not found"; exit 1; }
    echo "Checked out version: ${version}"
  else
    echo "Cloning repository ${repo_url}..."
    git clone "${repo_url}" || exit 1
    cd "${repo_name}" || exit 1
    git checkout "${version}" || { echo "Version ${version} not found"; exit 1; }
    echo "Checked out version: ${version}"
  fi

  # Prompt to edit .env if it exists
  read -p "Do you want to edit the existing .env file if present? (yes/no): " env_choice
  if [ "${env_choice}" == "yes" ]; then
    if [ -f ".env" ]; then
      echo ".env file found. Opening in nano for editing..."
      nano .env
      echo ".env file saved."
    else
      echo ".env file not found. Skipping as requested."
    fi
  else
    echo "Skipping .env update."
  fi

  # Prompt to edit Dockerfile if it exists
  read -p "Do you want to edit the existing Dockerfile if present? (yes/no): " dockerfile_choice
  if [ "${dockerfile_choice}" == "yes" ]; then
    if [ -f "Dockerfile" ]; then
      echo "Dockerfile found. Opening in nano for editing..."
      nano Dockerfile
      echo "Dockerfile saved."
    else
      echo "Dockerfile not found. Skipping edit."
    fi
  else
    echo "Skipping Dockerfile update."
  fi

  # Docker image build
  echo "Checking for Dockerfile..."
  if [ -f "Dockerfile" ]; then
    echo "Dockerfile found. Building Docker image..."
    if [ -n "${customization_name}" ]; then
      docker build -t "${customization_name}:${version}" .
    else
      docker build -t "${repo_name}:${version}" .
    fi
    echo "Docker image built successfully."
  else
    echo "Dockerfile not found. Skipping Docker build."
  fi
}

# Run deployment
deploy

echo "Deployment script completed."
exit 0
