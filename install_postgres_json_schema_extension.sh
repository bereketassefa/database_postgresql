#!/bin/bash

# Detect the operating system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    OS=$(uname -s)
fi

# Function to install packages on Alpine
install_alpine() {
    apk add --update $@
}

# Function to install packages on Ubuntu
install_ubuntu() {
    apt-get update
    apt-get install -y $@
}

# Function to get PostgreSQL version on Ubuntu
get_postgres_version_ubuntu() {
    local pg_version=$(ls /usr/share/postgresql/ | grep -E '^[0-9]+$' | sort -rn | head -n1)
    echo "$pg_version"
}

# Install packages based on the detected OS
if [[ "$OS" == *"Alpine"* ]]; then
    echo "Detected Alpine Linux"
    install_alpine make git libpq-dev postgresql-client
elif [[ "$OS" == *"Ubuntu"* ]]; then
    echo "Detected Ubuntu"
    install_ubuntu make git libpq-dev postgresql-client
else
    echo "Unsupported operating system: $OS"
    exit 1
fi

# Clone the repository
git clone https://github.com/gavinwahl/postgres-json-schema/

# Move into the directory
cd postgres-json-schema

# Build the extension
make && make install

if [[ "$OS" == *"Alpine"* ]]; then
    # Create the extension directory if it doesn't exist
    mkdir -p '/usr/local/share/postgresql/extension'
    # Set appropriate permissions for the control file
    chmod 644 /usr/local/share/postgresql/extension/postgres-json-schema.control
elif [[ "$OS" == *"Ubuntu"* ]]; then
    # Get PostgreSQL version
    PG_VERSION=$(get_postgres_version_ubuntu)
    
    if [ -z "$PG_VERSION" ]; then
        echo "Could not determine PostgreSQL version"
        exit 1
    fi
    
    # Create the extension directory if it doesn't exist
    mkdir -p "/usr/share/postgresql/$PG_VERSION/extension"
    # Set appropriate permissions for the control file
    chmod 644 "/usr/share/postgresql/$PG_VERSION/extension/postgres-json-schema.control"
else
    echo "Unsupported operating system: $OS"
    exit 1
fi
