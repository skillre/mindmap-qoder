#!/bin/bash

# 前端页面空白问题修复重建脚本

echo "=== 前端页面空白问题修复 ==="
echo

echo "🔧 修复内容:"
echo "- 已修复vue.config.js中的publicPath配置"
echo "- 将生产环境的publicPath从'./dist'改为'./'"
echo "- 这样资源文件将从根目录加载，而不是dist子目录"
echo

# 停止现有容器
echo "🛑 停止现有容器..."
docker stop mindmap-qoder-app 2>/dev/null || true
docker rm mindmap-qoder-app 2>/dev/null || true

# 清理镜像
echo "🧹 清理旧镜像..."
docker rmi mindmap-qoder:test 2>/dev/null || true

# 重新构建
echo "🔨 重新构建镜像..."
if docker build --no-cache -t mindmap-qoder:test .; then
    echo "✅ 镜像构建成功"
else
    echo "❌ 镜像构建失败"
    exit 1
fi

# 启动容器
echo "🚀 启动新容器..."
if docker run -d --name mindmap-qoder-app -p 8080:80 -p 3001:3000 mindmap-qoder:test; then
    echo "✅ 容器启动成功"
else
    echo "❌ 容器启动失败"
    exit 1
fi

echo
echo "⏳ 等待服务启动 (15秒)..."
sleep 15

echo
echo "🔍 测试访问..."
if curl -f -s http://localhost:8080/ | grep -q "思绪思维导图"; then
    echo "✅ 前端页面加载成功！"
else
    echo "⚠️  页面可能仍有问题，请检查浏览器控制台"
fi

echo
echo "📋 访问地址:"
echo "   前端应用: http://localhost:8080"
echo "   后端API:  http://localhost:3001"
echo
echo "🔧 如果仍有问题，运行诊断脚本:"
echo "   ./diagnose-frontend.sh"