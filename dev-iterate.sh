#!/bin/bash

# Quick iteration scripts for individual services
# Usage: ./dev-iterate.sh [service] [action]

set -e

# Determine docker command (handle sudo if needed)
if ! docker info > /dev/null 2>&1; then
    if sudo docker info > /dev/null 2>&1; then
        DOCKER_CMD="sudo docker compose"
    else
        echo "❌ Docker is not running"
        exit 1
    fi
else
    DOCKER_CMD="docker compose"
fi

COMPOSE_FILE="docker-compose.local.yml"
SERVICE=$1
ACTION=${2:-restart}

if [ -z "$SERVICE" ]; then
    echo "🔧 Quick Iteration Helper"
    echo ""
    echo "Usage: $0 <service> [action]"
    echo ""
    echo "Services:"
    echo "  backend   - Backend Flask API"
    echo "  frontend  - Frontend Flask app"
    echo "  postgres  - PostgreSQL database"
    echo "  redis     - Redis cache"
    echo ""
    echo "Actions:"
    echo "  restart   - Restart service (default)"
    echo "  rebuild   - Rebuild and restart service"
    echo "  logs      - Show service logs"
    echo "  shell     - Open shell in service"
    echo "  stop      - Stop service"
    echo "  start     - Start service"
    echo ""
    echo "Examples:"
    echo "  $0 backend rebuild    # Rebuild backend after code changes"
    echo "  $0 frontend logs      # View frontend logs"
    echo "  $0 backend shell      # Open shell in backend container"
    exit 0
fi

echo "🔧 Running $ACTION on $SERVICE..."

case $ACTION in
    "restart")
        $DOCKER_CMD -f $COMPOSE_FILE restart $SERVICE
        echo "✅ $SERVICE restarted"
        ;;
    "rebuild")
        echo "🔨 Rebuilding $SERVICE..."
        $DOCKER_CMD -f $COMPOSE_FILE up --build -d $SERVICE
        echo "✅ $SERVICE rebuilt and restarted"
        ;;
    "logs")
        $DOCKER_CMD -f $COMPOSE_FILE logs -f $SERVICE
        ;;
    "shell")
        $DOCKER_CMD -f $COMPOSE_FILE exec $SERVICE /bin/bash || \
        $DOCKER_CMD -f $COMPOSE_FILE exec $SERVICE /bin/sh
        ;;
    "stop")
        $DOCKER_CMD -f $COMPOSE_FILE stop $SERVICE
        echo "✅ $SERVICE stopped"
        ;;
    "start")
        $DOCKER_CMD -f $COMPOSE_FILE start $SERVICE
        echo "✅ $SERVICE started"
        ;;
    *)
        echo "❌ Unknown action: $ACTION"
        echo "Valid actions: restart, rebuild, logs, shell, stop, start"
        exit 1
        ;;
esac
