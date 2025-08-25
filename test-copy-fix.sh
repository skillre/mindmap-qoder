#!/bin/bash

# 简单的Docker构建验证脚本
# 专门用于验证copy.js文件修复

echo "=== 验证copy.js文件修复 ==="
echo

# 检查copy.js文件是否存在
if [ ! -f "copy.js" ]; then
    echo "❌ 错误: copy.js文件不存在于项目根目录"
    exit 1
fi

echo "✅ copy.js文件存在"

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未找到Docker命令"
    exit 1
fi

echo "✅ Docker已就绪"
echo

# 仅测试前端构建阶段
echo "🔨 测试前端构建阶段（包含copy.js执行）..."
if docker build --target frontend-builder -t test-frontend-copy . --no-cache; then
    echo "✅ 前端构建阶段成功（包含copy.js执行）"
else
    echo "❌ 前端构建阶段失败"
    exit 1
fi

echo
echo "🧹 清理测试镜像..."
docker rmi test-frontend-copy 2>/dev/null || true

echo "✨ copy.js修复验证完成！"