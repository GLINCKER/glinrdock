# GlinrDock Quick Start Guide

Get your first container deployed in 5 minutes with GlinrDock's streamlined workflow.

## 🚀 Installation (30 seconds)

Choose your preferred method:

### Option A: Quick Install
```bash
curl -fsSL https://github.com/glinr/glinrdock/releases/latest/download/install.sh | sudo bash
```

### Option B: Docker Compose
```bash
curl -fsSL https://raw.githubusercontent.com/glinr/glinrdock/main/deploy/docker-compose.yml -o docker-compose.yml
docker-compose up -d
```

## 🎯 First Login (30 seconds)

1. **Open the dashboard:** http://localhost:8080
2. **Find your admin token:**
   ```bash
   # For script installation
   sudo cat /etc/glinrdock/glinrdock.conf | grep ADMIN_TOKEN
   
   # For Docker Compose
   docker-compose logs glinrdock | grep "Admin token"
   ```
3. **Login** with the admin token

## 📦 Deploy Your First Container (2 minutes)

### Method 1: Using the Web UI

1. **Navigate to Projects** → Click "New Project"
2. **Create Project:**
   - Name: `my-first-app`
   - Description: `My first container deployment`
   - Click "Create"

3. **Add a Service:**
   - Click "Add Service"
   - Service name: `nginx-demo`
   - Image: `nginx:alpine`
   - Port mapping: `80:80` (container:host)
   - Click "Deploy"

4. **Access your app:** http://localhost:80

### Method 2: Using the API

```bash
# Set your admin token
export ADMIN_TOKEN="your-token-here"
export API_URL="http://localhost:8080/v1"

# Create a project
curl -X POST "$API_URL/projects" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-first-app",
    "description": "My first container deployment"
  }'

# Deploy nginx service
curl -X POST "$API_URL/projects/1/services" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "nginx-demo",
    "image": "nginx:alpine",
    "ports": [{"host_port": 80, "container_port": 80}]
  }'
```

### Method 3: Import Docker Compose

If you have an existing `docker-compose.yml`:

```bash
# Using the CLI (when available)
glinrdockd import compose docker-compose.yml

# Using the API
curl -X POST "$API_URL/projects/import/compose" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -F "file=@docker-compose.yml"
```

## 🔍 Explore the Dashboard (2 minutes)

### Main Navigation
- **🏠 Overview** - System status and quick stats
- **📋 Projects** - Manage your container projects  
- **🐳 Containers** - View all running containers
- **📊 Monitoring** - Real-time resource usage
- **⚙️ Settings** - System configuration

### Key Features to Try

#### 1. Real-time Monitoring
- Click on any container to see live logs
- Monitor CPU, memory, and network usage
- Set up resource alerts

#### 2. Project Management
```bash
# Create a multi-service project
curl -X POST "$API_URL/projects" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "web-stack",
    "description": "Full web application stack"
  }'

# Add database service
curl -X POST "$API_URL/projects/2/services" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "postgres",
    "image": "postgres:15-alpine",
    "environment": ["POSTGRES_DB=myapp", "POSTGRES_USER=user", "POSTGRES_PASSWORD=secure123"],
    "volumes": ["postgres-data:/var/lib/postgresql/data"],
    "ports": [{"host_port": 5432, "container_port": 5432}]
  }'

# Add web application
curl -X POST "$API_URL/projects/2/services" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "webapp",
    "image": "node:18-alpine",
    "command": ["npm", "start"],
    "environment": ["DATABASE_URL=postgresql://user:secure123@postgres:5432/myapp"],
    "ports": [{"host_port": 3000, "container_port": 3000}],
    "depends_on": ["postgres"]
  }'
```

#### 3. Container Operations
- **Start/Stop/Restart** containers from the UI
- **View logs** in real-time with filtering
- **Execute commands** in running containers
- **Update images** with zero-downtime deployments

## 🛠️ Common Deployment Patterns

### Static Website
```bash
curl -X POST "$API_URL/projects/1/services" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "static-site",
    "image": "nginx:alpine",
    "volumes": ["./site:/usr/share/nginx/html:ro"],
    "ports": [{"host_port": 8080, "container_port": 80}]
  }'
```

### Database with Backup
```bash
curl -X POST "$API_URL/projects/1/services" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mysql",
    "image": "mysql:8.0",
    "environment": [
      "MYSQL_ROOT_PASSWORD=rootpass123",
      "MYSQL_DATABASE=appdb",
      "MYSQL_USER=appuser",
      "MYSQL_PASSWORD=apppass123"
    ],
    "volumes": [
      "mysql-data:/var/lib/mysql",
      "./backups:/backups"
    ],
    "ports": [{"host_port": 3306, "container_port": 3306}],
    "health_check": {
      "test": ["CMD", "mysqladmin", "ping", "-h", "localhost"],
      "interval": "10s",
      "timeout": "5s",
      "retries": 5
    }
  }'
```

### Development Environment
```bash
curl -X POST "$API_URL/projects/1/services" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "dev-env",
    "image": "node:18-alpine",
    "command": ["npm", "run", "dev"],
    "working_dir": "/app",
    "volumes": ["./app:/app", "node_modules:/app/node_modules"],
    "ports": [{"host_port": 3000, "container_port": 3000}],
    "environment": ["NODE_ENV=development"],
    "restart_policy": "unless-stopped"
  }'
```

## 🔐 Security Best Practices (1 minute)

### 1. Secure Your Admin Token
```bash
# Generate a strong token
ADMIN_TOKEN=$(openssl rand -hex 32)

# Update configuration
sudo sed -i "s/ADMIN_TOKEN=.*/ADMIN_TOKEN=$ADMIN_TOKEN/" /etc/glinrdock/glinrdock.conf
sudo systemctl restart glinrdock.service
```

### 2. Network Security
```bash
# Restrict access to internal networks only
sudo ufw allow from 10.0.0.0/8 to any port 8080
sudo ufw allow from 172.16.0.0/12 to any port 8080
sudo ufw allow from 192.168.0.0/16 to any port 8080
```

### 3. Use Non-Root Containers
```json
{
  "name": "secure-app",
  "image": "nginx:alpine",
  "user": "nginx",
  "read_only": true,
  "security_opt": ["no-new-privileges:true"]
}
```

## 📚 Next Steps

### Learn More
- **[Installation Guide](./INSTALL.md)** - Detailed setup instructions
- **[Security Guide](./SECURITY.md)** - Production security practices
- **[API Documentation](./docs/API.md)** - Complete REST API reference
- **[UI Guide](./docs/UI-LITE.md)** - Master the web interface

### Advanced Features
- **Multi-Registry Support** - Connect to private registries
- **Webhook Integration** - Auto-deploy from Git pushes  
- **RBAC System** - Team-based access control
- **Monitoring & Alerts** - Resource usage notifications
- **Backup & Restore** - Automated data protection

### Get Help
- **Issues:** [GitHub Issues](https://github.com/GLINCKER/glinrdock/issues)
- **Discussions:** [GitHub Discussions](https://github.com/GLINCKER/glinrdock/discussions)
- **Security:** [Security Policy](./SECURITY.md)
- **Enterprise:** contact@glinr.dev

## You're Ready!

Congratulations! You've successfully:
- Installed GlinrDock
- Deployed your first container
- Explored the dashboard
- Learned common deployment patterns

Your container management platform is ready for production workloads.

---

**Next:** Dive deeper with our [complete documentation](./docs/) or start building your container infrastructure!