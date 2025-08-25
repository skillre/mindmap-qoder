#!/bin/bash

# Docker缓存清理脚本
# 解决 "failed to compute cache key" 错误

echo "=== Docker缓存清理脚本 ==="
echo

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未找到Docker命令"
    exit 1
fi

echo "✅ Docker已就绪"
echo

# 停止所有运行中的容器
echo "🛑 停止所有运行中的容器..."
docker stop $(docker ps -q) 2>/dev/null || echo "没有运行中的容器"

# 清理构建缓存
echo "🧹 清理Docker构建缓存..."
docker builder prune -f

# 清理未使用的镜像
echo "🧹 清理未使用的镜像..."
docker image prune -f

# 清理未使用的容器
echo "🧹 清理未使用的容器..."
docker container prune -f

# 清理未使用的网络
echo "🧹 清理未使用的网络..."
docker network prune -f

# 清理未使用的卷
echo "🧹 清理未使用的卷..."
docker volume prune -f

echo
echo "✨ Docker缓存清理完成！"
echo
echo "现在可以重新运行构建命令："
echo "docker build -t mindmap-qoder:test ."