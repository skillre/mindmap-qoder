<template>
  <el-dialog
    title="GitHub 云端文件管理"
    :visible.sync="visible"
    width="800px"
    :close-on-click-modal="false"
    @close="handleClose"
    class="github-files-dialog"
  >
    <div v-if="!isConfigured" class="no-config">
      <el-empty description="尚未配置GitHub">
        <el-button type="primary" @click="openConfig">配置GitHub</el-button>
      </el-empty>
    </div>

    <div v-else>
      <!-- 工具栏 -->
      <div class="toolbar">
        <div class="left">
          <el-button
            type="primary"
            icon="el-icon-plus"
            size="small"
            @click="showCreateDialog"
          >
            新建文件
          </el-button>
          <el-button
            icon="el-icon-refresh"
            size="small"
            @click="refreshFiles"
            :loading="loading"
          >
            刷新
          </el-button>
        </div>
        <div class="right">
          <el-input
            v-model="searchText"
            placeholder="搜索文件..."
            size="small"
            style="width: 200px"
            prefix-icon="el-icon-search"
            clearable
          >
          </el-input>
        </div>
      </div>

      <!-- 文件列表 -->
      <div class="file-list" v-loading="loading">
        <el-table
          :data="filteredFiles"
          empty-text="暂无文件"
          @row-dblclick="openFile"
          style="width: 100%"
        >
          <el-table-column prop="name" label="文件名" min-width="200">
            <template slot-scope="scope">
              <el-link @click="openFile(scope.row)" :underline="false">
                <i class="el-icon-document"></i>
                {{ scope.row.name }}
              </el-link>
            </template>
          </el-table-column>
          <el-table-column prop="size" label="大小" width="80">
            <template slot-scope="scope">
              {{ formatFileSize(scope.row.size) }}
            </template>
          </el-table-column>
          <el-table-column label="操作" width="150">
            <template slot-scope="scope">
              <el-button
                type="text"
                size="small"
                @click="openFile(scope.row)"
              >
                打开
              </el-button>
              <el-button
                type="text"
                size="small"
                @click="downloadFile(scope.row)"
              >
                下载
              </el-button>
              <el-button
                type="text"
                size="small"
                style="color: #f56c6c"
                @click="deleteFile(scope.row)"
              >
                删除
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </div>

    <!-- 新建文件对话框 -->
    <el-dialog
      title="新建文件"
      :visible.sync="createDialogVisible"
      width="400px"
      append-to-body
    >
      <el-form ref="createForm" :model="createForm" :rules="createRules">
        <el-form-item label="文件名" prop="filename">
          <el-input
            v-model="createForm.filename"
            placeholder="请输入文件名"
            @keyup.enter.native="createFile"
          >
            <template slot="append">.json</template>
          </el-input>
        </el-form-item>
        <el-form-item label="文件描述">
          <el-input
            v-model="createForm.description"
            placeholder="可选，描述文件内容"
          ></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="createDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="createFile" :loading="creating">
          创建
        </el-button>
      </div>
    </el-dialog>

    <div slot="footer" class="dialog-footer">
      <el-button @click="handleClose">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import GitHubService from '@/api/github'
import exampleData from 'simple-mind-map/example/exampleData'
import { mapState } from 'vuex'

export default {
  name: 'GitHubFiles',
  props: {
    visible: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      loading: false,
      creating: false,
      files: [],
      searchText: '',
      createDialogVisible: false,
      createForm: {
        filename: '',
        description: ''
      },
      createRules: {
        filename: [
          { required: true, message: '请输入文件名', trigger: 'blur' },
          { 
            pattern: /^[^<>:"/\\|?*]+$/, 
            message: '文件名包含非法字符', 
            trigger: 'blur' 
          }
        ]
      }
    }
  },
  computed: {
    ...mapState(['githubConfig']),
    
    isConfigured() {
      return this.githubConfig && 
             this.githubConfig.token && 
             this.githubConfig.owner && 
             this.githubConfig.repo
    },

    filteredFiles() {
      if (!this.searchText) return this.files
      
      return this.files.filter(file => 
        file.name.toLowerCase().includes(this.searchText.toLowerCase())
      )
    }
  },
  watch: {
    visible(val) {
      if (val && this.isConfigured) {
        this.loadFiles()
      }
    }
  },
  methods: {
    // 加载文件列表
    async loadFiles() {
      if (!this.isConfigured) return

      this.loading = true
      try {
        const { token, owner, repo, branch } = this.githubConfig
        this.files = await GitHubService.getFiles(token, owner, repo, branch)
      } catch (error) {
        this.$message.error('加载文件列表失败')
        this.files = []
      } finally {
        this.loading = false
      }
    },

    // 刷新文件列表
    refreshFiles() {
      this.loadFiles()
    },

    // 打开配置
    openConfig() {
      this.$emit('open-config')
    },

    // 显示创建对话框
    showCreateDialog() {
      this.createDialogVisible = true
      this.createForm = {
        filename: '',
        description: ''
      }
    },

    // 创建新文件
    async createFile() {
      try {
        await this.$refs.createForm.validate()
        
        this.creating = true
        const { token, owner, repo, branch } = this.githubConfig
        
        const filename = this.createForm.filename.endsWith('.json') 
          ? this.createForm.filename 
          : `${this.createForm.filename}.json`
        
        const filePath = GitHubService.generateFilePath(filename)
        
        // 创建基础思维导图数据
        const mindmapData = {
          ...exampleData,
          root: {
            ...exampleData.root,
            data: {
              ...exampleData.root.data,
              text: this.createForm.description || this.createForm.filename
            }
          }
        }

        await GitHubService.saveFile({
          token,
          owner,
          repo,
          path: filePath,
          content: mindmapData,
          message: `创建新文件: ${filename}`,
          branch
        })

        this.$message.success('文件创建成功')
        this.createDialogVisible = false
        this.loadFiles()
      } catch (error) {
        console.error('创建文件失败:', error)
      } finally {
        this.creating = false
      }
    },

    // 打开文件
    async openFile(file) {
      try {
        const { token, owner, repo, branch } = this.githubConfig
        
        this.loading = true
        const result = await GitHubService.getFileContent(
          token, 
          owner, 
          repo, 
          file.path, 
          branch
        )
        
        // 设置当前文件信息到全局状态
        this.$store.commit('setCurrentFile', {
          path: file.path,
          sha: result.sha,
          name: file.name
        })

        // 发送数据到思维导图
        this.$bus.$emit('setData', result.content.data || result.content)
        
        this.$message.success(`已打开文件：${file.name}`)
        this.handleClose()
      } catch (error) {
        this.$message.error('打开文件失败')
      } finally {
        this.loading = false
      }
    },

    // 下载文件
    async downloadFile(file) {
      try {
        const { token, owner, repo, branch } = this.githubConfig
        
        const result = await GitHubService.getFileContent(
          token, 
          owner, 
          repo, 
          file.path, 
          branch
        )
        
        // 创建下载链接
        const blob = new Blob([JSON.stringify(result.content, null, 2)], {
          type: 'application/json'
        })
        const url = URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = file.name
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        URL.revokeObjectURL(url)
        
        this.$message.success('文件下载成功')
      } catch (error) {
        this.$message.error('下载文件失败')
      }
    },

    // 删除文件
    async deleteFile(file) {
      try {
        await this.$confirm(
          `确定要删除文件 "${file.name}" 吗？此操作不可恢复。`,
          '确认删除',
          {
            confirmButtonText: '确定',
            cancelButtonText: '取消',
            type: 'warning'
          }
        )

        const { token, owner, repo, branch } = this.githubConfig
        
        // 先获取文件的SHA
        const fileContent = await GitHubService.getFileContent(
          token, 
          owner, 
          repo, 
          file.path, 
          branch
        )

        await GitHubService.deleteFile({
          token,
          owner,
          repo,
          path: file.path,
          sha: fileContent.sha,
          message: `删除文件: ${file.name}`,
          branch
        })

        this.$message.success('文件删除成功')
        this.loadFiles()
      } catch (error) {
        if (error === 'cancel') return
        this.$message.error('删除文件失败')
      }
    },

    // 格式化文件大小
    formatFileSize(bytes) {
      if (bytes === 0) return '0 B'
      const k = 1024
      const sizes = ['B', 'KB', 'MB', 'GB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    },

    // 关闭对话框
    handleClose() {
      this.$emit('update:visible', false)
    }
  }
}
</script>

<style lang="less" scoped>
.github-files-dialog {
  .no-config {
    text-align: center;
    padding: 60px 0;
  }

  .toolbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    padding: 10px 0;
    border-bottom: 1px solid #ebeef5;

    .left {
      display: flex;
      gap: 10px;
    }
  }

  .file-list {
    min-height: 300px;
    max-height: 400px;
    overflow-y: auto;

    .el-link {
      display: flex;
      align-items: center;
      color: #606266;

      i {
        margin-right: 5px;
        color: #409eff;
      }

      &:hover {
        color: #409eff;
      }
    }
  }

  .dialog-footer {
    text-align: right;
  }
}
</style>