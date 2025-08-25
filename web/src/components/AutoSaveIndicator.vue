<template>
  <div class="auto-save-indicator" v-if="isGitHubConfigured">
    <div class="save-status" :class="statusClass">
      <i :class="statusIcon"></i>
      <span class="status-text">{{ statusText }}</span>
    </div>
    <div class="last-save-time" v-if="lastSaveTime">
      上次保存: {{ formatTime(lastSaveTime) }}
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex'

export default {
  name: 'AutoSaveIndicator',
  computed: {
    ...mapState(['githubConfig', 'autoSaveStatus']),
    
    isGitHubConfigured() {
      return this.githubConfig && 
             this.githubConfig.token && 
             this.githubConfig.owner && 
             this.githubConfig.repo
    },

    lastSaveTime() {
      return this.autoSaveStatus.lastSaveTime
    },

    statusClass() {
      if (this.autoSaveStatus.saving) {
        return 'saving'
      } else if (this.autoSaveStatus.enabled) {
        return 'enabled'
      }
      return 'disabled'
    },

    statusIcon() {
      if (this.autoSaveStatus.saving) {
        return 'el-icon-loading'
      } else if (this.autoSaveStatus.enabled) {
        return 'el-icon-success'
      }
      return 'el-icon-warning'
    },

    statusText() {
      if (this.autoSaveStatus.saving) {
        return '保存中...'
      } else if (this.autoSaveStatus.enabled) {
        return `自动保存已启用 (${this.githubConfig.autoSaveInterval}s)`
      }
      return '自动保存已禁用'
    }
  },
  methods: {
    formatTime(timeString) {
      if (!timeString) return ''
      const date = new Date(timeString)
      return date.toLocaleTimeString('zh-CN', {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      })
    }
  }
}
</script>

<style lang="less" scoped>
.auto-save-indicator {
  position: fixed;
  bottom: 20px;
  right: 20px;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 8px;
  padding: 12px 16px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  font-size: 12px;
  z-index: 1000;
  border: 1px solid #ebeef5;

  .save-status {
    display: flex;
    align-items: center;
    margin-bottom: 4px;

    i {
      margin-right: 6px;
      font-size: 14px;
    }

    &.saving {
      color: #409eff;
      
      i {
        animation: rotate 1s linear infinite;
      }
    }

    &.enabled {
      color: #67c23a;
    }

    &.disabled {
      color: #e6a23c;
    }
  }

  .last-save-time {
    color: #909399;
    font-size: 11px;
  }

  @keyframes rotate {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }
}

// 暗黑模式适配
.isDark .auto-save-indicator {
  background: rgba(38, 42, 46, 0.95);
  border-color: #4c4d4f;
  color: rgba(255, 255, 255, 0.9);

  .last-save-time {
    color: rgba(255, 255, 255, 0.6);
  }
}
</style>