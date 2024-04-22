#!/bin/bash

# Generate a random API token needed for the InfluxDB admin token
INFLUX_INIT_TOKEN=$(openssl rand -base64 64 | tr -d '\n')

# Set the repository name
repository="evanrogers719/ani_oaas"

# Query Docker Hub for the list of images in the repository
image_tags=$(curl -s "https://hub.docker.com/v2/repositories/$repository/tags" | jq -r '.results | .[].name' | head -n 5)
echo "This utility deploys the ANI OaaS platform for the provided customer, complete the prompts to deploy"
# User entry for folder name created for use by ANI OaaS Utility
while true; do
  # Prompt the user for a folder name, with a default value of 'ani_oaas_01'
  read -p "Enter a customer directory name [ani_oaas_01]: " folder_name

  # Set the default value for the folder name if the user did not provide any input
  folder_name=${folder_name:-ani_oaas_01}

  # Check if the folder already exists
  if [ -d "$folder_name" ]; then
    # Output the message indicating that the folder already exists
    echo "Customer Directory '$folder_name' already exists. Please try again."
  else
    # Create the folder
    mkdir "$folder_name"
    # Break out of the loop
    break
  fi
done

# Get a list of IP addresses
ip_list=$(ip addr show | grep inet | awk '{print $2}' | grep -v '127.0.0.1' | grep -v '::')

# Prompt the user to select an IP address
PS3='Please select an IP address that Grafana / InfluxDB will be accessible: '
select ip in $ip_list; do
    if [ -n "$ip" ]; then
        break
    fi
    echo "Invalid selection"
done

# Remove the subnet
selected_ip=$(echo $ip | cut -f1 -d/)

# Print the list of image tags
echo "Available images:"

# Iterate over the list of image tags, and print them with a number prefix
i=1
for image in $image_tags; do
  echo "$i) $repository:$image"
  i=$((i+1))
done

# Set the default selection to the first item in the list
selected_image_index=1

# Prompt the user to select an image from the list
read -p "Enter the number of the image you want to select [default: $selected_image_index]: " index

# If the user didn't provide an input, use the default selection
if [ -z "$index" ]; then
  index=$selected_image_index
fi

# Get the selected image from the list of image tags
selected_image=$(echo "$image_tags" | sed -n "${index}p")

# Set the selected image as the value of the 'selected_image' variable
selected_image="$repository:$selected_image"

# Prompt the user for the AppNeta URL
read -p "Enter the Customer's AppNeta URL (default: app-01.pm.appneta.com): " appNeta_URL
if [ -z "$appNeta_URL" ]; then
  appNeta_URL="app-01.pm.appneta.com"
fi

# Prompt the user for the AppNeta token
read -p "Enter the AppNeta token (default: none): " appNeta_TOKEN
appNeta_TOKEN="${appNeta_TOKEN:-none}"

# Prompt the user for the Grafana Web Service Port
while true; do
    read -p "Enter the Grafana HTTP port (default: 80): " port
    ss -tuln | grep ":$port\b" >/dev/null
    if [ $? -eq 0 ]; then
        echo "Port $port is in use. Please choose another port."
    else
        grafana_PORT=$port
        break
    fi
done

# Prompt the user for the Grafana Web Service Port
while true; do
    read -p "Enter the InfluxDB HTTP port (default: 8080): " port
    ss -tuln | grep ":$port\b" >/dev/null
    if [ $? -eq 0 ]; then
        echo "Port $port is in use. Please choose another port."
    else
        influxDB_PORT=$port
        break
    fi
done

cd $folder_name

# Output the Docker Compose file to a file called docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.0'

networks:
  back-tier:
volumes:
  grafana-data:
  influxdb2:
  api-data:
services:

  api_utility:
    image: $selected_image
    environment: #insert token generated from Appneta here
      - appT=$appNeta_TOKEN
      - appURL=$appNeta_URL
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$INFLUX_INIT_TOKEN
    volumes:
      - ./:/config/:rw
      - api-data:/data:rw
    command: bash -c "./initial/env_setup.sh & ./initial/api_scrape.sh"
    hostname: api_utility.local
    networks:
      - back-tier
    restart: unless-stopped #starts container on reboot

  grafana:
    image: grafana/grafana-enterprise:latest
    hostname: grafana.local
    environment:
      - GF_PATHS_CONFIG=/etc/grafana/custom.ini
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$INFLUX_INIT_TOKEN
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=PW4demosANI!
    ports:
      - $grafana_PORT:3000
    depends_on:
      - api_utility
      - influxdb
    volumes:
      - ./grafana.ini:/etc/grafana/custom.ini
      - ./influxdb_ds.yml:/etc/grafana/provisioning/datasources/influxdb_ds.yml
      - grafana-data:/var/lib/grafana
    networks:
      - back-tier
    healthcheck:
      test: ["CMD", "wget", "-q", "-O", "-", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped #starts container on reboot

  influxdb:
    image: influxdb:latest
    volumes:
      # Mount for influxdb data directory and configuration
      - influxdb2:/var/lib/influxdb2:rw
    environment:
       # Use these same configurations parameters in your telegraf configuration, mytelegraf.conf.
      - DOCKER_INFLUXDB_INIT_MODE=setup
      - DOCKER_INFLUXDB_INIT_USERNAME=admin
      - DOCKER_INFLUXDB_INIT_PASSWORD=PW4demosANI!
      - DOCKER_INFLUXDB_INIT_ORG=bsr
      - DOCKER_INFLUXDB_INIT_BUCKET=bsr_bucket
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$INFLUX_INIT_TOKEN
    ports:
      - $influxDB_PORT:8086
    networks:
      - back-tier
    hostname: influxdb.local
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8086/ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped #starts container on reboot

  telegraf:
    image: telegraf
    logging:
      driver: none
    volumes:
      - ./telegraf.conf:/etc/telegraf/telegraf.conf
      - api-data:/api-data:rw
    environment:
      - DOCKER_INFLUXDB_INIT_ORG=bsr
      - DOCKER_INFLUXDB_INIT_BUCKET=bsr_bucket
      - DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$INFLUX_INIT_TOKEN
    hostname: telegraf.local
    healthcheck:
      test: ["CMD", "sh", "-c", "ps -ef | grep telegraf | grep -v grep || exit 1"]
      interval: 30s
      timeout: 30s
      retries: 3
      start_period: 5s
    depends_on:
      - api_utility
      - influxdb
    networks:
      - back-tier
    restart: unless-stopped #starts container on reboot
EOF

# Run the Docker Compose file
if command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE_COMMAND="docker-compose"
elif command -v "docker" &>/dev/null && docker compose --help &>/dev/null; then
    DOCKER_COMPOSE_COMMAND="docker compose"
else
    echo "Docker Compose not found. Please install Docker Compose."
    exit 1
fi

$DOCKER_COMPOSE_COMMAND up -d

unset INFLUX_INIT_TOKEN
unset appNeta_URL
unset appNeta_TOKEN

echo "Grafana is now available at http://"$selected_ip":"$grafana_PORT"/"
echo "Default username: admin"
echo "Default passowrd: PW4demosANI!"
echo "InfluxDB is now available at http://"$selected_ip":"$influxDB_PORT"/"
echo "Default username: admin"
echo "Default password: PW4demosANI!"