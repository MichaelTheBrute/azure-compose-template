# Local Development Setup

This directory contains everything you need to run sliostudio locally for development.

## Quick Start

1. **Start the local development environment:**
   ```bash
   ./dev-local.sh
   ```

2. **Access your application:**
   - Frontend: http://localhost:8080
   - Backend API: http://localhost:5000
   - PostgreSQL: localhost:5432
   - Redis: localhost:6379

## Manual Commands

If you prefer to run commands manually (use `sudo` if needed):

```bash
# Start all services
docker compose -f docker-compose.local.yml up --build

# Start in background
docker compose -f docker-compose.local.yml up --build -d

# View logs
docker compose -f docker-compose.local.yml logs -f

# Stop services
docker compose -f docker-compose.local.yml down

# Remove volumes (reset database)
docker compose -f docker-compose.local.yml down -v
```

**Note:** If you get permission errors, you may need to use `sudo` before the docker commands, or add your user to the docker group:
```bash
sudo usermod -aG docker $USER
# Then log out and log back in
```

## Database Access

The local PostgreSQL database is automatically initialized with:
- Database: `sliostudio`
- Username: `postgres`
- Password: `postgres`
- Port: `5432`

Connect using any PostgreSQL client or command line:
```bash
psql -h localhost -U postgres -d sliostudio
```

## File Structure

- `docker-compose.local.yml` - Local development Docker Compose configuration
- `init-db.sql` - Database initialization script
- `dev-local.sh` - Convenient startup script
- `.env.local.template` - Environment variables template

## Development Features

- **Hot reloading**: Source code is mounted as volumes for quick iteration
- **Database persistence**: PostgreSQL data persists between container restarts
- **Health checks**: Services wait for dependencies to be ready
- **Isolated environment**: Completely separate from Azure deployment configuration

## Troubleshooting

1. **Port conflicts**: Make sure ports 5000, 8080, 5432, and 6379 are not in use
2. **Docker issues**: Restart Docker Desktop if you encounter connection issues
3. **Database connection**: Wait a few seconds for PostgreSQL to fully start
4. **Clean slate**: Run `docker compose -f docker-compose.local.yml down -v` to reset everything
