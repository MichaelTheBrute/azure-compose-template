# Development Iteration Workflows 🚀

Now that your local environment is running, here are the different ways you can quickly iterate on individual containers:

## 🔒 Security Note: Debug Mode

**Debug mode is automatically managed for security:**
- ✅ **Local development**: Debug mode enabled for hot reloading
- ✅ **Azure production**: Debug mode always disabled (secure)
- ✅ **Automatic detection**: Uses Azure environment detection

Run `./security-check.sh` to validate this configuration anytime.

## 🔥 Hot Reloading (Fastest)

**What it does:** Flask apps automatically reload when you change Python files
**When to use:** Making code changes to existing files

✅ **Already enabled!** Just edit your Python files and Flask will automatically restart:
- Edit `backend/src/app.py` → Backend automatically reloads
- Edit `frontend/src/app.py` → Frontend automatically reloads  
- Edit `frontend/templates/*.html` → Changes appear immediately

**No restart needed!** Your changes appear in seconds.

## 🔄 Quick Service Restart

**What it does:** Restart individual services without rebuilding
**When to use:** When hot reload doesn't pick up changes (new dependencies, Docker config changes)

```bash
# Restart just the backend
./dev-iterate.sh backend restart

# Restart just the frontend  
./dev-iterate.sh frontend restart
```

## 🔨 Rebuild Individual Services

**What it does:** Rebuild Docker image and restart service
**When to use:** New dependencies, Dockerfile changes, or if something is broken

```bash
# Rebuild backend (if you added new pip packages)
./dev-iterate.sh backend rebuild

# Rebuild frontend
./dev-iterate.sh frontend rebuild

# Or manually:
docker compose -f docker-compose.local.yml up --build -d backend
```

## 📊 Monitor Services

```bash
# View logs for specific service
./dev-iterate.sh backend logs
./dev-iterate.sh frontend logs

# Get shell access to debug
./dev-iterate.sh backend shell
./dev-iterate.sh frontend shell

# Check service status
docker compose -f docker-compose.local.yml ps
```

## ⚡ Speed Comparison

| Change Type | Method | Speed | Command |
|-------------|--------|-------|---------|
| Edit Python code | Hot reload | ~2-3 seconds | Just save the file! |
| New Python dependency | Rebuild service | ~30-60 seconds | `./dev-iterate.sh backend rebuild` |
| Edit HTML template | Hot reload | Instant | Just save the file! |
| Dockerfile change | Rebuild service | ~30-60 seconds | `./dev-iterate.sh [service] rebuild` |
| Full reset | Rebuild all | ~2-3 minutes | `docker compose -f docker-compose.local.yml up --build` |

## 🎯 Recommended Workflow

1. **Start environment once:** `./dev-local.sh`
2. **Make code changes:** Edit files normally
3. **See changes:** Most changes appear automatically via hot reload
4. **If issues:** Use `./dev-iterate.sh [service] restart` 
5. **New dependencies:** Use `./dev-iterate.sh [service] rebuild`

## 🐛 Troubleshooting

**Hot reload not working?**
- Check the service logs: `./dev-iterate.sh backend logs`
- Restart the service: `./dev-iterate.sh backend restart`

**Service won't start?**
- Check for Python syntax errors in your code
- Rebuild the service: `./dev-iterate.sh backend rebuild`

**Need fresh start?**
- Stop everything: `docker compose -f docker-compose.local.yml down`
- Start fresh: `./dev-local.sh`

You now have a super fast development setup! 🎉
