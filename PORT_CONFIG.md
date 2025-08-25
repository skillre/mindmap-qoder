# 端口配置说明

## 概述

为避免端口冲突，项目使用以下端口映射配置：

## 端口映射方案

### 生产环境 (docker-compose.yml / docker-compose.prod.yml)
- **前端服务**: `8080:80` (nginx)
  - 外部访问: http://localhost:8080
  - 容器内部: 80
- **后端服务**: `3001:3000` (node.js)
  - 外部访问: http://localhost:3001
  - 容器内部: 3000

### 开发环境 (docker-compose.dev.yml)
- **前端服务**: `8080:80` (nginx)
- **后端API**: `3001:3000` (node.js)
- **前端开发服务器**: `8081:8080` (vue dev server)
- **Redis**: `6379:6379`

## 快速启动命令

### 使用Docker Compose（推荐）
```bash
# 启动生产环境
docker-compose up -d

# 启动开发环境
docker-compose -f docker-compose.dev.yml up -d

# 启动生产环境（优化版）
docker-compose -f docker-compose.prod.yml up -d
```

### 使用Docker命令
```bash
# 构建镜像
docker build -t mindmap-qoder:latest .

# 启动容器
docker run -d \
  --name mindmap-qoder \
  -p 8080:80 \
  -p 3001:3000 \
  mindmap-qoder:latest
```

## 访问地址

### 生产环境
- **思维导图应用**: http://localhost:8080
- **后端API**: http://localhost:3001
- **健康检查**: http://localhost:8080/health

### 开发环境
- **思维导图应用**: http://localhost:8080
- **前端开发服务器**: http://localhost:8081 (热重载)
- **后端API**: http://localhost:3001
- **Redis**: localhost:6379

## 故障排除

### 端口冲突
如果遇到端口冲突，可以：

1. **检查端口占用**:
   ```bash
   # macOS/Linux
   lsof -i :8080
   netstat -an | grep 8080
   
   # Windows
   netstat -an | findstr 8080
   ```

2. **停止占用端口的服务**:
   ```bash
   # 停止Docker容器
   docker stop $(docker ps -q --filter "publish=8080")
   
   # 停止本地开发服务器
   pkill -f "webpack-dev-server"
   pkill -f "vue-cli-service"
   ```

3. **修改端口映射**:
   在docker-compose.yml中修改端口：
   ```yaml
   ports:
     - "9080:80"    # 改为9080
     - "3002:3000"  # 改为3002
   ```

### 常见端口冲突
- **8080**: 通常被开发服务器使用
- **3000**: 通常被React/Node.js开发服务器使用
- **80**: 通常被系统Web服务器使用

### 端口选择建议
- **前端**: 8080, 9080, 8000, 8888
- **后端**: 3001, 3002, 8001, 8002
- **数据库**: 默认端口 + 1000 (如Redis: 7379)

## 验证配置

使用提供的验证脚本检查配置：
```bash
# 验证端口配置
./test-build-path.sh

# 完整构建测试
./test-docker-build.sh

# 故障排除
./docker-troubleshoot.sh
```

## 安全注意事项

1. **生产环境**: 不要将内部端口(3000)直接暴露到公网
2. **防火墙**: 确保只开放必要的端口
3. **代理**: 在生产环境中使用反向代理(nginx/Apache)
4. **SSL**: 生产环境应配置HTTPS (443端口)