# bsr_utility
# BSR Application

## **Overview**

This utility polls specified Appneta API metrics, stores in local InfluxDB time series database, and displays data via local Grafana instance.

Persistent storage is maintained via Docker volumes. Data persist for Grafana and InfluxDB across machine / composer reboots.

It is comprised of four containerized pieces:

- **Grafana --** Data Visualizations
- **Telegraf**- Used to scrape metrics
- **Appneta_API_Utility** -- Utility that creates the environment
- **InfluxDB** -- Time Series Database

The four containers are wrapped into a single Docker Compose file in order to reduce complexity and allow the application to be start and run via one command.

The following files specified below are what run the utility. The only one that needs to be created is the docker-compose.yml file. All other files are created dynamically at run time via the BSR_Scrape_Utility

- api_scrape.sh -- Config file for the API integration utility
- env_setup.sh -- Config file that sets up the environment
- influxdb_ds.yml -- Config file for Grafana data source initiation
- docker-compose.yml -- File that constructs the Docker services, specific information regarding authentication and URLs are entered here as variables

The containers are specified to restart, therefore are persistent across reboots. Though if you stop them manually they will remain down.

Information needed for deployment:

- Appneta API Token
- Appneta API URLs for needed metrics
- A standard Docker account in order to pull images

## Docker Setup

Configure local machine with Docker components needed to run the utility

#install yum utils

sudo yum install -y yum-utils

#add docker repo for yum

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

#install docker

sudo yum -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

#start docker

systemctl start docker

#add docker to startup

systemctl enable docker

#login to docker with credentials so that you can pull images

docker login

## BSR Utility First Run Utility

Create a shell script with the below contents, it will do the following:

- Creates API admin token used by InfluxDB
- Requests user to select the local address that will be used for services
- Allows user to choose specific version of the BSR Scrape Utility from Docker Hub (Currently located in my personal repository)
- Creates the local directory that will contain the Docker Compose file and other files needed for the utility
- Requests the AppNeta instance URL from the user
- Requests the AppNeta API token from the user
- Requests the desired Grafana HTTP port
- Requests the desired InfluxDB HTTP port
- Creates the Docker Compose file
- Runs the Docker Compose instance and provisions all services
- Clears out environment variables for sensitive information.
- Lists the URLs for the running Grafana and InfluxDB instances


