#!/bin/bash

# Clone the Wazuh Docker project
git clone https://github.com/wazuh/wazuh-docker.git -b v4.7.4

# Navigate to the single-node directory
cd wazuh-docker/single-node &&

# Check if the configuration is already present
if ! grep -q "<remote>\n    <connection>syslog<\/connection>\n    <port>5140<\/port>\n    <protocol>udp<\/protocol>\n    <allowed-ips>0.0.0.0\/0<\/allowed-ips>\n  <\/remote>" config/wazuh_cluster/wazuh_manager.conf; then
    # If not, append it
    echo "Appending configuration to Wazuh manager configuration file..." &&
    echo -e "\n<remote>\n    <connection>syslog</connection>\n    <port>5140</port>\n    <protocol>udp</protocol>\n    <allowed-ips>0.0.0.0/0</allowed-ips>\n  </remote>" >> config/wazuh_cluster/wazuh_manager.conf &&
    echo "Configuration appended successfully."
fi &&

# Generate the certificates
docker-compose -f generate-indexer-certs.yml run --rm generator &&

# Modify Docker Compose file
sed -i 's/9200:9200/9201:9200/g' docker-compose.yml &&
sed -i 's/443:5601/5500:5601/g' docker-compose.yml &&

# Set the vm.max_map_count parameter
sysctl -w vm.max_map_count=262144 &&

# Start the Docker Compose services
docker-compose up -d
