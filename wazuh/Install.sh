#!/bin/bash

PROJECT_DIR="wazuh-docker"
GIT_URL="https://github.com/wazuh/wazuh-docker.git"
BRANCH="v4.7.4"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Cloning the Wazuh Docker project..."
    git clone "$GIT_URL" -b "$BRANCH" && \
    echo "Cloning successful." || \
    { echo "Cloning failed. Exiting."; exit 1; }
else
    echo "Project directory already exists. Skipping clone."
fi
echo "Removing unwanted files and folders..."
rm -rf "$PROJECT_DIR/build-docker-images/" \
       "$PROJECT_DIR/CHANGELOG.md" \
       "$PROJECT_DIR/indexer-certs-creator/" \
       "$PROJECT_DIR/LICENSE" \
       "$PROJECT_DIR/multi-node/" \
       "$PROJECT_DIR/README.md" \
       "$PROJECT_DIR/VERSION" && \
echo "Cleanup successful." || \
{ echo "Cleanup failed. Exiting."; exit 1; }
cd "$PROJECT_DIR/single-node" && \
echo "Generating indexer certificates..."
docker-compose -f generate-indexer-certs.yml run --rm generator && \
echo "Certificate generation successful." || \
{ echo "Certificate generation failed. Exiting."; exit 1; }
echo "Modifying Docker Compose file..."
sed -i 's/9200:9200/9203:9200/g' docker-compose.yml && \
sed -i 's/443:5601/5500:5601/g' docker-compose.yml && \
echo "Docker Compose file modified successfully." || \
{ echo "Failed to modify Docker Compose file. Exiting."; exit 1; }
echo "Setting vm.max_map_count parameter..."
sysctl -w vm.max_map_count=262144 && \
echo "vm.max_map_count parameter set successfully." || \
{ echo "Failed to set vm.max_map_count parameter. Exiting."; exit 1; }
echo "Starting Docker Compose services..."
docker-compose up -d && \
echo "Docker Compose services started successfully." || \
{ echo "Failed to start Docker Compose services. Exiting."; exit 1; }
