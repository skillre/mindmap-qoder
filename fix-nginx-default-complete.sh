#!/bin/bash

# Docker构建和nginx默认页面修复脚本
# 此脚本用于修复mindmap-qoder项目的nginx显示默认页面问题

set -e  # 遇到错误立即退出

echo "🔧 mindmap-qoder Docker构建和nginx修复脚本"
echo "================================================"

# 检查Docker是否可用
check_docker() {
    echo "📋 检查Docker状态..."
    
    # 尝试多种方式查找Docker
    DOCKER_CMD=""
    
    if command -v docker >/dev/null 2>&1; then
        DOCKER_CMD="docker"
    elif [ -f "/Applications/Docker.app/Contents/Resources/bin/docker" ]; then
        DOCKER_CMD="/Applications/Docker.app/Contents/Resources/bin/docker"
    else
        echo "❌ 错误: 未找到Docker命令"
        echo "请确保Docker Desktop已安装并正在运行"
        echo "如果已安装，请尝试启动Docker Desktop应用"
        exit 1
    fi
    
    # 测试Docker是否正常工作
    if ! $DOCKER_CMD ps >/dev/null 2>&1; then
        echo "❌ 错误: Docker未运行或无法访问"
        echo "请启动Docker Desktop并等待其完全启动"
        exit 1
    fi
    
    echo "✅ Docker检查通过，使用命令: $DOCKER_CMD"
    return 0
}

# 清理旧容器和镜像
cleanup_old() {
    echo "🧹 清理旧的容器和镜像..."
    
    # 停止运行中的容器
    if $DOCKER_CMD ps -q --filter "name=mindmap" | grep -q .; then
        echo "停止现有mindmap容器..."
        $DOCKER_CMD stop $($DOCKER_CMD ps -q --filter "name=mindmap")
    fi
    
    # 删除旧容器
    if $DOCKER_CMD ps -a -q --filter "name=mindmap" | grep -q .; then
        echo "删除旧的mindmap容器..."
        $DOCKER_CMD rm $($DOCKER_CMD ps -a -q --filter "name=mindmap")
    fi
    
    # 删除旧镜像
    if $DOCKER_CMD images -q mindmap-qoder | grep -q .; then
        echo "删除旧的mindmap-qoder镜像..."
        $DOCKER_CMD rmi mindmap-qoder 2>/dev/null || true
    fi
    
    echo "✅ 清理完成"
}

# 构建新镜像
build_image() {
    echo "🔨 构建新的Docker镜像..."
    echo "这可能需要几分钟时间，请耐心等待..."
    
    # 构建镜像并显示详细输出
    if $DOCKER_CMD build -t mindmap-qoder . --no-cache; then
        echo "✅ 镜像构建成功"
    else
        echo "❌ 镜像构建失败"
        echo "请检查Dockerfile和源代码是否正确"
        exit 1
    fi
}

# 启动容器
start_container() {
    echo "🚀 启动新容器..."
    
    # 检查8080端口是否占用
    if lsof -i :8080 >/dev/null 2>&1; then
        echo "⚠️  警告: 端口8080已被占用"
        echo "请停止占用8080端口的进程，或者修改docker-compose.yml中的端口映射"
        echo "正在尝试使用端口8090..."
        PORT=8090
    else
        PORT=8080
    fi
    
    # 启动容器
    if $DOCKER_CMD run -d -p $PORT:80 --name mindmap-qoder-test mindmap-qoder; then
        echo "✅ 容器启动成功，端口: $PORT"
        echo "🌐 请访问: http://localhost:$PORT"
    else
        echo "❌ 容器启动失败"
        exit 1
    fi
    
    # 等待容器启动
    echo "⏳ 等待容器完全启动..."
    sleep 5
}

# 测试应用
test_application() {
    echo "🧪 测试应用状态..."
    
    # 检查容器是否在运行
    if ! $DOCKER_CMD ps --filter "name=mindmap-qoder-test" --format "table {{.Names}}\t{{.Status}}" | grep -q "Up"; then
        echo "❌ 容器未正常运行"
        echo "容器日志:"
        $DOCKER_CMD logs mindmap-qoder-test
        exit 1
    fi
    
    # 检查nginx目录内容
    echo "📁 检查nginx目录内容:"
    $DOCKER_CMD exec mindmap-qoder-test ls -la /usr/share/nginx/html/
    
    # 检查index.html内容
    echo "📄 检查index.html文件:"
    if $DOCKER_CMD exec mindmap-qoder-test test -f /usr/share/nginx/html/index.html; then
        echo "✅ index.html文件存在"
        echo "文件大小:"
        $DOCKER_CMD exec mindmap-qoder-test stat /usr/share/nginx/html/index.html
        
        # 检查文件内容
        echo "📖 文件内容摘要:"
        $DOCKER_CMD exec mindmap-qoder-test head -3 /usr/share/nginx/html/index.html
    else
        echo "❌ index.html文件不存在"
        exit 1
    fi
    
    # 测试HTTP响应
    echo "🌐 测试HTTP响应..."
    sleep 2
    
    if command -v curl >/dev/null 2>&1; then
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ || echo "000")
        if [ "$HTTP_STATUS" = "200" ]; then
            echo "✅ HTTP响应正常 (状态码: $HTTP_STATUS)"
            
            # 检查响应内容
            RESPONSE_CONTENT=$(curl -s http://localhost:$PORT/ | head -1)
            if echo "$RESPONSE_CONTENT" | grep -q "<!DOCTYPE html>"; then
                echo "✅ 返回正确的HTML内容"
                echo "🎉 修复成功！应用应该正常显示思维导图界面"
            else
                echo "⚠️  警告: 返回的不是预期的HTML内容"
                echo "响应内容开头: $RESPONSE_CONTENT"
            fi
        else
            echo "⚠️  HTTP状态码: $HTTP_STATUS"
        fi
    else
        echo "ℹ️  curl未安装，跳过HTTP测试"
    fi
}

# 显示最终信息
show_final_info() {
    echo ""
    echo "🎯 修复完成!"
    echo "================================================"
    echo "🌐 应用访问地址: http://localhost:$PORT"
    echo "📊 容器状态: "
    $DOCKER_CMD ps --filter "name=mindmap-qoder-test" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo "📝 常用命令:"
    echo "  查看容器日志: docker logs mindmap-qoder-test"
    echo "  停止容器:     docker stop mindmap-qoder-test"
    echo "  删除容器:     docker rm mindmap-qoder-test"
    echo "  进入容器:     docker exec -it mindmap-qoder-test sh"
    echo ""
    
    if [ "$PORT" != "8080" ]; then
        echo "⚠️  注意: 由于端口冲突，应用运行在端口$PORT而不是8080"
    fi
}

# 主执行流程
main() {
    echo "开始执行修复流程..."
    
    check_docker
    cleanup_old
    build_image
    start_container
    test_application
    show_final_info
    
    echo "✅ 所有步骤完成!"
}

# 错误处理
trap 'echo "❌ 脚本执行过程中出现错误"; exit 1' ERR

# 执行主函数
main "$@"