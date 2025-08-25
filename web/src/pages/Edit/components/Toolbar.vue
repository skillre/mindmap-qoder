<template>
  <div class="toolbarContainer" :class="{ isDark: isDark }">
    <div class="toolbar" ref="toolbarRef">
      <!-- 节点操作 -->
      <div class="toolbarBlock">
        <ToolbarNodeBtnList :list="horizontalList"></ToolbarNodeBtnList>
        <!-- 更多 -->
        <el-popover
          v-model="popoverShow"
          placement="bottom-end"
          width="120"
          trigger="hover"
          v-if="showMoreBtn"
          :style="{ marginLeft: horizontalList.length > 0 ? '20px' : 0 }"
        >
          <ToolbarNodeBtnList
            dir="v"
            :list="verticalList"
            @click.native="popoverShow = false"
          ></ToolbarNodeBtnList>
          <div slot="reference" class="toolbarBtn">
            <span class="icon iconfont icongongshi"></span>
            <span class="text">{{ $t('toolbar.more') }}</span>
          </div>
        </el-popover>
      </div>
      <!-- GitHub 云端功能 -->
      <div class="toolbarBlock">
        <div class="toolbarBtn" @click="showGitHubConfig">
          <span class="icon iconfont iconGitHub"></span>
          <span class="text">配置</span>
        </div>
        <div class="toolbarBtn" @click="showGitHubFiles" :class="{ disabled: !isGitHubConfigured }">
          <span class="icon iconfont iconcloud"></span>
          <span class="text">云端文件</span>
        </div>
        <div class="toolbarBtn" @click="manualSave" :class="{ disabled: !canSave }" v-if="isGitHubConfigured">
          <span class="icon iconfont iconsave"></span>
          <span class="text">手动保存</span>
        </div>
      </div>
      <!-- 导出导入 -->
      <div class="toolbarBlock">
        <div class="toolbarBtn" @click="$bus.$emit('showImport')">
          <span class="icon iconfont icondaoru"></span>
          <span class="text">{{ $t('toolbar.import') }}</span>
        </div>
        <div
          class="toolbarBtn"
          @click="$bus.$emit('showExport')"
          style="margin-right: 0;"
        >
          <span class="icon iconfont iconexport"></span>
          <span class="text">{{ $t('toolbar.export') }}</span>
        </div>
      </div>
    </div>
    <NodeImage></NodeImage>
    <NodeHyperlink></NodeHyperlink>
    <NodeIcon></NodeIcon>
    <NodeNote></NodeNote>
    <NodeTag></NodeTag>
    <Export></Export>
    <Import ref="ImportRef"></Import>
    <!-- GitHub 相关组件 -->
    <GitHubConfig
      :visible.sync="githubConfigVisible"
      @config-saved="onGitHubConfigSaved"
    ></GitHubConfig>
    <GitHubFiles
      :visible.sync="githubFilesVisible"
      @open-config="showGitHubConfig"
    ></GitHubFiles>
  </div>
</template>

<script>
import NodeImage from './NodeImage.vue'
import NodeHyperlink from './NodeHyperlink.vue'
import NodeIcon from './NodeIcon.vue'
import NodeNote from './NodeNote.vue'
import NodeTag from './NodeTag.vue'
import Export from './Export.vue'
import Import from './Import.vue'
import GitHubConfig from '@/components/GitHubConfig.vue'
import GitHubFiles from '@/components/GitHubFiles.vue'
import { mapState } from 'vuex'
import ToolbarNodeBtnList from './ToolbarNodeBtnList.vue'
import { throttle, isMobile } from 'simple-mind-map/src/utils/index'
import GitHubService from '@/api/github'
import { getData } from '@/api'

// 工具栏
const defaultBtnList = [
  'back',
  'forward',
  'painter',
  'siblingNode',
  'childNode',
  'deleteNode',
  'image',
  'icon',
  'link',
  'note',
  'tag',
  'summary',
  'associativeLine',
  'formula',
  // 'attachment',
  'outerFrame',
  'annotation',
  'ai'
]

export default {
  components: {
    NodeImage,
    NodeHyperlink,
    NodeIcon,
    NodeNote,
    NodeTag,
    Export,
    Import,
    GitHubConfig,
    GitHubFiles,
    ToolbarNodeBtnList
  },
  data() {
    return {
      isMobile: isMobile(),
      horizontalList: [],
      verticalList: [],
      showMoreBtn: true,
      popoverShow: false,
      // GitHub 相关状态
      githubConfigVisible: false,
      githubFilesVisible: false,
      saving: false
    }
  },
  computed: {
    ...mapState({
      isDark: state => state.localConfig.isDark,
      openNodeRichText: state => state.localConfig.openNodeRichText,
      enableAi: state => state.localConfig.enableAi,
      githubConfig: state => state.githubConfig,
      currentFile: state => state.currentFile,
      autoSaveStatus: state => state.autoSaveStatus
    }),

    // 是否已配置GitHub
    isGitHubConfigured() {
      return this.githubConfig && 
             this.githubConfig.token && 
             this.githubConfig.owner && 
             this.githubConfig.repo
    },

    // 是否可以保存
    canSave() {
      return this.isGitHubConfigured && !this.saving
    },

    btnLit() {
      let res = [...defaultBtnList]
      if (!this.openNodeRichText) {
        res = res.filter(item => {
          return item !== 'formula'
        })
      }
      if (!this.enableAi) {
        res = res.filter(item => {
          return item !== 'ai'
        })
      }
      return res
    }
  },
  watch: {
    btnLit: {
      deep: true,
      handler() {
        this.computeToolbarShow()
      }
    }
  },
  created() {
    // 初始化自动保存
    if (this.isGitHubConfigured && this.githubConfig.enableAutoSave) {
      this.startAutoSave()
    }
    // 监听GitHub自动保存事件
    this.$bus.$on('github_auto_save', this.handleGitHubAutoSave)
  },
  mounted() {
    this.computeToolbarShow()
    this.computeToolbarShowThrottle = throttle(this.computeToolbarShow, 300)
    window.addEventListener('resize', this.computeToolbarShowThrottle)
    this.$bus.$on('lang_change', this.computeToolbarShowThrottle)
    this.$bus.$on('node_note_dblclick', this.onNodeNoteDblclick)
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.computeToolbarShowThrottle)
    this.$bus.$off('lang_change', this.computeToolbarShowThrottle)
    this.$bus.$off('node_note_dblclick', this.onNodeNoteDblclick)
    this.$bus.$off('github_auto_save', this.handleGitHubAutoSave)
    // 清理自动保存
    this.stopAutoSave()
  },
  methods: {
    // 计算工具按钮如何显示
    computeToolbarShow() {
      if (!this.$refs.toolbarRef) return
      const windowWidth = window.innerWidth - 40
      const all = [...this.btnLit]
      let index = 1
      const loopCheck = () => {
        if (index > all.length) return done()
        this.horizontalList = all.slice(0, index)
        this.$nextTick(() => {
          const width = this.$refs.toolbarRef.getBoundingClientRect().width
          if (width < windowWidth) {
            index++
            loopCheck()
          } else if (index > 0 && width > windowWidth) {
            index--
            this.horizontalList = all.slice(0, index)
            done()
          }
        })
      }
      const done = () => {
        this.verticalList = all.slice(index)
        this.showMoreBtn = this.verticalList.length > 0
      }
      loopCheck()
    },

    onNodeNoteDblclick(node, e) {
      e.stopPropagation()
      this.$bus.$emit('showNodeNote', node)
    },

    // 显示GitHub配置对话框
    showGitHubConfig() {
      this.githubConfigVisible = true
    },

    // 显示GitHub文件管理对话框
    showGitHubFiles() {
      if (!this.isGitHubConfigured) {
        this.$message.warning('请先配置GitHub')
        this.showGitHubConfig()
        return
      }
      this.githubFilesVisible = true
    },

    // GitHub配置保存回调
    onGitHubConfigSaved(config) {
      // 启动自动保存
      if (config.enableAutoSave) {
        this.startAutoSave()
      } else {
        this.stopAutoSave()
      }
      this.$message.success('GitHub配置已保存')
    },

    // 手动保存
    async manualSave() {
      if (!this.canSave) return
      
      this.saving = true
      try {
        const data = getData()
        const result = await GitHubService.autoSave(
          this.githubConfig,
          data,
          this.currentFile.path,
          this.currentFile.sha
        )
        
        // 更新当前文件信息
        this.$store.commit('setCurrentFile', {
          ...this.currentFile,
          sha: result.sha
        })
        
        this.$store.commit('updateLastSaveTime')
        this.$message.success('保存成功')
      } catch (error) {
        console.error('手动保存失败:', error)
        this.$message.error('保存失败')
      } finally {
        this.saving = false
      }
    },

    // 启动自动保存
    startAutoSave() {
      if (!this.isGitHubConfigured) return
      
      const callback = async () => {
        if (this.autoSaveStatus.saving) return
        
        try {
          this.$store.commit('setAutoSaveStatus', { saving: true })
          const data = getData()
          const result = await GitHubService.autoSave(
            this.githubConfig,
            data,
            this.currentFile.path,
            this.currentFile.sha
          )
          
          // 更新当前文件信息
          this.$store.commit('setCurrentFile', {
            ...this.currentFile,
            sha: result.sha
          })
          
          this.$store.commit('updateLastSaveTime')
        } catch (error) {
          console.error('自动保存失败:', error)
        } finally {
          this.$store.commit('setAutoSaveStatus', { saving: false })
        }
      }
      
      this.$store.commit('startAutoSave', {
        interval: this.githubConfig.autoSaveInterval || 30,
        callback
      })
    },

    // 停止自动保存
    stopAutoSave() {
      this.$store.commit('stopAutoSave')
    },

    // 处理GitHub自动保存事件
    async handleGitHubAutoSave(data) {
      if (!this.isGitHubConfigured || this.autoSaveStatus.saving) {
        return
      }
      
      // 防抖处理
      clearTimeout(this.autoSaveTimeout)
      this.autoSaveTimeout = setTimeout(async () => {
        try {
          this.$store.commit('setAutoSaveStatus', { saving: true })
          
          const result = await GitHubService.autoSave(
            this.githubConfig,
            data,
            this.currentFile.path,
            this.currentFile.sha
          )
          
          // 更新当前文件信息
          this.$store.commit('setCurrentFile', {
            ...this.currentFile,
            sha: result.sha,
            path: result.path || this.currentFile.path
          })
          
          this.$store.commit('updateLastSaveTime')
        } catch (error) {
          console.error('自动保存失败:', error)
        } finally {
          this.$store.commit('setAutoSaveStatus', { saving: false })
        }
      }, 2000) // 2秒防抖
    }
  }
}
</script>

<style lang="less" scoped>
.toolbarContainer {
  &.isDark {
    .toolbar {
      color: hsla(0, 0%, 100%, 0.9);
      .toolbarBlock {
        background-color: #262a2e;
      }

      .toolbarBtn {
        .icon {
          background: transparent;
          border-color: transparent;
        }

        &:hover {
          &:not(.disabled) {
            .icon {
              background: hsla(0, 0%, 100%, 0.05);
            }
          }
        }

        &.disabled {
          color: #54595f;
        }
      }
    }
  }
  .toolbar {
    position: fixed;
    left: 50%;
    transform: translateX(-50%);
    top: 20px;
    width: max-content;
    display: flex;
    font-size: 12px;
    font-family: PingFangSC-Regular, PingFang SC;
    font-weight: 400;
    color: rgba(26, 26, 26, 0.8);
    z-index: 2;

    .toolbarBlock {
      display: flex;
      background-color: #fff;
      padding: 10px 20px;
      border-radius: 6px;
      box-shadow: 0 2px 16px 0 rgba(0, 0, 0, 0.06);
      border: 1px solid rgba(0, 0, 0, 0.06);
      margin-right: 20px;
      flex-shrink: 0;
      position: relative;

      &:last-of-type {
        margin-right: 0;
      }
    }

    .toolbarBtn {
      display: flex;
      justify-content: center;
      flex-direction: column;
      cursor: pointer;
      margin-right: 20px;

      &:last-of-type {
        margin-right: 0;
      }

      &:hover {
        &:not(.disabled) {
          .icon {
            background: #f5f5f5;
          }
        }
      }

      &.active {
        .icon {
          background: #f5f5f5;
        }
      }

      &.disabled {
        color: #bcbcbc;
        cursor: not-allowed;
        pointer-events: none;
      }

      .icon {
        display: flex;
        height: 26px;
        background: #fff;
        border-radius: 4px;
        border: 1px solid #e9e9e9;
        justify-content: center;
        flex-direction: column;
        text-align: center;
        padding: 0 5px;
      }

      .text {
        margin-top: 3px;
      }
    }
  }
}
</style>
