#!/bin/bash

# Exit on error
set -e

echo "Smart Stock Docker Setup"
echo "========================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker is not running. Please start Docker and try again."
  exit 1
fi

# Set environment variables
export HOST_USER_ID=$(id -u)
export HOST_GROUP_ID=$(id -g)

# Display configuration
echo "Configuration:"
echo "- MySQL Root Password: root"
echo "- Host User ID: $HOST_USER_ID"
echo "- Host Group ID: $HOST_GROUP_ID"
echo "- Database: smart_stock"
echo "========================"

# Force remove existing containers with the same names
echo "Checking for existing containers..."
for CONTAINER in "dolibarr-mariadb-prod" "dolibarr-web-prod" "dolibarr-phpmyadmin-prod"; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo "Removing existing container: ${CONTAINER}"
    docker rm -f "${CONTAINER}" || true
  fi
done

# Make sure we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
  echo "Error: docker-compose.yml not found in current directory."
  echo "Current directory: $(pwd)"
  exit 1
fi

echo "Starting containers..."
# Run docker-compose with error handling
if ! docker-compose -f docker-compose.yml up -d; then
  echo "Error: Failed to start containers."
  exit 1
fi

# Wait for services to start (increased wait time)
echo "Waiting for services to start..."
sleep 30

# Verify containers are running
if ! docker-compose ps | grep -q "Up"; then
  echo "Error: Containers failed to start properly."
  docker-compose ps
  exit 1
fi

echo -e "\nContainers started successfully:"
docker-compose ps

echo -e "\nAccess information:"
echo "- Dolibarr web interface: http://localhost:8089"
echo "- phpMyAdmin: http://localhost:8080 (username: root, password: root)"

# Check database connectivity
echo -e "\nVerifying database connection..."
# Try multiple times with increasing delays
for i in {1..5}; do
  echo "Attempt $i to connect to database..."
  if docker exec dolibarr-mariadb-prod mariadb -uroot -proot -e "SELECT 1;" >/dev/null 2>&1; then
    echo "Database connection successful!"
    break
  else
    echo "Waiting for database to initialize... (attempt $i)"
    sleep 10
  fi
  
  if [ $i -eq 5 ]; then
    echo "Warning: Unable to connect to database after several attempts."
    echo "Try logging into phpMyAdmin at http://localhost:8080 with username 'root' and password 'root'"
    echo "If problems persist, you may need to rebuild the containers with: docker-compose down -v && ./run.sh"
  fi
done 