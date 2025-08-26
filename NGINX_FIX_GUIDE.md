# nginx默认页面问题修复指南

## 问题描述
访问8080端口显示nginx默认页面而不是思维导图应用界面。

## 根本原因
前端静态文件没有正确复制到nginx的服务目录，导致nginx只能显示默认页面。

## 修复方案

### 方案1: 使用自动化脚本 (推荐)
```bash
# 运行完整修复脚本
./fix-nginx-default-complete.sh
```

### 方案2: 手动执行步骤

#### 步骤1: 检查Docker状态
```bash
# 检查Docker是否运行
docker ps

# 如果Docker未运行，启动Docker Desktop
```

#### 步骤2: 清理旧容器
```bash
# 停止现有容器
docker stop $(docker ps -q --filter "name=mindmap")

# 删除旧容器
docker rm $(docker ps -a -q --filter "name=mindmap")

# 删除旧镜像
docker rmi mindmap-qoder
```

#### 步骤3: 重新构建镜像
```bash
# 无缓存构建新镜像
docker build -t mindmap-qoder . --no-cache
```

#### 步骤4: 启动新容器
```bash
# 启动容器
docker run -d -p 8080:80 --name mindmap-qoder-test mindmap-qoder
```

#### 步骤5: 验证修复
```bash
# 检查容器状态
docker ps

# 检查nginx目录内容
docker exec mindmap-qoder-test ls -la /usr/share/nginx/html/

# 检查index.html是否存在
docker exec mindmap-qoder-test test -f /usr/share/nginx/html/index.html && echo "文件存在" || echo "文件不存在"

# 测试访问
curl -I http://localhost:8080/
```

## 修复的关键改进

### 1. Dockerfile修改
- 添加了copy.js脚本的执行
- 智能文件复制逻辑，支持多种文件结构
- 详细的构建验证步骤

### 2. 文件处理优化
- 根据copy.js的处理结果智能选择文件源
- 支持根目录或dist目录的index.html
- 完整的错误检查和日志输出

### 3. 构建验证
- 构建阶段验证文件存在性
- 生产阶段验证文件复制
- 启动前验证nginx配置

## 常见问题排查

### 问题1: Docker未运行
**现象**: `command not found: docker` 或连接错误
**解决**: 启动Docker Desktop应用

### 问题2: 端口占用
**现象**: 端口绑定失败
**解决**: 
```bash
# 检查端口占用
lsof -i :8080

# 使用其他端口
docker run -d -p 8090:80 --name mindmap-qoder-test mindmap-qoder
```

### 问题3: 构建失败
**现象**: 构建过程中出错
**解决**: 
```bash
# 清理Docker缓存
docker system prune -f

# 检查构建日志
docker build -t mindmap-qoder . --no-cache --progress=plain
```

### 问题4: 文件未复制
**现象**: nginx目录为空或只有默认文件
**解决**: 检查构建日志中的文件验证部分

## 验证成功标准

✅ **修复成功的标志**:
1. 容器正常启动且状态为"Up"
2. nginx目录包含index.html等前端文件
3. 访问localhost:8080显示思维导图界面而非nginx默认页面
4. HTTP状态码为200且返回HTML内容

❌ **仍需修复的标志**:
1. 显示"Welcome to nginx!"页面
2. 404错误或空白页面
3. 静态资源加载失败

## 技术细节

### 构建过程改进
1. **智能依赖安装**: 根据package-lock.json存在情况选择安装命令
2. **copy.js执行**: 确保文件结构按预期处理
3. **多路径支持**: 支持根目录和dist目录的不同文件布局
4. **详细验证**: 每个关键步骤都有验证和错误报告

### 文件路径逻辑
- Vue构建输出: `/app/dist/` (由vue.config.js的outputDir控制)
- copy.js处理: 可能移动文件到根目录
- nginx服务: `/usr/share/nginx/html/`
- 智能复制: 自动检测并使用正确的源路径

如需更多帮助或遇到其他问题，请查看容器日志:
```bash
docker logs mindmap-qoder-test
```