#!/bin/bash

# 前端应用加载诊断脚本
# 诊断页面空白问题

echo "=== 前端应用加载诊断脚本 ==="
echo

# 获取容器名称
CONTAINER_NAME="mindmap-qoder-app"
if ! docker ps | grep -q $CONTAINER_NAME; then
    echo "🔍 查找运行中的mindmap容器..."
    CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep -i mindmap | head -1)
    
    if [ -z "$CONTAINER_NAME" ]; then
        echo "❌ 未找到运行中的mindmap容器"
        echo "请先启动容器: docker-compose up -d"
        exit 1
    fi
fi

echo "✅ 找到容器: $CONTAINER_NAME"
echo

# 1. 检查容器状态
echo "📊 检查容器状态..."
docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo

# 2. 检查nginx进程
echo "🔍 检查nginx进程..."
if docker exec $CONTAINER_NAME pgrep nginx >/dev/null; then
    echo "✅ nginx进程正在运行"
    docker exec $CONTAINER_NAME ps aux | grep nginx | grep -v grep
else
    echo "❌ nginx进程未运行"
fi
echo

# 3. 检查静态文件
echo "📁 检查静态文件..."
echo "检查 /usr/share/nginx/html 目录:"
docker exec $CONTAINER_NAME ls -la /usr/share/nginx/html/

echo
echo "检查index.html是否存在:"
if docker exec $CONTAINER_NAME test -f /usr/share/nginx/html/index.html; then
    echo "✅ index.html 存在"
    echo "文件大小:"
    docker exec $CONTAINER_NAME stat /usr/share/nginx/html/index.html | grep Size
else
    echo "❌ index.html 不存在"
fi
echo

# 4. 检查index.html内容
echo "📄 检查index.html内容..."
if docker exec $CONTAINER_NAME test -f /usr/share/nginx/html/index.html; then
    echo "HTML文件内容预览:"
    docker exec $CONTAINER_NAME head -20 /usr/share/nginx/html/index.html
else
    echo "❌ 无法读取index.html"
fi
echo

# 5. 检查JavaScript文件
echo "📦 检查JavaScript文件..."
echo "JS文件列表:"
docker exec $CONTAINER_NAME find /usr/share/nginx/html -name "*.js" -type f | head -10
echo

# 6. 检查CSS文件
echo "🎨 检查CSS文件..."
echo "CSS文件列表:"
docker exec $CONTAINER_NAME find /usr/share/nginx/html -name "*.css" -type f | head -10
echo

# 7. 检查nginx配置
echo "⚙️  检查nginx配置..."
echo "nginx配置文件:"
docker exec $CONTAINER_NAME cat /etc/nginx/nginx.conf | grep -A 10 -B 5 "location /"
echo

# 8. 检查nginx错误日志
echo "📝 检查nginx错误日志..."
echo "最近的nginx错误日志:"
docker exec $CONTAINER_NAME tail -20 /var/log/nginx/error.log 2>/dev/null || echo "无错误日志或无法访问"
echo

# 9. 检查nginx访问日志
echo "📊 检查nginx访问日志..."
echo "最近的nginx访问日志:"
docker exec $CONTAINER_NAME tail -10 /var/log/nginx/access.log 2>/dev/null || echo "无访问日志或无法访问"
echo

# 10. 测试HTTP响应
echo "🌐 测试HTTP响应..."
echo "测试根路径:"
if docker exec $CONTAINER_NAME wget -qO- http://localhost/ | head -10; then
    echo "✅ 能获取到响应内容"
else
    echo "❌ 无法获取响应内容"
fi
echo

# 11. 检查构建产物
echo "🔨 检查构建产物..."
echo "检查是否有构建产物目录:"
docker exec $CONTAINER_NAME ls -la /app/ | grep dist || echo "未找到dist目录"
echo

# 12. 建议的解决方案
echo "💡 常见问题及解决方案:"
echo
echo "1. 如果index.html不存在或为空："
echo "   - 检查前端构建是否成功"
echo "   - 重新构建镜像: docker build --no-cache -t mindmap-qoder:test ."
echo
echo "2. 如果文件存在但页面空白："
echo "   - 检查浏览器开发者工具控制台错误"
echo "   - 检查JavaScript文件路径是否正确"
echo "   - 检查是否有CORS问题"
echo
echo "3. 如果nginx配置有问题："
echo "   - 检查nginx.conf配置文件"
echo "   - 重启容器: docker restart $CONTAINER_NAME"
echo
echo "📋 下一步建议："
echo "1. 在浏览器中访问 http://localhost:8080"
echo "2. 打开开发者工具(F12)查看控制台错误"
echo "3. 查看网络标签页检查资源加载情况"