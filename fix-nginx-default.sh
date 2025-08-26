#!/bin/bash

# 修复nginx显示默认页面问题

echo "=== 修复nginx默认页面问题 ==="
echo

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未找到Docker命令"
    echo "请确保Docker已安装并运行"
    exit 1
fi

echo "✅ Docker已就绪"

# 查找运行中的容器
echo "🔍 查找运行中的mindmap容器..."
CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep -i mindmap | head -1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ 未找到运行中的mindmap容器"
    echo "请先启动容器"
    exit 1
fi

echo "✅ 找到容器: $CONTAINER_NAME"

# 检查容器中的文件
echo
echo "📁 检查容器中的nginx目录..."
echo "检查 /usr/share/nginx/html 目录内容:"
docker exec $CONTAINER_NAME ls -la /usr/share/nginx/html/

echo
echo "🔍 分析问题..."

# 检查是否有index.html文件
if docker exec $CONTAINER_NAME test -f /usr/share/nginx/html/index.html; then
    echo "✅ index.html 文件存在"
    
    # 检查文件大小
    SIZE=$(docker exec $CONTAINER_NAME stat -c%s /usr/share/nginx/html/index.html)
    echo "📊 index.html 文件大小: $SIZE bytes"
    
    if [ "$SIZE" -lt 1000 ]; then
        echo "⚠️  文件太小，可能是空文件或nginx默认文件"
        echo "文件内容预览:"
        docker exec $CONTAINER_NAME head -10 /usr/share/nginx/html/index.html
    else
        echo "✅ 文件大小正常"
        echo "检查文件内容..."
        if docker exec $CONTAINER_NAME grep -q "思绪思维导图\|app" /usr/share/nginx/html/index.html; then
            echo "✅ 文件内容正确"
            echo "问题可能在其他地方..."
        else
            echo "❌ 文件内容不正确，显示为nginx默认页面"
        fi
    fi
else
    echo "❌ index.html 文件不存在"
fi

echo
echo "📦 检查构建目录..."
# 检查构建源目录
docker exec $CONTAINER_NAME ls -la /app/ | grep dist || echo "❌ 未找到dist目录"

echo
echo "🔧 修复建议："
echo

if ! docker exec $CONTAINER_NAME test -f /usr/share/nginx/html/index.html; then
    echo "1. index.html文件缺失 - 需要重新构建镜像"
    echo "   原因: 前端构建失败或文件复制失败"
    echo "   解决: ./fix-blank-page.sh"
elif docker exec $CONTAINER_NAME grep -q "Welcome to nginx" /usr/share/nginx/html/index.html; then
    echo "1. 显示nginx默认页面 - 构建文件没有正确复制"
    echo "   原因: Dockerfile中的COPY命令可能失败"
    echo "   解决: 重新构建镜像"
else
    echo "1. 文件存在但有其他问题"
    echo "   需要进一步检查nginx配置和文件权限"
fi

echo
echo "🚀 推荐的修复步骤:"
echo "1. 停止当前容器: docker stop $CONTAINER_NAME"
echo "2. 删除容器: docker rm $CONTAINER_NAME" 
echo "3. 清理镜像: docker rmi mindmap-qoder:test"
echo "4. 重新构建: ./fix-blank-page.sh"
echo "   或者手动执行:"
echo "   docker build --no-cache -t mindmap-qoder:test ."
echo "   docker run -d --name mindmap-qoder-app -p 8080:80 -p 3001:3000 mindmap-qoder:test"
echo
echo "5. 如果问题持续，检查构建日志中的错误"

# 自动修复选项
echo
read -p "是否自动执行修复? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 开始自动修复..."
    
    # 停止容器
    echo "🛑 停止容器..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
    
    # 清理镜像
    echo "🧹 清理镜像..."
    docker rmi mindmap-qoder:test 2>/dev/null || true
    
    # 重新构建
    echo "🔨 重新构建镜像..."
    if docker build --no-cache -t mindmap-qoder:test .; then
        echo "✅ 构建成功"
        
        # 启动容器
        echo "🚀 启动容器..."
        if docker run -d --name mindmap-qoder-app -p 8080:80 -p 3001:3000 mindmap-qoder:test; then
            echo "✅ 容器启动成功"
            echo
            echo "⏳ 等待服务启动..."
            sleep 10
            
            echo "🌐 测试访问..."
            if curl -f -s http://localhost:8080/ | grep -q "思绪思维导图\|app"; then
                echo "🎉 修复成功! 请访问 http://localhost:8080"
            else
                echo "⚠️  仍有问题，请手动检查"
            fi
        else
            echo "❌ 容器启动失败"
        fi
    else
        echo "❌ 构建失败，请检查错误日志"
    fi
else
    echo "取消自动修复"
fi