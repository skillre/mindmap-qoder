#!/bin/bash

# GitHub存储集成功能验证脚本

echo "🚀 开始验证 mindmap-qoder GitHub 存储集成功能..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} 文件存在: $1"
        return 0
    else
        echo -e "${RED}✗${NC} 文件缺失: $1"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} 目录存在: $1"
        return 0
    else
        echo -e "${RED}✗${NC} 目录缺失: $1"
        return 1
    fi
}

# 1. 检查后端文件结构
echo -e "\n${YELLOW}1. 检查后端文件结构${NC}"
check_dir "server"
check_file "server/package.json"
check_file "server/index.js"
check_dir "server/routes"
check_file "server/routes/github.js"

# 2. 检查前端文件结构
echo -e "\n${YELLOW}2. 检查前端文件结构${NC}"
check_file "web/src/api/github.js"
check_file "web/src/components/GitHubConfig.vue"
check_file "web/src/components/GitHubFiles.vue"
check_file "web/src/components/AutoSaveIndicator.vue"

# 3. 检查修改的核心文件
echo -e "\n${YELLOW}3. 检查修改的核心文件${NC}"
check_file "web/src/store.js"
check_file "web/src/main.js"
check_file "web/src/api/index.js"
check_file "web/src/pages/Edit/components/Toolbar.vue"
check_file "web/src/pages/Edit/Index.vue"

# 4. 检查Docker相关文件
echo -e "\n${YELLOW}4. 检查Docker配置文件${NC}"
check_file "Dockerfile"
check_file "Dockerfile.prod"
check_file "Dockerfile.dev"
check_file "docker-compose.yml"
check_file "docker-compose.prod.yml"
check_file "docker-compose.dev.yml"

# 5. 检查Nginx配置
echo -e "\n${YELLOW}5. 检查Nginx配置文件${NC}"
check_file "nginx.conf"
check_file "nginx.dev.conf"
check_file "nginx.https.conf"

# 6. 检查环境配置
echo -e "\n${YELLOW}6. 检查环境配置文件${NC}"
check_file ".env.production"
check_file ".env.development"

# 7. 检查package.json依赖
echo -e "\n${YELLOW}7. 检查依赖配置${NC}"
if [ -f "server/package.json" ]; then
    if grep -q "express" "server/package.json"; then
        echo -e "${GREEN}✓${NC} 后端Express依赖已配置"
    else
        echo -e "${RED}✗${NC} 后端Express依赖缺失"
    fi
    
    if grep -q "axios" "server/package.json"; then
        echo -e "${GREEN}✓${NC} 后端axios依赖已配置"
    else
        echo -e "${RED}✗${NC} 后端axios依赖缺失"
    fi
fi

# 8. 语法检查（如果有Node.js）
echo -e "\n${YELLOW}8. 语法检查${NC}"
if command -v node &> /dev/null; then
    echo "检查JavaScript语法..."
    
    # 检查后端文件
    if node -c server/index.js 2>/dev/null; then
        echo -e "${GREEN}✓${NC} server/index.js 语法正确"
    else
        echo -e "${RED}✗${NC} server/index.js 语法错误"
    fi
    
    if node -c server/routes/github.js 2>/dev/null; then
        echo -e "${GREEN}✓${NC} server/routes/github.js 语法正确"
    else
        echo -e "${RED}✗${NC} server/routes/github.js 语法错误"
    fi
else
    echo -e "${YELLOW}⚠${NC} 未找到Node.js，跳过语法检查"
fi

# 9. Docker配置验证
echo -e "\n${YELLOW}9. Docker配置验证${NC}"
if command -v docker &> /dev/null; then
    echo "验证Dockerfile语法..."
    if docker build -f Dockerfile . --dry-run &>/dev/null; then
        echo -e "${GREEN}✓${NC} Dockerfile 语法正确"
    else
        echo -e "${YELLOW}⚠${NC} Dockerfile 需要完整构建环境验证"
    fi
else
    echo -e "${YELLOW}⚠${NC} 未找到Docker，跳过Docker验证"
fi

echo -e "\n${GREEN}🎉 验证完成！${NC}"
echo "请确保按照README.md中的部署说明进行完整测试。"

# 输出快速启动命令
echo -e "\n${YELLOW}📋 快速启动命令:${NC}"
echo "开发环境: docker-compose -f docker-compose.dev.yml up"
echo "生产环境: docker-compose -f docker-compose.prod.yml up -d"
echo "单容器: docker-compose up"