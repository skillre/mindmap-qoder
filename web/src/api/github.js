import axios from 'axios'
import { Message } from 'element-ui'

// 创建API实例
const api = axios.create({
  baseURL: process.env.NODE_ENV === 'production' 
    ? '/api' 
    : 'http://localhost:3000/api',
  timeout: 30000
})

// 请求拦截器
api.interceptors.request.use(
  config => {
    // 可以在这里添加loading状态
    return config
  },
  error => {
    return Promise.reject(error)
  }
)

// 响应拦截器
api.interceptors.response.use(
  response => {
    const { data } = response
    if (data.success === false) {
      Message.error(data.message || '请求失败')
      return Promise.reject(new Error(data.message || '请求失败'))
    }
    return data
  },
  error => {
    const message = error.response?.data?.message || error.message || '网络错误'
    Message.error(message)
    return Promise.reject(error)
  }
)

/**
 * GitHub API服务类
 */
class GitHubService {
  /**
   * 验证GitHub Token
   * @param {string} token GitHub Personal Access Token
   * @returns {Promise<Object>} 用户信息
   */
  static async validateToken(token) {
    const response = await api.post('/github/validate-token', { token })
    return response.data
  }

  /**
   * 获取仓库列表
   * @param {string} token GitHub Token
   * @param {string} type 仓库类型 (all, owner, private, public)
   * @returns {Promise<Array>} 仓库列表
   */
  static async getRepositories(token, type = 'private') {
    const response = await api.get('/github/repositories', {
      params: { token, type }
    })
    return response.data
  }

  /**
   * 获取分支列表
   * @param {string} token GitHub Token
   * @param {string} owner 仓库所有者
   * @param {string} repo 仓库名称
   * @returns {Promise<Array>} 分支列表
   */
  static async getBranches(token, owner, repo) {
    const response = await api.get('/github/branches', {
      params: { token, owner, repo }
    })
    return response.data
  }

  /**
   * 获取文件列表
   * @param {string} token GitHub Token
   * @param {string} owner 仓库所有者
   * @param {string} repo 仓库名称
   * @param {string} branch 分支名称
   * @param {string} path 目录路径
   * @returns {Promise<Array>} 文件列表
   */
  static async getFiles(token, owner, repo, branch = 'main', path = 'mindmaps') {
    const response = await api.get('/github/files', {
      params: { token, owner, repo, branch, path }
    })
    return response.data
  }

  /**
   * 获取文件内容
   * @param {string} token GitHub Token
   * @param {string} owner 仓库所有者
   * @param {string} repo 仓库名称
   * @param {string} path 文件路径
   * @param {string} branch 分支名称
   * @returns {Promise<Object>} 文件内容和SHA
   */
  static async getFileContent(token, owner, repo, path, branch = 'main') {
    const response = await api.get('/github/file/content', {
      params: { token, owner, repo, path, branch }
    })
    return response.data
  }

  /**
   * 保存文件
   * @param {Object} params 保存参数
   * @param {string} params.token GitHub Token
   * @param {string} params.owner 仓库所有者
   * @param {string} params.repo 仓库名称
   * @param {string} params.path 文件路径
   * @param {Object} params.content 文件内容
   * @param {string} params.message 提交信息
   * @param {string} params.branch 分支名称
   * @param {string} params.sha 文件SHA (更新时必需)
   * @returns {Promise<Object>} 保存结果
   */
  static async saveFile({
    token,
    owner,
    repo,
    path,
    content,
    message = '保存思维导图文件',
    branch = 'main',
    sha
  }) {
    const response = await api.post('/github/file/save', {
      token,
      owner,
      repo,
      path,
      content,
      message,
      branch,
      sha
    })
    return response.data
  }

  /**
   * 删除文件
   * @param {Object} params 删除参数
   * @param {string} params.token GitHub Token
   * @param {string} params.owner 仓库所有者
   * @param {string} params.repo 仓库名称
   * @param {string} params.path 文件路径
   * @param {string} params.sha 文件SHA
   * @param {string} params.message 提交信息
   * @param {string} params.branch 分支名称
   * @returns {Promise<void>}
   */
  static async deleteFile({
    token,
    owner,
    repo,
    path,
    sha,
    message = '删除思维导图文件',
    branch = 'main'
  }) {
    await api.delete('/github/file/delete', {
      data: {
        token,
        owner,
        repo,
        path,
        sha,
        message,
        branch
      }
    })
  }

  /**
   * 生成文件路径
   * @param {string} filename 文件名
   * @returns {string} 完整路径
   */
  static generateFilePath(filename) {
    if (!filename.endsWith('.json')) {
      filename += '.json'
    }
    return `mindmaps/${filename}`
  }

  /**
   * 生成默认文件名
   * @param {string} title 思维导图标题
   * @returns {string} 文件名
   */
  static generateFileName(title = '思维导图') {
    const timestamp = new Date().toISOString().slice(0, 19).replace(/[:-]/g, '')
    const safeName = title.replace(/[^a-zA-Z0-9\u4e00-\u9fa5]/g, '_')
    return `${safeName}_${timestamp}.json`
  }

  /**
   * 自动保存
   * @param {Object} config GitHub配置
   * @param {Object} data 思维导图数据
   * @param {string} currentFilePath 当前文件路径 (可选)
   * @param {string} currentSha 当前文件SHA (可选)
   * @returns {Promise<Object>} 保存结果
   */
  static async autoSave(config, data, currentFilePath = null, currentSha = null) {
    const { token, owner, repo, branch } = config
    
    // 如果没有指定文件路径，生成新文件
    let filePath = currentFilePath
    if (!filePath) {
      const title = data.root?.data?.text || '思维导图'
      const fileName = this.generateFileName(title)
      filePath = this.generateFilePath(fileName)
    }

    return await this.saveFile({
      token,
      owner,
      repo,
      path: filePath,
      content: data,
      message: `自动保存: ${new Date().toLocaleString()}`,
      branch,
      sha: currentSha
    })
  }
}

export default GitHubService