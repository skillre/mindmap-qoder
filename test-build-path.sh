#!/bin/bash

# Vue构建路径修复验证脚本
# 专门验证构建输出路径配置是否正确

echo "=== Vue构建路径修复验证脚本 ==="
echo

# 检查Vue配置文件
if [ ! -f "web/vue.config.js" ]; then
    echo "❌ 错误: vue.config.js文件不存在"
    exit 1
fi

echo "✅ vue.config.js文件存在"

# 检查outputDir配置
OUTPUT_DIR=$(grep -n "outputDir" web/vue.config.js | head -1)
if [ -n "$OUTPUT_DIR" ]; then
    echo "📋 发现outputDir配置: $OUTPUT_DIR"
    
    if echo "$OUTPUT_DIR" | grep -q "../dist"; then
        echo "✅ outputDir配置正确: '../dist' (输出到项目根目录的dist文件夹)"
        EXPECTED_PATH="/app/dist"
    elif echo "$OUTPUT_DIR" | grep -q "dist"; then
        echo "⚠️  outputDir配置: 相对于web目录的dist"
        EXPECTED_PATH="/app/web/dist"
    else
        echo "❓ outputDir配置未知格式"
        EXPECTED_PATH="/app/dist"
    fi
else
    echo "❓ 未找到outputDir配置，使用默认值"
    EXPECTED_PATH="/app/web/dist"
fi

echo

# 检查Dockerfile中的路径配置
echo "🔍 检查Dockerfile中的路径配置..."
DOCKERFILE_PATH=$(grep -n "COPY --from=frontend-builder" Dockerfile | grep "nginx/html")

if [ -n "$DOCKERFILE_PATH" ]; then
    echo "📋 发现Dockerfile路径配置: $DOCKERFILE_PATH"
    
    if echo "$DOCKERFILE_PATH" | grep -q "/app/dist"; then
        ACTUAL_PATH="/app/dist"
        echo "✅ Dockerfile使用路径: /app/dist"
    elif echo "$DOCKERFILE_PATH" | grep -q "/app/web/dist"; then
        ACTUAL_PATH="/app/web/dist"
        echo "⚠️  Dockerfile使用路径: /app/web/dist"
    else
        echo "❓ Dockerfile路径配置未知"
        ACTUAL_PATH="unknown"
    fi
else
    echo "❌ 未找到Dockerfile中的路径配置"
    exit 1
fi

echo

# 验证路径一致性
echo "🎯 验证路径一致性..."
if [ "$EXPECTED_PATH" = "$ACTUAL_PATH" ]; then
    echo "✅ 路径配置一致！"
    echo "   Vue outputDir: ../dist → $EXPECTED_PATH"
    echo "   Dockerfile: $ACTUAL_PATH"
else
    echo "❌ 路径配置不一致！"
    echo "   预期路径（基于Vue配置）: $EXPECTED_PATH"
    echo "   实际路径（Dockerfile中）: $ACTUAL_PATH"
    echo
    echo "🔧 建议修复："
    if [ "$EXPECTED_PATH" = "/app/dist" ]; then
        echo "   Dockerfile应该使用: COPY --from=frontend-builder /app/dist /usr/share/nginx/html"
    else
        echo "   Dockerfile应该使用: COPY --from=frontend-builder /app/web/dist /usr/share/nginx/html"
    fi
    exit 1
fi

echo
echo "✨ 路径配置验证通过！可以继续构建测试。"