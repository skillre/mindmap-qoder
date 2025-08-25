<template>
  <el-dialog
    title="GitHub 配置"
    :visible.sync="visible"
    width="600px"
    :close-on-click-modal="false"
    @close="handleClose"
    class="github-config-dialog"
  >
    <el-form
      ref="configForm"
      :model="form"
      :rules="rules"
      label-width="120px"
      v-loading="loading"
    >
      <!-- GitHub Token -->
      <el-form-item label="GitHub Token" prop="token">
        <el-input
          v-model="form.token"
          type="password"
          placeholder="请输入GitHub Personal Access Token"
          show-password
          @blur="validateToken"
        >
          <template slot="append">
            <el-button
              @click="validateToken"
              :loading="validatingToken"
              type="primary"
              size="mini"
            >
              验证
            </el-button>
          </template>
        </el-input>
        <div class="form-tip">
          <el-link
            href="https://github.com/settings/tokens"
            target="_blank"
            type="primary"
            :underline="false"
          >
            如何创建GitHub Token？
          </el-link>
        </div>
      </el-form-item>

      <!-- 用户信息显示 -->
      <el-form-item label="用户信息" v-if="userInfo">
        <div class="user-info">
          <el-avatar :src="userInfo.avatar" size="small"></el-avatar>
          <span class="username">{{ userInfo.name }}</span>
          <el-tag size="mini" type="success">已验证</el-tag>
        </div>
      </el-form-item>

      <!-- 仓库选择 -->
      <el-form-item label="选择仓库" prop="repo" v-if="tokenValid">
        <el-select
          v-model="form.repo"
          placeholder="请选择私有仓库"
          filterable
          remote
          :remote-method="searchRepositories"
          :loading="loadingRepos"
          @change="onRepoChange"
          style="width: 100%"
        >
          <el-option
            v-for="repo in repositories"
            :key="repo.fullName"
            :label="repo.fullName"
            :value="repo.fullName"
          >
            <span style="float: left">{{ repo.name }}</span>
            <span style="float: right; color: #8492a6; font-size: 13px">
              {{ repo.private ? '私有' : '公开' }}
            </span>
          </el-option>
        </el-select>
      </el-form-item>

      <!-- 分支选择 -->
      <el-form-item label="选择分支" prop="branch" v-if="form.repo">
        <el-select
          v-model="form.branch"
          placeholder="请选择分支"
          :loading="loadingBranches"
          style="width: 100%"
        >
          <el-option
            v-for="branch in branches"
            :key="branch.name"
            :label="branch.name"
            :value="branch.name"
          >
          </el-option>
        </el-select>
      </el-form-item>

      <!-- 自动保存设置 -->
      <el-form-item label="自动保存">
        <el-switch
          v-model="form.enableAutoSave"
          active-text="启用"
          inactive-text="禁用"
        >
        </el-switch>
      </el-form-item>

      <el-form-item label="保存间隔" v-if="form.enableAutoSave">
        <el-input-number
          v-model="form.autoSaveInterval"
          :min="10"
          :max="300"
          :step="10"
          size="small"
        ></el-input-number>
        <span class="form-tip">秒（建议30-60秒）</span>
      </el-form-item>
    </el-form>

    <div slot="footer" class="dialog-footer">
      <el-button @click="handleClose">取消</el-button>
      <el-button @click="resetForm">重置</el-button>
      <el-button
        type="primary"
        @click="saveConfig"
        :loading="saving"
        :disabled="!isConfigValid"
      >
        保存配置
      </el-button>
    </div>
  </el-dialog>
</template>

<script>
import GitHubService from '@/api/github'
import { mapState, mapMutations } from 'vuex'

export default {
  name: 'GitHubConfig',
  props: {
    visible: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      loading: false,
      validatingToken: false,
      loadingRepos: false,
      loadingBranches: false,
      saving: false,
      tokenValid: false,
      userInfo: null,
      repositories: [],
      branches: [],
      form: {
        token: '',
        repo: '',
        branch: 'main',
        enableAutoSave: true,
        autoSaveInterval: 30
      },
      rules: {
        token: [
          { required: true, message: '请输入GitHub Token', trigger: 'blur' },
          { min: 20, message: 'Token长度不能少于20位', trigger: 'blur' }
        ],
        repo: [
          { required: true, message: '请选择仓库', trigger: 'change' }
        ],
        branch: [
          { required: true, message: '请选择分支', trigger: 'change' }
        ]
      }
    }
  },
  computed: {
    ...mapState(['githubConfig']),
    isConfigValid() {
      return this.tokenValid && this.form.repo && this.form.branch
    }
  },
  watch: {
    visible(val) {
      if (val) {
        this.initForm()
      }
    }
  },
  methods: {
    ...mapMutations(['setGitHubConfig']),

    // 初始化表单
    initForm() {
      if (this.githubConfig) {
        this.form = { ...this.githubConfig }
        if (this.form.token) {
          this.validateToken()
        }
      }
    },

    // 验证Token
    async validateToken() {
      if (!this.form.token) return

      this.validatingToken = true
      try {
        this.userInfo = await GitHubService.validateToken(this.form.token)
        this.tokenValid = true
        this.$message.success('Token验证成功')
        await this.loadRepositories()
      } catch (error) {
        this.tokenValid = false
        this.userInfo = null
        this.$message.error('Token验证失败')
      } finally {
        this.validatingToken = false
      }
    },

    // 加载仓库列表
    async loadRepositories() {
      if (!this.tokenValid) return

      this.loadingRepos = true
      try {
        this.repositories = await GitHubService.getRepositories(this.form.token, 'private')
        
        // 如果配置中有仓库且在列表中，保持选中状态
        if (this.form.repo && this.repositories.find(r => r.fullName === this.form.repo)) {
          await this.loadBranches()
        }
      } catch (error) {
        this.$message.error('加载仓库列表失败')
        this.repositories = []
      } finally {
        this.loadingRepos = false
      }
    },

    // 搜索仓库
    async searchRepositories(query) {
      if (!query || !this.tokenValid) return
      // 这里可以实现远程搜索逻辑
      // 当前直接过滤本地已加载的仓库
      this.repositories = this.repositories.filter(repo => 
        repo.name.toLowerCase().includes(query.toLowerCase()) ||
        repo.fullName.toLowerCase().includes(query.toLowerCase())
      )
    },

    // 仓库改变时
    async onRepoChange() {
      this.form.branch = 'main'
      this.branches = []
      if (this.form.repo) {
        await this.loadBranches()
      }
    },

    // 加载分支列表
    async loadBranches() {
      if (!this.form.repo) return

      const [owner, repo] = this.form.repo.split('/')
      this.loadingBranches = true
      
      try {
        this.branches = await GitHubService.getBranches(this.form.token, owner, repo)
        
        // 如果默认分支存在，选中它
        const defaultBranch = this.branches.find(b => b.name === 'main') || 
                             this.branches.find(b => b.name === 'master') ||
                             this.branches[0]
        
        if (defaultBranch && !this.form.branch) {
          this.form.branch = defaultBranch.name
        }
      } catch (error) {
        this.$message.error('加载分支列表失败')
        this.branches = []
      } finally {
        this.loadingBranches = false
      }
    },

    // 保存配置
    async saveConfig() {
      try {
        await this.$refs.configForm.validate()
        
        this.saving = true
        const [owner, repo] = this.form.repo.split('/')
        
        const config = {
          ...this.form,
          owner,
          repo: repo,
          userInfo: this.userInfo
        }

        this.setGitHubConfig(config)
        
        this.$message.success('GitHub配置保存成功')
        this.$emit('config-saved', config)
        this.handleClose()
      } catch (error) {
        console.error('保存配置失败:', error)
      } finally {
        this.saving = false
      }
    },

    // 重置表单
    resetForm() {
      this.$refs.configForm.resetFields()
      this.tokenValid = false
      this.userInfo = null
      this.repositories = []
      this.branches = []
      this.form = {
        token: '',
        repo: '',
        branch: 'main',
        enableAutoSave: true,
        autoSaveInterval: 30
      }
    },

    // 关闭对话框
    handleClose() {
      this.$emit('update:visible', false)
    }
  }
}
</script>

<style lang="less" scoped>
.github-config-dialog {
  .form-tip {
    font-size: 12px;
    color: #909399;
    margin-top: 5px;
  }

  .user-info {
    display: flex;
    align-items: center;
    gap: 10px;

    .username {
      font-weight: 500;
    }
  }

  .dialog-footer {
    text-align: right;
  }
}
</style>