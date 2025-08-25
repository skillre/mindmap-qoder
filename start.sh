#!/bin/bash

# mindmap-qoder 快速启动脚本
# 使用新的端口配置避免冲突

echo "=== mindmap-qoder 快速启动脚本 ==="
echo

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: 未找到Docker命令"
    exit 1
fi

echo "✅ Docker已就绪"

# 检查端口占用
echo "🔍 检查端口占用情况..."

check_port() {
    local port=$1
    local service=$2
    if lsof -i :$port >/dev/null 2>&1; then
        echo "⚠️  端口 $port ($service) 已被占用"
        echo "   占用进程: $(lsof -ti :$port | xargs ps -p | tail -n +2)"
        return 1
    else
        echo "✅ 端口 $port ($service) 可用"
        return 0
    fi
}

PORT_CONFLICTS=0

if ! check_port 8080 "前端服务"; then
    PORT_CONFLICTS=$((PORT_CONFLICTS + 1))
fi

if ! check_port 3001 "后端服务"; then
    PORT_CONFLICTS=$((PORT_CONFLICTS + 1))
fi

if [ $PORT_CONFLICTS -gt 0 ]; then
    echo
    echo "❌ 发现 $PORT_CONFLICTS 个端口冲突"
    echo
    echo "🔧 解决方案:"
    echo "1. 停止占用端口的服务"
    echo "2. 修改docker-compose.yml中的端口映射"
    echo "3. 使用其他端口启动 (如: docker run -p 9080:80 -p 3002:3000 ...)"
    echo
    read -p "是否继续启动? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "启动已取消"
        exit 1
    fi
fi

echo

# 停止已存在的容器
echo "🧹 清理已存在的容器..."
docker stop mindmap-qoder-app 2>/dev/null || true
docker rm mindmap-qoder-app 2>/dev/null || true

# 选择启动方式
echo "🚀 选择启动方式:"
echo "1. 使用Docker Compose (推荐)"
echo "2. 使用Docker命令"
echo "3. 使用开发环境"
echo
read -p "请选择 (1/2/3): " -n 1 -r
echo

case $REPLY in
    1)
        echo "📦 使用Docker Compose启动..."
        if docker-compose up -d; then
            echo "✅ 启动成功!"
        else
            echo "❌ 启动失败"
            exit 1
        fi
        ;;
    2)
        echo "🔨 检查镜像是否存在..."
        if ! docker images mindmap-qoder:latest >/dev/null 2>&1; then
            echo "📦 镜像不存在，开始构建..."
            if docker build -t mindmap-qoder:latest .; then
                echo "✅ 镜像构建成功"
            else
                echo "❌ 镜像构建失败"
                exit 1
            fi
        fi
        
        echo "🚀 启动容器..."
        if docker run -d \
            --name mindmap-qoder-app \
            -p 8080:80 \
            -p 3001:3000 \
            mindmap-qoder:latest; then
            echo "✅ 容器启动成功!"
        else
            echo "❌ 容器启动失败"
            exit 1
        fi
        ;;
    3)
        echo "🛠️  使用开发环境启动..."
        if docker-compose -f docker-compose.dev.yml up -d; then
            echo "✅ 开发环境启动成功!"
        else
            echo "❌ 开发环境启动失败"
            exit 1
        fi
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo
echo "🎉 启动完成!"
echo
echo "📋 访问地址:"
echo "   前端应用: http://localhost:8080"
echo "   后端API:  http://localhost:3001"
echo
echo "🔧 管理命令:"
echo "   查看日志: docker logs mindmap-qoder-app"
echo "   停止服务: docker stop mindmap-qoder-app"
echo "   重启服务: docker restart mindmap-qoder-app"
echo
echo "📝 更多信息请查看 PORT_CONFIG.md"