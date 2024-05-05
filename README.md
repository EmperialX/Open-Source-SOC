# Open-Source-SOC
Building one Solution for Threat management and detection for you network with Open source SOC solution. 


Manual for setup the Log-collection dashboard for the grafana/loki and logstash to collect any log and pass to the data source in loki for visual representation. This is for Docker Compose file for single soution.


# Directory Structure
```
├── docker-compose.yml
├── grafana
│   └── Dockerfile.grafana2
├── logstash
│   └── Dockerfile.logstash2
└── loki
    ├── Dockerfile.loki3
    └── loki-local-config.yaml
```
### Build the Directory
```
mkdir Log-Collection
cd Log-Collection
mkdir grafana loki logstash
```

## docker-compose.yml
> nano docker-compose.yml
```
version: '3'
services:
  grafana:
    image: mygrafana
    ports:
      - 3000:3000
  loki:
    image: myloki
    ports:
      - 3100:3100
  logstash:
    image: mylogstash
    ports:
      - 9600:9600
```

## Grafana Docker File
> nano grafana/Dockerfile.grafana
```
FROM ubuntu:latest

# Install necessary packages and dependencies
RUN apt-get update && \
    apt-get install -y apt-transport-https software-properties-common wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Import the GPG key and add Grafana repository
RUN mkdir -p /etc/apt/keyrings/ && \
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list

# Update the list of available packages and install Grafana
RUN apt-get update && \
    apt-get install -y grafana

EXPOSE 3000

CMD ["/usr/sbin/grafana-server", "-homepath", "/usr/share/grafana"]
```

## Loki Docker File
Before Editing download the loki config file. If you face any issue commnet out the encoding from the file.
> cd loki 
```
wget https://raw.githubusercontent.com/grafana/loki/main/cmd/loki/loki-local-config.yaml
```
> nano loki/Dockerfile.loki

```
# Start from the latest Ubuntu image
FROM ubuntu:latest

# Install necessary packages
RUN apt-get update && \
    apt-get install -y wget

# Download Loki
RUN wget https://github.com/grafana/loki/releases/download/v2.9.8/loki_2.9.8_amd64.deb

# Make Loki executable
RUN chmod +x loki_2.9.8_amd64.deb

# Install Loki
RUN apt-get install ./loki_2.9.8_amd64.deb

# Set the working directory
WORKDIR /loki

# Copy the Loki configuration file from your local system into the Docker image
COPY ./loki/loki-local-config.yaml /loki/loki-local-config.yaml

# Use the Loki configuration file
CMD ["loki", "-config.file=/loki/loki-local-config.yaml"]
```

## Logstash Docker File
> nano logstash/Dockerfile.logstash
```
FROM ubuntu:latest

# Install necessary packages and dependencies
RUN apt-get update && \
    apt-get install -y wget apt-transport-https gnupg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and install the Public Signing Key
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg

# Save the repository definition
RUN echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-8.x.list

# Update the list of available packages and install Logstash
RUN apt-get update && \
    apt-get install -y logstash
RUN /usr/share/logstash/bin/logstash-plugin install logstash-output-loki
# Create Logstash configuration file
RUN mkdir -p /etc/logstash/conf.d/ && \
    echo 'input {\n  udp {\n    port => 514\n    type => syslog\n  }\n}\n\noutput {\n  loki {\n    url => "http://localhost:3100/loki/api/v1/push"\n  }\n}' > /etc/logstash/conf.d/fortigate.conf

EXPOSE 9600

CMD ["/usr/share/logstash/bin/logstash", "-f", "/etc/logstash/conf.d/fortigate.conf"]
```

### Commands to build all Projects.
```
docker build -t mygrafana -f ./grafana/Dockerfile.grafana .
docker build -t mylogstash -f ./logstash/Dockerfile.logstash .
docker build -t myloki -f ./loki/Dockerfile.loki .
```

### Command to remove stop and remove docker files
```
docker-compose down -v --rmi all --remove-orphans

```


