#!/bin/bash

# Local Development Script for sliostudio
# This script helps you run the application locally using Docker Compose

set -e

echo "🚀 Starting sliostudio in local development mode..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running or requires sudo. Checking with sudo..."
    if ! sudo docker info > /dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker and try again."
        exit 1
    else
        echo "⚠️  Docker requires sudo. You may need to add your user to the docker group:"
        echo "   sudo usermod -aG docker $USER"
        echo "   Then log out and log back in."
        echo ""
        DOCKER_CMD="sudo docker compose"
    fi
else
    DOCKER_CMD="docker compose"
fi

# Function to cleanup on exit
cleanup() {
    echo "🧹 Cleaning up..."
    $DOCKER_CMD -f docker-compose.local.yml down
}

# Trap cleanup function on script exit
trap cleanup EXIT

# Build and start the services
echo "🔨 Building and starting services..."
$DOCKER_CMD -f docker-compose.local.yml up --build --remove-orphans

echo "✅ Local development environment started successfully!"
echo ""
echo "🌐 Your application is now running at:"
echo "   Frontend: http://localhost:8080"
echo "   Backend API: http://localhost:5000"
echo "   Redis: localhost:6379"
echo "   PostgreSQL: localhost:5432"
echo ""
echo "💡 To stop the services, press Ctrl+C"
echo ""
echo "🔧 Useful commands:"
echo "   View logs: $DOCKER_CMD -f docker-compose.local.yml logs -f"
echo "   Stop services: $DOCKER_CMD -f docker-compose.local.yml down"
echo "   Rebuild specific service: $DOCKER_CMD -f docker-compose.local.yml up --build <service_name>"
