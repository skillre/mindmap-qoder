# mindmap-qoder GitHub存储版 部署指南

## 🚀 快速开始

mindmap-qoder 现已集成 GitHub 私有仓库存储功能，支持实时/定时自动保存，提供完整的云端文件管理能力。

### ⚡ 一键部署（推荐）

```bash
# 克隆项目
git clone <repository-url>
cd mindmap-qoder

# 生产环境部署
docker-compose -f docker-compose.prod.yml up -d

# 开发环境部署
docker-compose -f docker-compose.dev.yml up
```

访问 `http://localhost` 开始使用！

## 📋 系统要求

### 最低配置
- **CPU**: 1核心
- **内存**: 512MB
- **存储**: 1GB
- **网络**: 能够访问GitHub API

### 推荐配置
- **CPU**: 2核心
- **内存**: 1GB
- **存储**: 5GB
- **网络**: 稳定的互联网连接

### 软件依赖
- Docker 20.10+
- Docker Compose 2.0+
- Node.js 16+ (仅开发环境)

## 🔧 部署选项

### 选项 1: Docker Compose (推荐)

#### 生产环境
```bash
# 复制环境变量文件
cp .env.production .env

# 根据需要修改配置
vim .env

# 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 查看服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f
```

#### 开发环境
```bash
# 复制环境变量文件
cp .env.development .env

# 启动开发服务
docker-compose -f docker-compose.dev.yml up

# 支持热重载，代码修改后自动更新
```

### 选项 2: 单容器部署

```bash
# 构建镜像
docker build -t mindmap-qoder .

# 运行容器
docker run -d \
  --name mindmap-qoder \
  -p 80:80 \
  -p 3000:3000 \
  -e NODE_ENV=production \
  mindmap-qoder
```

### 选项 3: 本地开发

```bash
# 安装后端依赖
cd server && npm install

# 安装前端依赖
cd ../web && npm install
cd ../simple-mind-map && npm install

# 启动后端服务
cd server && npm start

# 启动前端服务
cd web && npm run serve
```

## ⚙️ 配置说明

### 环境变量

#### `.env.production` (生产环境)
```bash
NODE_ENV=production
PORT=3000
REDIS_PASSWORD=your-secure-password
CORS_ORIGIN=https://yourdomain.com
LOG_LEVEL=info
```

#### `.env.development` (开发环境)
```bash
NODE_ENV=development
PORT=3000
DEBUG=true
LOG_LEVEL=debug
HOT_RELOAD=true
```

### GitHub配置

1. **创建 Personal Access Token**
   - 访问 [GitHub Settings > Tokens](https://github.com/settings/tokens)
   - 点击 "Generate new token (classic)"
   - 勾选 `repo` 权限（访问私有仓库）
   - 生成并复制 Token

2. **应用内配置**
   - 打开应用，点击工具栏"配置"按钮
   - 输入 GitHub Token
   - 选择私有仓库和分支
   - 设置自动保存间隔
   - 保存配置

## 🌐 Nginx 配置

### 标准HTTP配置 (nginx.conf)
- 支持前后端代理
- 启用 Gzip 压缩
- 静态资源缓存
- API 请求限流

### HTTPS配置 (nginx.https.conf)
```bash
# 准备SSL证书
mkdir -p ssl/
# 将证书文件放置到 ssl/ 目录
# - cert.pem (证书文件)
# - key.pem (私钥文件)

# 使用HTTPS配置
docker run -d \
  -p 443:443 \
  -v $(pwd)/ssl:/etc/nginx/ssl \
  -v $(pwd)/nginx.https.conf:/etc/nginx/nginx.conf \
  mindmap-qoder
```

## 🔍 监控和维护

### 健康检查
```bash
# 检查应用状态
curl http://localhost/health

# 预期返回
{
  "success": true,
  "message": "Server is running",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### 日志管理
```bash
# 查看应用日志
docker-compose logs -f mindmap-app

# 查看 Nginx 日志
docker exec mindmap-qoder-app tail -f /var/log/nginx/access.log
docker exec mindmap-qoder-app tail -f /var/log/nginx/error.log
```

### 性能监控
```bash
# 查看容器资源使用情况
docker stats

# 查看磁盘使用
docker system df
```

## 🚨 故障排除

### 常见问题

#### 1. 容器无法启动
```bash
# 检查端口占用
lsof -i :80
lsof -i :3000

# 检查 Docker 日志
docker-compose logs
```

#### 2. GitHub API 连接失败
- 检查网络连接
- 验证 Token 权限
- 检查 API 限流状态

#### 3. 前后端通信异常
- 检查 nginx 配置
- 验证代理设置
- 查看网络日志

#### 4. 自动保存失败
- 检查 GitHub Token 有效性
- 验证仓库权限
- 查看后端日志

### 调试模式

#### 开启详细日志
```bash
# 修改环境变量
export LOG_LEVEL=debug
export DEBUG=true

# 重启服务
docker-compose restart
```

#### 手动测试 API
```bash
# 测试健康检查
curl -v http://localhost/health

# 测试 GitHub API 代理
curl -X POST http://localhost/api/github/validate-token \
  -H "Content-Type: application/json" \
  -d '{"token":"your-github-token"}'
```

## 🔐 安全配置

### 生产环境安全检查清单

- [ ] 使用 HTTPS
- [ ] 设置强密码
- [ ] 配置防火墙
- [ ] 定期更新依赖
- [ ] 配置访问限制
- [ ] 启用请求限流
- [ ] 设置安全头
- [ ] 定期备份数据

### 建议的安全配置

#### 防火墙规则
```bash
# 只允许必要端口
ufw allow 22    # SSH
ufw allow 80    # HTTP
ufw allow 443   # HTTPS
ufw enable
```

#### Docker 安全
```bash
# 使用非root用户运行
# 已在 Dockerfile.prod 中配置

# 定期更新镜像
docker-compose pull
docker-compose up -d
```

## 📈 性能优化

### 建议配置

#### 生产环境优化
```yaml
# docker-compose.prod.yml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 512M
    reservations:
      cpus: '0.5'
      memory: 256M
```

#### Nginx 缓存优化
```nginx
# 静态资源缓存
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 监控指标

- 响应时间 < 2秒
- 内存使用 < 512MB
- CPU 使用 < 50%
- 磁盘使用 < 80%

## 🔄 升级和备份

### 升级流程
```bash
# 1. 备份当前版本
docker-compose down
docker commit mindmap-qoder-app mindmap-backup:$(date +%Y%m%d)

# 2. 拉取新版本
git pull origin main

# 3. 重新构建和部署
docker-compose build --no-cache
docker-compose up -d
```

### 备份策略
```bash
# 定期备份脚本
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker commit mindmap-qoder-app mindmap-backup:$DATE
docker save mindmap-backup:$DATE | gzip > backup_$DATE.tar.gz
```

## 📞 技术支持

- 查看 [TESTING.md](./TESTING.md) 获取测试指南
- 查看 [项目 Issues](issues-url) 报告问题
- 参考 [架构文档](architecture-url) 了解技术细节

---

🎉 **恭喜！** 您已成功部署 mindmap-qoder GitHub存储版本。开始创建您的第一个云端思维导图吧！