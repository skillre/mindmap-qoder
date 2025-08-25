const express = require('express');
const axios = require('axios');
const router = express.Router();

// GitHub API基础配置
const GITHUB_API_BASE = 'https://api.github.com';

// 创建GitHub API客户端
const createGitHubClient = (token) => {
  return axios.create({
    baseURL: GITHUB_API_BASE,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'mindmap-qoder/1.0.0'
    }
  });
};

// 验证Token
router.post('/validate-token', async (req, res) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'Token不能为空'
      });
    }

    const client = createGitHubClient(token);
    const response = await client.get('/user');
    
    res.json({
      success: true,
      data: {
        username: response.data.login,
        avatar: response.data.avatar_url,
        name: response.data.name || response.data.login
      },
      message: 'Token验证成功'
    });
  } catch (error) {
    console.error('Token validation error:', error.response?.data || error.message);
    res.status(401).json({
      success: false,
      message: 'Token验证失败，请检查Token是否有效',
      error: error.response?.data?.message || error.message
    });
  }
});

// 获取仓库列表
router.get('/repositories', async (req, res) => {
  try {
    const { token, type = 'private' } = req.query;
    
    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'Token不能为空'
      });
    }

    const client = createGitHubClient(token);
    const response = await client.get('/user/repos', {
      params: {
        type: type, // all, owner, private, public
        sort: 'updated',
        per_page: 100
      }
    });
    
    const repositories = response.data.map(repo => ({
      id: repo.id,
      name: repo.name,
      fullName: repo.full_name,
      owner: repo.owner.login,
      private: repo.private,
      description: repo.description,
      updatedAt: repo.updated_at
    }));

    res.json({
      success: true,
      data: repositories,
      message: '获取仓库列表成功'
    });
  } catch (error) {
    console.error('Get repositories error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      message: '获取仓库列表失败',
      error: error.response?.data?.message || error.message
    });
  }
});

// 获取分支列表
router.get('/branches', async (req, res) => {
  try {
    const { token, owner, repo } = req.query;
    
    if (!token || !owner || !repo) {
      return res.status(400).json({
        success: false,
        message: '参数不完整，需要token、owner和repo'
      });
    }

    const client = createGitHubClient(token);
    const response = await client.get(`/repos/${owner}/${repo}/branches`);
    
    const branches = response.data.map(branch => ({
      name: branch.name,
      sha: branch.commit.sha,
      protected: branch.protected
    }));

    res.json({
      success: true,
      data: branches,
      message: '获取分支列表成功'
    });
  } catch (error) {
    console.error('Get branches error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      message: '获取分支列表失败',
      error: error.response?.data?.message || error.message
    });
  }
});

// 获取文件列表
router.get('/files', async (req, res) => {
  try {
    const { token, owner, repo, branch = 'main', path = 'mindmaps' } = req.query;
    
    if (!token || !owner || !repo) {
      return res.status(400).json({
        success: false,
        message: '参数不完整，需要token、owner和repo'
      });
    }

    const client = createGitHubClient(token);
    
    try {
      const response = await client.get(`/repos/${owner}/${repo}/contents/${path}`, {
        params: { ref: branch }
      });
      
      const files = Array.isArray(response.data) 
        ? response.data
            .filter(item => item.type === 'file' && item.name.endsWith('.json'))
            .map(file => ({
              name: file.name,
              path: file.path,
              sha: file.sha,
              size: file.size,
              downloadUrl: file.download_url
            }))
        : [];

      res.json({
        success: true,
        data: files,
        message: '获取文件列表成功'
      });
    } catch (error) {
      if (error.response?.status === 404) {
        // 目录不存在，返回空列表
        res.json({
          success: true,
          data: [],
          message: '目录不存在，返回空列表'
        });
      } else {
        throw error;
      }
    }
  } catch (error) {
    console.error('Get files error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      message: '获取文件列表失败',
      error: error.response?.data?.message || error.message
    });
  }
});

// 获取文件内容
router.get('/file/content', async (req, res) => {
  try {
    const { token, owner, repo, path, branch = 'main' } = req.query;
    
    if (!token || !owner || !repo || !path) {
      return res.status(400).json({
        success: false,
        message: '参数不完整，需要token、owner、repo和path'
      });
    }

    const client = createGitHubClient(token);
    const response = await client.get(`/repos/${owner}/${repo}/contents/${path}`, {
      params: { ref: branch }
    });
    
    const content = JSON.parse(
      Buffer.from(response.data.content, 'base64').toString('utf-8')
    );

    res.json({
      success: true,
      data: {
        content,
        sha: response.data.sha
      },
      message: '获取文件内容成功'
    });
  } catch (error) {
    console.error('Get file content error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      message: '获取文件内容失败',
      error: error.response?.data?.message || error.message
    });
  }
});

// 保存文件
router.post('/file/save', async (req, res) => {
  try {
    const { 
      token, 
      owner, 
      repo, 
      path, 
      content, 
      message = '保存思维导图文件',
      branch = 'main',
      sha 
    } = req.body;
    
    if (!token || !owner || !repo || !path || !content) {
      return res.status(400).json({
        success: false,
        message: '参数不完整，需要token、owner、repo、path和content'
      });
    }

    const client = createGitHubClient(token);
    
    // 添加元数据
    const fileContent = {
      version: '1.0',
      metadata: {
        title: content.root?.data?.text || '思维导图',
        created: new Date().toISOString(),
        modified: new Date().toISOString(),
        author: owner
      },
      data: content
    };

    const encodedContent = Buffer.from(JSON.stringify(fileContent, null, 2)).toString('base64');
    
    const payload = {
      message,
      content: encodedContent,
      branch
    };
    
    if (sha) {
      payload.sha = sha;
    }

    const response = await client.put(`/repos/${owner}/${repo}/contents/${path}`, payload);
    
    res.json({
      success: true,
      data: {
        sha: response.data.content.sha,
        htmlUrl: response.data.content.html_url
      },
      message: '文件保存成功'
    });
  } catch (error) {
    console.error('Save file error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      message: '文件保存失败',
      error: error.response?.data?.message || error.message
    });
  }
});

// 删除文件
router.delete('/file/delete', async (req, res) => {
  try {
    const { 
      token, 
      owner, 
      repo, 
      path, 
      sha,
      message = '删除思维导图文件',
      branch = 'main'
    } = req.body;
    
    if (!token || !owner || !repo || !path || !sha) {
      return res.status(400).json({
        success: false,
        message: '参数不完整，需要token、owner、repo、path和sha'
      });
    }

    const client = createGitHubClient(token);
    
    await client.delete(`/repos/${owner}/${repo}/contents/${path}`, {
      data: {
        message,
        sha,
        branch
      }
    });
    
    res.json({
      success: true,
      message: '文件删除成功'
    });
  } catch (error) {
    console.error('Delete file error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      message: '文件删除失败',
      error: error.response?.data?.message || error.message
    });
  }
});

module.exports = router;