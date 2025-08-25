#!/bin/bash

# Docker构建综合故障排除脚本
# 自动诊断和修复常见的Docker构建问题

echo "=== Docker构建故障排除脚本 ==="
echo

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未找到Docker命令，请先安装Docker"
    exit 1
fi

echo "✅ Docker已就绪"

# 检查Docker daemon是否运行
if ! docker info >/dev/null 2>&1; then
    echo "❌ 错误: Docker daemon未运行，请启动Docker"
    exit 1
fi

echo "✅ Docker daemon正在运行"
echo

# 显示当前Docker状态
echo "📊 当前Docker状态："
echo "镜像数量: $(docker images -q | wc -l)"
echo "容器数量: $(docker ps -a -q | wc -l)"
echo "运行中容器: $(docker ps -q | wc -l)"
echo

# 检查磁盘空间
echo "💾 检查磁盘空间..."
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 5 ]; then
    echo "⚠️  警告: 磁盘空间不足 (${AVAILABLE_SPACE}GB)，建议清理"
fi

echo
echo "🔧 开始故障排除流程..."
echo

# 步骤1: 清理旧的mindmap-qoder相关镜像和容器
echo "1️⃣ 清理旧的mindmap-qoder镜像和容器..."
docker stop $(docker ps -q --filter "ancestor=mindmap-qoder") 2>/dev/null || true
docker rm $(docker ps -a -q --filter "ancestor=mindmap-qoder") 2>/dev/null || true
docker rmi $(docker images mindmap-qoder -q) 2>/dev/null || true
docker rmi $(docker images -f "reference=mindmap-qoder*" -q) 2>/dev/null || true
echo "✅ 完成"

# 步骤2: 清理构建缓存
echo
echo "2️⃣ 清理Docker构建缓存..."
docker builder prune -f >/dev/null 2>&1
echo "✅ 完成"

# 步骤3: 清理未使用的资源
echo
echo "3️⃣ 清理未使用的Docker资源..."
docker image prune -f >/dev/null 2>&1
docker container prune -f >/dev/null 2>&1
docker network prune -f >/dev/null 2>&1
docker volume prune -f >/dev/null 2>&1
echo "✅ 完成"

# 步骤4: 检查必要文件
echo
echo "4️⃣ 检查必要文件..."
MISSING_FILES=()

if [ ! -f "Dockerfile" ]; then
    MISSING_FILES+=("Dockerfile")
fi

if [ ! -f "copy.js" ]; then
    MISSING_FILES+=("copy.js")
fi

if [ ! -f "web/package.json" ]; then
    MISSING_FILES+=("web/package.json")
fi

if [ ! -f "simple-mind-map/package.json" ]; then
    MISSING_FILES+=("simple-mind-map/package.json")
fi

if [ ! -f "server/package.json" ]; then
    MISSING_FILES+=("server/package.json")
fi

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "❌ 缺少必要文件:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    exit 1
else
    echo "✅ 所有必要文件存在"
fi

echo
echo "🎯 故障排除完成！现在尝试构建..."
echo

# 步骤5: 尝试无缓存构建
echo "5️⃣ 执行无缓存构建..."
if docker build --no-cache -t mindmap-qoder:test .; then
    echo
    echo "🎉 构建成功！"
    echo
    echo "📋 后续步骤:"
    echo "1. 测试容器启动: docker run -d -p 8080:80 -p 3001:3000 --name mindmap-test mindmap-qoder:test"
    echo "2. 查看容器日志: docker logs mindmap-test"
    echo "3. 访问应用: http://localhost:8080"
    echo "4. 停止容器: docker stop mindmap-test && docker rm mindmap-test"
else
    echo
    echo "❌ 构建仍然失败"
    echo
    echo "🔍 建议进一步检查:"
    echo "1. 检查网络连接是否正常"
    echo "2. 检查是否有防火墙阻止npm下载"
    echo "3. 尝试在本地单独运行: cd web && npm install && npm run build"
    echo "4. 查看详细错误日志"
    exit 1
fi