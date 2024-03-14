#!/bin/bash

# Function to display help
function show_help() {
    echo "Usage: deploy.sh [OPTIONS]"
    echo "Deploy the ani_oaas container"
    echo ""
    echo "Options:"
    echo "  -d, --detach      Run the container in detached mode"
    echo "  --help            Display this help message"
    echo "  debug             Run the container in debug mode with bash"
}

# Function to stop and remove the existing container
function stop_existing_container() {
    existing_container=$(docker ps -a --filter "name=ani_oaas_test" --format '{{.Names}}' | grep -q '^ani_oaas_test$' && echo "true" || echo "false")
    if [ $existing_container == "true" ]; then
        echo "Stopping the existing ani_oaas_test container..."
        docker stop ani_oaas_test
        docker rm ani_oaas_test
    fi
}

# Check for the --help option
if [[ " $* " == *" --help "* ]]; then
    show_help
    exit 0
fi

# Stop and remove the existing container if it is running
stop_existing_container

# Check if the ani_oaas directory exists in the current directory
if [ -d "ani_oaas" ]; then
    rm -rf ani_oaas
fi

# Check if the ani_oaas directory exists in the parent directory
if [ -d "../ani_oaas" ]; then
    rm -rf ../ani_oaas
fi

# Clone the git project with the specified branch
git clone https://github.com/evanrogers15/ani_oaas.git

# Navigate to the ani_oaas directory
cd ani_oaas

# Build the Docker container with the test tag
docker build -t evanrogers719/ani_oaas:test .

# Check if the -d flag is passed
if [[ " $* " == *" -d "* ]]; then
    # Run the Docker container in detached mode with the specified port mapping(s) and container name
    docker run -d --name ani_oaas_test evanrogers719/ani_oaas:test
else
    # Run the Docker container in foreground with the specified port mapping(s) and container name
    docker run -it --name ani_oaas_test evanrogers719/ani_oaas:test
fi
