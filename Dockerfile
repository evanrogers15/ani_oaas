# Use the official Ubuntu base image
FROM ubuntu:latest

# Set environment variables to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install necessary packages
RUN apt-get update && \
    apt-get install -y python3 python3-pip curl jq vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up symbolic links for Python and pip if they don't exist
RUN if [ ! -e /usr/bin/python ]; then ln -s /usr/bin/python3 /usr/bin/python; fi
RUN if [ ! -e /usr/bin/pip ]; then ln -s /usr/bin/pip3 /usr/bin/pip; fi

# Install the requests library using pip
RUN pip install requests

# Set the working directory
WORKDIR /

COPY initial/ /initial/

# Make the scripts executable
RUN chmod +x initial/env_setup.sh && \
    chmod +x initial/api_scrape.sh &&

# Define the default command to run when the container starts
CMD ["/bin/bash"]
