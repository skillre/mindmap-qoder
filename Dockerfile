# 多阶段构建优化的Dockerfile

# 阶段1: 构建前端应用
FROM node:16-alpine AS frontend-builder

# 设置工作目录
WORKDIR /app

# 复制前端package文件
COPY web/package*.json ./web/
COPY simple-mind-map/package*.json ./simple-mind-map/

# 智能依赖安装 - 构建阶段需要包含开发依赖
WORKDIR /app/web
RUN test -f package-lock.json && npm ci || npm install

WORKDIR /app/simple-mind-map
RUN test -f package-lock.json && npm ci || npm install

WORKDIR /app

# 复制源代码
COPY web/ ./web/
COPY simple-mind-map/ ./simple-mind-map/
COPY copy.js ./copy.js

# 构建前端应用
RUN cd web && npm run build

# 阶段2: 构建后端应用
FROM node:16-alpine AS backend-builder

# 设置工作目录
WORKDIR /app

# 复制后端package文件
COPY server/package*.json ./

# 智能依赖安装 - 后端只需要生产依赖
RUN test -f package-lock.json && npm ci --omit=dev || npm install --omit=dev

# 复制后端源代码
COPY server/ ./

# 阶段3: 生产运行环境
FROM nginx:alpine AS production

# 安装Node.js运行时
RUN apk add --no-cache nodejs npm

# 创建应用目录
RUN mkdir -p /app/backend

# 从构建阶段复制文件
COPY --from=frontend-builder /app/web/dist /usr/share/nginx/html
COPY --from=backend-builder /app /app/backend

# 复制nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 创建启动脚本
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'cd /app/backend && node index.js &' >> /start.sh && \
    echo 'nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

# 暴露端口
EXPOSE 80 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

# 启动服务
CMD ["/start.sh"]