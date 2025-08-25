#!/bin/bash

# 无缓存Docker构建脚本
# 完全绕过Docker缓存进行构建

echo "=== 无缓存Docker构建脚本 ==="
echo

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未找到Docker命令"
    exit 1
fi

echo "✅ Docker已就绪"
echo

# 清理旧的mindmap-qoder镜像
echo "🧹 清理旧的mindmap-qoder镜像..."
docker rmi mindmap-qoder:test 2>/dev/null || true
docker rmi $(docker images mindmap-qoder -q) 2>/dev/null || true

echo
echo "🔨 开始无缓存构建..."
echo "注意：这将需要更长时间，因为会重新下载所有依赖"
echo

# 执行无缓存构建
if docker build --no-cache -t mindmap-qoder:test .; then
    echo
    echo "✅ 无缓存构建成功！"
    echo
    echo "可以测试运行容器："
    echo "docker run -d -p 8080:80 -p 3001:3000 --name mindmap-test mindmap-qoder:test"
else
    echo
    echo "❌ 无缓存构建失败"
    exit 1
fi