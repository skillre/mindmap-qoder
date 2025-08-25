import Vue from 'vue'
import Vuex from 'vuex'
import { storeLocalConfig } from '@/api'

Vue.use(Vuex)

const store = new Vuex.Store({
  state: {
    isHandleLocalFile: false, // 是否操作的是本地文件
    localConfig: {
      // 本地配置
      isZenMode: false, // 是否是禅模式
      // 是否开启节点富文本
      openNodeRichText: true,
      // 鼠标行为
      useLeftKeySelectionRightKeyDrag: false,
      // 是否显示滚动条
      isShowScrollbar: false,
      // 是否是暗黑模式
      isDark: false,
      // 是否开启AI功能
      enableAi: true
    },
    activeSidebar: '', // 当前显示的侧边栏
    isOutlineEdit: false, // 是否是大纲编辑模式
    isReadonly: false, // 是否只读
    isSourceCodeEdit: false, // 是否是源码编辑模式
    extraTextOnExport: '', // 导出时底部添加的文字
    isDragOutlineTreeNode: false, // 当前是否正在拖拽大纲树的节点
    aiConfig: {
      api: 'http://ark.cn-beijing.volces.com/api/v3/chat/completions',
      key: '',
      model: '',
      port: 3456,
      method: 'POST'
    },
    // 扩展主题列表
    extendThemeGroupList: [],
    // 内置背景图片
    bgList: [],
    // GitHub 配置
    githubConfig: null,
    // 当前打开的文件信息
    currentFile: {
      path: null,
      sha: null,
      name: null
    },
    // 自动保存状态
    autoSaveStatus: {
      enabled: false,
      interval: 30,
      timer: null,
      lastSaveTime: null,
      saving: false
    }
  },
  mutations: {
    // 设置操作本地文件标志位
    setIsHandleLocalFile(state, data) {
      state.isHandleLocalFile = data
    },

    // 设置本地配置
    setLocalConfig(state, data) {
      const aiConfigKeys = Object.keys(state.aiConfig)
      Object.keys(data).forEach(key => {
        if (aiConfigKeys.includes(key)) {
          state.aiConfig[key] = data[key]
        } else {
          state.localConfig[key] = data[key]
        }
      })
      storeLocalConfig({
        ...state.localConfig,
        ...state.aiConfig
      })
    },

    // 设置当前显示的侧边栏
    setActiveSidebar(state, data) {
      state.activeSidebar = data
    },

    // 设置大纲编辑模式
    setIsOutlineEdit(state, data) {
      state.isOutlineEdit = data
    },

    // 设置是否只读
    setIsReadonly(state, data) {
      state.isReadonly = data
    },

    // 设置源码编辑模式
    setIsSourceCodeEdit(state, data) {
      state.isSourceCodeEdit = data
    },

    // 设置导出时底部添加的文字
    setExtraTextOnExport(state, data) {
      state.extraTextOnExport = data
    },

    // 设置树节点拖拽
    setIsDragOutlineTreeNode(state, data) {
      state.isDragOutlineTreeNode = data
    },

    // 扩展主题列表
    setExtendThemeGroupList(state, data) {
      state.extendThemeGroupList = data
    },

    // 设置背景图片列表
    setBgList(state, data) {
      state.bgList = data
    },

    // 设置GitHub配置
    setGitHubConfig(state, config) {
      state.githubConfig = config
      // 保存到localStorage
      try {
        localStorage.setItem('GITHUB_CONFIG', JSON.stringify(config))
      } catch (error) {
        console.error('保存GitHub配置失败:', error)
      }
    },

    // 设置当前文件信息
    setCurrentFile(state, fileInfo) {
      state.currentFile = { ...fileInfo }
    },

    // 清除当前文件信息
    clearCurrentFile(state) {
      state.currentFile = {
        path: null,
        sha: null,
        name: null
      }
    },

    // 设置自动保存状态
    setAutoSaveStatus(state, status) {
      state.autoSaveStatus = { ...state.autoSaveStatus, ...status }
    },

    // 启动自动保存
    startAutoSave(state, { interval, callback }) {
      // 清除现有定时器
      if (state.autoSaveStatus.timer) {
        clearInterval(state.autoSaveStatus.timer)
      }
      
      state.autoSaveStatus.enabled = true
      state.autoSaveStatus.interval = interval
      
      // 设置新的定时器
      state.autoSaveStatus.timer = setInterval(() => {
        if (callback && typeof callback === 'function') {
          callback()
        }
      }, interval * 1000)
    },

    // 停止自动保存
    stopAutoSave(state) {
      if (state.autoSaveStatus.timer) {
        clearInterval(state.autoSaveStatus.timer)
        state.autoSaveStatus.timer = null
      }
      state.autoSaveStatus.enabled = false
    },

    // 更新最后保存时间
    updateLastSaveTime(state) {
      state.autoSaveStatus.lastSaveTime = new Date().toISOString()
    }
  },
  actions: {
    // 初始化GitHub配置
    initGitHubConfig({ commit }) {
      try {
        const config = localStorage.getItem('GITHUB_CONFIG')
        if (config) {
          const parsedConfig = JSON.parse(config)
          commit('setGitHubConfig', parsedConfig)
        }
      } catch (error) {
        console.error('初始化GitHub配置失败:', error)
      }
    },

    // 清除GitHub配置
    clearGitHubConfig({ commit }) {
      commit('setGitHubConfig', null)
      localStorage.removeItem('GITHUB_CONFIG')
    }
  }
})

export default store
