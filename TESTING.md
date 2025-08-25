# GitHub存储集成功能测试清单

## 📋 功能验证清单

### ✅ 已验证的文件结构
- [x] 后端服务器架构 (`server/`)
- [x] GitHub API集成 (`server/routes/github.js`)
- [x] 前端API服务 (`web/src/api/github.js`)
- [x] GitHub配置组件 (`web/src/components/GitHubConfig.vue`)
- [x] 文件管理组件 (`web/src/components/GitHubFiles.vue`)
- [x] 自动保存指示器 (`web/src/components/AutoSaveIndicator.vue`)
- [x] Vuex状态管理扩展 (`web/src/store.js`)
- [x] 工具栏改造 (`web/src/pages/Edit/components/Toolbar.vue`)

### ✅ 已验证的配置文件
- [x] Docker多阶段构建 (`Dockerfile`, `Dockerfile.prod`, `Dockerfile.dev`)
- [x] Docker Compose配置 (开发/生产环境)
- [x] Nginx优化配置 (HTTP/HTTPS/开发环境)
- [x] 环境变量配置 (`.env.production`, `.env.development`)

### 🧪 需要手动测试的功能

#### 1. GitHub配置功能
- [ ] 打开GitHub配置对话框
- [ ] 输入有效的GitHub Token
- [ ] Token验证功能
- [ ] 仓库列表加载
- [ ] 分支列表加载
- [ ] 配置保存功能

#### 2. 文件管理功能
- [ ] 云端文件列表显示
- [ ] 新建文件功能
- [ ] 打开文件功能
- [ ] 删除文件功能
- [ ] 文件下载功能
- [ ] 文件搜索功能

#### 3. 自动保存功能
- [ ] 编辑思维导图时触发自动保存
- [ ] 自动保存状态指示器显示
- [ ] 手动保存功能
- [ ] 保存间隔设置
- [ ] 自动保存开关

#### 4. 界面集成测试
- [ ] 工具栏GitHub按钮显示
- [ ] 本地文件操作按钮已移除
- [ ] 暗黑模式适配
- [ ] 响应式布局

#### 5. Docker部署测试
- [ ] 开发环境启动 (`docker-compose.dev.yml`)
- [ ] 生产环境启动 (`docker-compose.prod.yml`)
- [ ] 前后端通信正常
- [ ] 健康检查正常
- [ ] 日志输出正常

## 🔧 测试步骤

### 本地开发测试
```bash
# 1. 安装依赖
cd server && npm install
cd ../web && npm install

# 2. 启动后端服务
cd server && npm start

# 3. 启动前端服务
cd web && npm run serve

# 4. 访问 http://localhost:8080
```

### Docker测试
```bash
# 开发环境
docker-compose -f docker-compose.dev.yml up

# 生产环境
docker-compose -f docker-compose.prod.yml up -d

# 检查容器状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### GitHub集成测试
1. 创建GitHub Personal Access Token
   - 访问 https://github.com/settings/tokens
   - 生成新token，授予 `repo` 权限
   - 复制token

2. 配置GitHub存储
   - 打开应用，点击"配置"按钮
   - 输入GitHub Token
   - 选择私有仓库
   - 选择分支
   - 启用自动保存

3. 测试文件操作
   - 创建新思维导图
   - 编辑内容，观察自动保存
   - 通过"云端文件"管理文件
   - 验证文件在GitHub仓库中

## 🐛 已知问题和注意事项

### 安全考虑
- GitHub Token需要妥善保管
- 仅支持私有仓库存储
- API请求有频率限制

### 性能考虑
- 大文件上传可能较慢
- 自动保存间隔建议30-60秒
- 网络不稳定时需要重试机制

### 浏览器兼容性
- 需要支持ES6+的现代浏览器
- WebSocket支持（用于开发环境热重载）

## 📝 测试报告模板

### 基础功能测试
- [ ] ✅ 通过 / ❌ 失败 - 功能描述
- 问题描述：
- 错误日志：
- 修复建议：

### 性能测试
- [ ] 响应时间 < 2秒
- [ ] 内存使用 < 512MB
- [ ] CPU使用 < 50%

### 安全测试
- [ ] API认证正常
- [ ] 输入验证正常
- [ ] CORS配置正确

## 🚀 部署验证

### 生产环境检查清单
- [ ] HTTPS配置
- [ ] 环境变量设置
- [ ] 日志配置
- [ ] 备份策略
- [ ] 监控告警
- [ ] 性能优化