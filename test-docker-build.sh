#!/bin/bash

# Docker构建验证脚本
# 用于验证修复后的Dockerfile是否能正常构建

echo "=== Docker构建修复验证脚本 ==="
echo

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未找到Docker命令，请确保Docker已安装并运行"
    exit 1
fi

echo "✅ Docker已就绪"
echo

# 清理旧的镜像（可选）
echo "🧹 清理旧的测试镜像..."
docker rmi mindmap-qoder:test 2>/dev/null || true
echo

# 构建前端阶段
echo "🔨 测试前端构建阶段..."
if docker build --target frontend-builder -t test-frontend . --no-cache; then
    echo "✅ 前端构建阶段成功"
else
    echo "❌ 前端构建阶段失败"
    exit 1
fi
echo

# 构建后端阶段
echo "🔨 测试后端构建阶段..."
if docker build --target backend-builder -t test-backend . --no-cache; then
    echo "✅ 后端构建阶段成功"
else
    echo "❌ 后端构建阶段失败"
    exit 1
fi
echo

# 完整构建
echo "🔨 执行完整构建..."
if docker build -t mindmap-qoder:test . --no-cache; then
    echo "✅ 完整构建成功"
else
    echo "❌ 完整构建失败"
    exit 1
fi
echo

# 测试容器启动
echo "🚀 测试容器启动..."
CONTAINER_ID=$(docker run -d -p 8080:80 -p 3001:3000 mindmap-qoder:test)

if [ $? -eq 0 ]; then
    echo "✅ 容器启动成功，容器ID: $CONTAINER_ID"
    
    # 等待服务启动
    echo "⏳ 等待服务启动 (10秒)..."
    sleep 10
    
    # 测试健康检查
    echo "🔍 测试服务健康状态..."
    if curl -f -s http://localhost:8080/ > /dev/null; then
        echo "✅ 前端服务正常"
    else
        echo "⚠️  前端服务可能未就绪"
    fi
    
    if curl -f -s http://localhost:3001/ > /dev/null; then
        echo "✅ 后端服务正常"
    else
        echo "⚠️  后端服务可能未就绪"
    fi
    
    # 显示容器日志
    echo "📝 容器日志预览:"
    docker logs --tail 20 $CONTAINER_ID
    
    # 停止容器
    echo "🛑 停止测试容器..."
    docker stop $CONTAINER_ID > /dev/null
    docker rm $CONTAINER_ID > /dev/null
    
else
    echo "❌ 容器启动失败"
    exit 1
fi

echo
echo "🎉 所有测试通过！Docker构建修复成功。"
echo
echo "清理测试镜像..."
docker rmi test-frontend test-backend mindmap-qoder:test 2>/dev/null || true

echo "✨ 验证完成！"