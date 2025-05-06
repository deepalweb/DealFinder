/**
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * 初始化 window.ezsite
 * @example
 * window.ezsite = {
 *    PROJECT_CODE: "abcdefg",
 *    init(),
 *    http,
 *      get()
 *      post()
 *      put()
 *      delete()
 *    apis
 *      register()
 *      login()
 *      getGoogleLoginUrl()
 *      loginWithGoogle()
 *      getFacebookLoginUrl()
 *      loginWithFacebook()
 *      logout()
 *      forgetPassword()
 *      getUserInfo()
 *      tableCreate()
 *      tableUpdate()
 *      tableDelete()
 *      tablePage()
 *      tableList()
 *      tableCount()
 *      upload()
 *      getUploadUrl()
 *      getProducts()
 *      createOrder()
 *      getUserSubscribeInfo()
 *      getUserOrderList()
 *      sendResentEmail()
 * }
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */
window.ezsite = window.ezsite || {};

window.ezsite.init = function () {
  // 获取当前正在执行的script标签
  const currentScript = document.currentScript;

  // 从script标签中获取project-code属性值
  const projectCode = currentScript.getAttribute('project-code');
  // 将project-code值赋给window.ezsite.PROJECT_CODE
  window.ezsite.PROJECT_CODE = projectCode;
};

window.ezsite.init();

/**
 * +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * @title HTTP Request Client Utility
 * @description
 * 该模块提供了一个标准化的 HTTP 请求客户端，统一封装了请求处理和响应格式化。
 * 模块会在全局创建实例：window.ezsite.http
 * 支持的方法：
 * - get(url, options): 发送 GET 请求
 * - post(url, data, options): 发送 POST 请求
 * - put(url, data, options): 发送 PUT 请求
 * - delete(url, options): 发送 DELETE 请求
 * 统一响应格式:
 * {
 *   data: any | null,    // 响应数据，请求失败时为 null
 *   error: string | null, // 错误信息，请求成功时为 null
 *   original: Response    // 原始响应对象
 * }
 * 特殊选项:
 * - isReturnBody: 设置为 true 时返回原始响应体，默认 false
 * @example
 * const { data, error, original } = await window.ezsite.http.get('/api/users');
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */
(() => {
  // Ensure window.ezsite exists
  window.ezsite = window.ezsite || {};
  const searchParams = new URLSearchParams(location.search);
  const env = searchParams.get('env');

  /**
   * Default configuration
   * @type {Object}
   * @property {string} baseURL - Base URL for API requests
   * @property {number} timeout - Request timeout in milliseconds
   * @property {Object} headers - Default request headers
   */
  const defaultConfig = {
    baseURL:
      env === 'staging'
        ? 'https://usapi.hottask.com/stagingautodev'
        : 'https://usapi.hottask.com/autodev',
    timeout: 30000,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ReferrerInfo:
        typeof window !== 'undefined'
          ? JSON.stringify({
              url: window.location.href,
              agent: navigator.userAgent
            })
          : ''
    }
  };

  /**
   * Handle API response
   * @param {Response} response - Fetch Response object
   * @returns {Promise<any>} Parsed response data
   * @throws {Error} Throws error when request fails or business status code is not 200
   */
  const handleResponseJson = async (response, options = {}) => {
    if (!response.ok) {
      // throw new Error(`HTTP error! status: ${response.status}`);
      return {
        data: null,
        error: 'Network error!',
        original: response
      };
    }

    // If isReturnBody is true, return the raw response body
    if (options?.isReturnBody) {
      return {
        data: response,
        error: null,
        original: response
      };
    }

    const result = await response.json();

    // Handle standard API response format
    if (result.Code !== 200) {
      // Handle business error
      // throw new Error(result.Message || 'Request failed');
      return {
        data: null,
        error: result.Message || 'Request failed',
        original: response
      };
    }

    return {
      data: result.Data,
      error: null,
      original: response
    };
  };

  /**
   * Get authentication token from localStorage
   * @returns {string} Authentication token
   */
  const getToken = () => {
    return localStorage.getItem('token') || '';
  };

  /**
   * Create request instance
   * @param {Object} config - Configuration options
   * @returns {Object} Object containing request methods
   */
  const createRequest = (config = {}) => {
    // Merge configurations
    const finalConfig = {
      ...defaultConfig,
      ...config
    };

    // Base request method
    const request = async (url, options = {}) => {
      try {
        const token = getToken();
        const fullUrl = url.startsWith('http')
          ? url
          : finalConfig.baseURL + url;

        const res = await Promise.race([
          fetch(fullUrl, {
            ...options,
            headers: {
              ...finalConfig.headers,
              Authorization: token ? `Bearer ${token}` : '',
              ...options.headers
            }
          }),
          new Promise((_, reject) =>
            setTimeout(
              reject,
              options.timeout || finalConfig.timeout,
              'Request timeout'
            )
          )
        ]);
        return res;
      } catch (err) {
        if (typeof err === 'string') {
          console.error('Request Error:', err);
        }
        return Promise.reject(err);
      }
    };

    /**
     * GET request method
     * @param {string} url - Request URL
     * @param {Object} options - Request options
     * @returns {Promise<any>} Response data
     */
    const get = async (url, options = {}) => {
      const res = await request(url, {
        ...options,
        method: 'GET'
      });
      return handleResponseJson(res, options);
    };

    /**
     * POST request method
     * @param {string} url - Request URL
     * @param {any} data - Request body data
     * @param {Object} options - Request options
     * @param {boolean} options.isReturnBody - Whether to return raw response body
     * @returns {Promise<any>} Response data
     */
    const post = async (url, data, options = {}) => {
      const res = await request(url, {
        ...options,
        method: 'POST',
        body: JSON.stringify(data)
      });
      return handleResponseJson(res, options);
    };

    /**
     * PUT request method
     * @param {string} url - Request URL
     * @param {any} data - Request body data
     * @param {Object} options - Request options
     * @returns {Promise<any>} Response data
     */
    const put = async (url, data, options = {}) => {
      const res = await request(url, {
        ...options,
        method: 'PUT',
        body: JSON.stringify(data)
      });
      return handleResponseJson(res, options);
    };

    /**
     * DELETE request method
     * @param {string} url - Request URL
     * @param {Object} options - Request options
     * @returns {Promise<any>} Response data
     */
    const del = async (url, options = {}) => {
      const res = await request(url, {
        ...options,
        method: 'DELETE'
      });
      return handleResponseJson(res, options);
    };

    return {
      request,
      get,
      post,
      put,
      delete: del
    };
  };

  // Create and mount to window.ezsite.http
  window.ezsite.http = createRequest();
})();

/**
 * +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * @title API Interface
 * +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */
(function () {
  // 内部实现
  const projectCode = window.ezsite.PROJECT_CODE;
  const apis = {
    /**
     * 用户登录
     * @param {Object} data 登录数据
     * @param {string} data.email 邮箱
     * @param {string} data.password 密码
     * @returns {Promise<Object>} 登录结果
     */
    login: async (data) => {
      const res = await window.ezsite.http.post(
        `/CustomTableValue/SignIn/${projectCode}`,
        data
      );
      if (res.data) {
        localStorage.setItem('token', res.data);
      }
      return res;
    },
    /**
     * 获取Google登录URL
     * @param {Object} params 参数
     * @param {string} params.returnUrl 返回URL
     * @returns {Promise<string>} 返回 url
     */
    getGoogleLoginUrl: async (params) => {
      return window.ezsite.http.post(
        `/CustomTableValue/GetGoogleLoginUrl/${projectCode}`,
        params
      );
    },
    /**
     * Google登录
     * @param {Object} params 登录数据
     * @param {string} params.credential 登录code
     * @returns {Promise<Object>} 登录结果
     */
    loginWithGoogle: async (params) => {
      const res = await window.ezsite.http.post(
        `/CustomTableValue/GoogleLogin/${projectCode}`,
        params
      );
      if (res.data) {
        localStorage.setItem('token', res.data);
      }
      return res;
    },
    /**
     * 获取Facebook登录URL
     * @param {Object} params 参数
     * @param {string} params.returnUrl 返回URL
     * @returns {Promise<string>} 返回 url
     */
    getFacebookLoginUrl: async (params) => {
      return window.ezsite.http.post(
        `/CustomTableValue/GetFacebookLoginUrl/${projectCode}`,
        params
      );
    },
    /**
     * Facebook登录
     * @param {Object} params 登录数据
     * @param {string} params.credential 登录code
     * @returns {Promise<Object>} 登录结果
     */
    loginWithFacebook: async (params) => {
      const res = await window.ezsite.http.post(
        `/CustomTableValue/FacebookLogin/${projectCode}`,
        params
      );
      if (res.data) {
        localStorage.setItem('token', res.data);
      }
      return res;
    },
    /**
     * 注销登录
     */
    logout: async () => {
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          localStorage.setItem('token', '');
          resolve({ data: true, error: null });
        }, 1000);
      });
    },
    /**
     * 发送重置密码邮件
     * @param {Object} data 发送重置密码邮件数据
     * @param {string} data.email 邮箱
     * @returns {Promise<Object>} 发送重置密码邮件结果
     */
    sendResetPwdEmail: async (data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/SendResetPasswordEmail/${projectCode}`,
        data
      );
    },
    /**
     * 重置密码
     * @param {Object} data 重置密码数据
     * @param {string} data.token 重置密码token
     * @param {string} data.password 新密码
     * @returns {Promise<Object>} 重置密码结果
     */
    resetPassword: async (data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/ResetPasswordForEmail/${projectCode}`,
        data
      );
    },
    /**
     * 获取用户信息
     * @returns {Promise<Object>} 用户信息
     */
    getUserInfo: async () => {
      return window.ezsite.http.get(`/CustomTableValue/GetUser/${projectCode}`);
    },
    /**
     * 用户注册
     * @param {Object} data 注册数据
     * @param {string} data.email 邮箱
     * @param {string} data.password 密码
     * @returns {Promise<Object>} 注册结果
     */
    register: (data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/SignUp/${projectCode}`,
        data
      );
    },

    /**
     * 创建动态表
     * @param {string} tableId 表ID
     * @param {Object} data 表数据
     * @returns {Promise<Object>} 创建结果
     */
    tableCreate: (tableId, data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/Create/${projectCode}/${tableId}`,
        data
      );
    },
    /**
     * 更新动态表
     * @param {string} tableId 表ID
     * @param {Object} data 表数据
     * @returns {Promise<Object>} 更新结果
     */
    tableUpdate: (tableId, data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/UD/${projectCode}/${tableId}`,
        data
      );
    },
    /**
     * 删除动态表
     * @param {string} tableId 表ID
     * @param {Object} data 表数据
     * @returns {Promise<Object>} 删除结果
     */
    tableDelete: (tableId, data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/Delete/${projectCode}/${tableId}`,
        data
      );
    },
    /**
     * 获取动态表列表
     * @param {string} tableId 表ID
     * @param {Object} data 表数据
     * @returns {Promise<Object>} 获取列表结果
     */
    tablePage: (tableId, data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/Page/${projectCode}/${tableId}`,
        data
      );
    },
    tableList: (tableId, data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/List/${projectCode}/${tableId}`,
        data
      );
    },
    tableCount: (tableId, data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/Count/${projectCode}/${tableId}`,
        data
      );
    },
    /**
     * 上传文件
     * @param {string} tableId 表ID
     * @param {Object} data 表数据
     * @returns {Promise<Object>} 上传结果
     */
    upload: async (data = { filename: '', file: null }) => {
      try {
        const getUpUrlRes = await window.ezsite.http.post(
          `/CustomTable/GetPreUploadUrl/${projectCode}`,
          { filename: data.filename }
        );
        if (getUpUrlRes.error) {
          return getUpUrlRes;
        }
        const { FileStoreId, PreUploadUrl } = getUpUrlRes.data;
        const uploadRes = await fetch(PreUploadUrl, {
          method: 'PUT',
          body: data.file,
          headers: {
            'Content-Type': data.file.type || 'application/octet-stream'
          }
        });
        if (!uploadRes.ok) {
          return {
            data: null,
            error: '上传失败',
            original: uploadRes
          };
        }
        const uploadResJson = await window.ezsite.http.post(
          `/CustomTable/ReportUploadSuccess/${projectCode}`,
          { FileStoreId }
        );
        if (uploadResJson.error) {
          return uploadResJson;
        }
        return {
          data: FileStoreId,
          error: null,
          original: uploadResJson
        };
      } catch (err) {
        return {
          data: null,
          error: err.message,
          original: err
        };
      }
    },
    /**
     * 获取上传文件地址
     * @param {number} storeId 文件Id
     * @returns {Promise<Object>} 上传文件地址
     */
    getUploadUrl: async (fileId) => {
      return window.ezsite.http.post(
        `/CustomTable/GetFileStaticUrl/${projectCode}`,
        { fileId }
      );
    },
    /**
     * 获取订阅产品列表
     * @returns {Promise<Object>} 订阅产品列表
     */
    getProducts: async () => {
      return window.ezsite.http.post(
        `/CustomProduct/GetProductList/${projectCode}`
      );
    },
    /**
     * 创建订单
     * @param {Object} data 订单数据
     * @returns {Promise<Object>} 创建结果
     */
    createOrder: async (data) => {
      return window.ezsite.http.post(
        `/CustomOrder/CreateOrder/${projectCode}`,
        data
      );
    },
    /**
     * 获取用户订阅信息
     * @returns {Promise<Object>} 用户订阅信息
     */
    getUserSubscribeInfo: async (data) => {
      return window.ezsite.http.post(
        `/CustomOrder/GetUserSubscribe/${projectCode}`,
        data
      );
    },
    /**
     * 获取用户订单列表
     * @returns {Promise<Object>} 用户订单列表
     */
    getUserOrderList: async (data) => {
      return window.ezsite.http.post(
        `/CustomOrder/GetUserOrderList/${projectCode}`,
        data
      );
    },
    /**
     * send Email
     * @param {Object} data 发送数据
     * @returns {Promise<Object>} 发送结果
     */
    sendEmail: async (data) => {
      return window.ezsite.http.post(
        `/Integration/EmailSend/${projectCode}`,
        data
      );
    },
    /**
     * sql 查询
     * @param {Object} data 查询数据
     * @returns {Promise<Object>} 查询结果
     */
    sqlQuery: async (data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/SqlQuery/${projectCode}`,
        data
      );
    },
    /**
     * sql 执行
     * @param {Object} data 执行数据
     * @returns {Promise<Object>} 执行结果
     */
    sqlExecute: async (data) => {
      return window.ezsite.http.post(
        `/CustomTableValue/SqlExecute/${projectCode}`,
        data
      );
    }
  };

  // 暴露到全局
  window.ezsite = window.ezsite || {};
  window.ezsite.apis = Object.keys(apis).reduce((acc, key) => {
    acc[key] = apis[key];
    return acc;
  }, {});
})();
