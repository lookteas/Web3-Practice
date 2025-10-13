// Pinata IPFS 配置
const PINATA_CONFIG = {
    // Pinata API 端点
    API_URL: 'https://api.pinata.cloud',
    
    // 多个IPFS网关配置，按优先级排序
    GATEWAY_URLS: [
        'https://aqua-magnificent-bee-282.mypinata.cloud/ipfs',
        'https://ipfs.io/ipfs',
        'https://cloudflare-ipfs.com/ipfs'
    ],
    
    // 保持向后兼容
    GATEWAY_URL: 'https://aqua-magnificent-bee-282.mypinata.cloud/ipfs',
    
    // API 密钥 - 请在实际使用时替换为您的密钥
    // 建议通过环境变量或用户输入获取，不要直接硬编码
    API_KEY: '', // 您的 Pinata API Key
    SECRET_KEY: '', // 您的 Pinata Secret Key
    JWT: '', // 您的 Pinata JWT Token (推荐使用)
    
    // 上传选项
    OPTIONS: {
        // 文件大小限制 (10MB)
        MAX_FILE_SIZE: 10 * 1024 * 1024,
        
        // 支持的图片格式
        SUPPORTED_IMAGE_TYPES: [
            'image/jpeg',
            'image/jpg', 
            'image/png',
            'image/gif',
            'image/webp',
            'image/svg+xml'
        ],
        
        // 默认元数据选项
        DEFAULT_METADATA_OPTIONS: {
            name: 'NFT Metadata',
            keyvalues: {
                project: 'NFT-Market',
                type: 'metadata'
            }
        },
        
        // 默认图片选项
        DEFAULT_IMAGE_OPTIONS: {
            name: 'NFT Image',
            keyvalues: {
                project: 'NFT-Market',
                type: 'image'
            }
        }
    }
};

/**
 * 尝试多个IPFS网关获取内容
 * @param {string} hash - IPFS哈希
 * @param {number} timeout - 每个网关的超时时间（毫秒）
 * @returns {Promise<string>} 成功的网关URL
 */
// 请求缓存和节流机制
const gatewayCache = new Map();
const requestThrottle = new Map();

async function tryMultipleGateways(hash, timeout = 5000) {
    // 检查缓存
    const cacheKey = hash;
    if (gatewayCache.has(cacheKey)) {
        const cachedResult = gatewayCache.get(cacheKey);
        // 缓存5分钟
        if (Date.now() - cachedResult.timestamp < 5 * 60 * 1000) {
            console.log(`使用缓存的网关: ${cachedResult.url}`);
            return cachedResult.url;
        } else {
            gatewayCache.delete(cacheKey);
        }
    }

    // 检查节流
    const throttleKey = hash;
    if (requestThrottle.has(throttleKey)) {
        const lastRequest = requestThrottle.get(throttleKey);
        const timeSinceLastRequest = Date.now() - lastRequest;
        // 同一个hash在2秒内只能请求一次
        if (timeSinceLastRequest < 2000) {
            console.log(`请求被节流，等待 ${2000 - timeSinceLastRequest}ms`);
            await new Promise(resolve => setTimeout(resolve, 2000 - timeSinceLastRequest));
        }
    }
    
    requestThrottle.set(throttleKey, Date.now());
    
    const gateways = PINATA_CONFIG.GATEWAY_URLS;
    
    for (let i = 0; i < gateways.length; i++) {
        const gatewayUrl = `${gateways[i]}/${hash}`;
        
        try {
            console.log(`尝试网关 ${i + 1}/${gateways.length}: ${gateways[i]}`);
            
            // 创建带超时的请求
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), timeout);
            
            const response = await fetch(gatewayUrl, {
                method: 'HEAD', // 只检查头部，不下载内容
                signal: controller.signal
            });
            
            clearTimeout(timeoutId);
            
            if (response.ok) {
                console.log(`网关 ${gateways[i]} 响应成功`);
                
                // 缓存成功的结果
                gatewayCache.set(cacheKey, {
                    url: gatewayUrl,
                    timestamp: Date.now()
                });
                
                return gatewayUrl;
            } else {
                console.warn(`网关 ${gateways[i]} 响应失败: ${response.status}`);
            }
            
        } catch (error) {
            console.warn(`网关 ${gateways[i]} 连接失败:`, error.message);
            
            // 如果不是最后一个网关，继续尝试下一个
            if (i < gateways.length - 1) {
                continue;
            }
        }
        
        // 在网关之间添加延迟，避免过于频繁的请求
        if (i < gateways.length - 1) {
            await new Promise(resolve => setTimeout(resolve, 500));
        }
    }
    
    // 所有网关都失败，返回默认的第一个网关
    console.warn('所有网关都无法访问，使用默认网关');
    const defaultUrl = `${gateways[0]}/${hash}`;
    
    // 即使失败也缓存结果，避免重复尝试
    gatewayCache.set(cacheKey, {
        url: defaultUrl,
        timestamp: Date.now()
    });
    
    return defaultUrl;
}

/**
 * 获取IPFS内容的最佳网关URL
 * @param {string} hash - IPFS哈希
 * @returns {Promise<string>} 最佳网关URL
 */
async function getBestGatewayUrl(hash) {
    try {
        return await tryMultipleGateways(hash);
    } catch (error) {
        console.error('获取最佳网关失败:', error);
        // 返回默认网关
        return `${PINATA_CONFIG.GATEWAY_URLS[0]}/${hash}`;
    }
}

// API 密钥验证函数
function validatePinataConfig() {
    if (!PINATA_CONFIG.JWT && (!PINATA_CONFIG.API_KEY || !PINATA_CONFIG.SECRET_KEY)) {
        return false;
    }
    return true;
}

// 获取认证头
function getPinataAuthHeaders() {
    if (PINATA_CONFIG.JWT) {
        return {
            'Authorization': `Bearer ${PINATA_CONFIG.JWT}`
        };
    } else {
        return {
            'pinata_api_key': PINATA_CONFIG.API_KEY,
            'pinata_secret_api_key': PINATA_CONFIG.SECRET_KEY
        };
    }
}

// 设置 API 密钥的函数
function setPinataCredentials(apiKey, secretKey, jwt) {
    if (jwt) {
        PINATA_CONFIG.JWT = jwt;
        PINATA_CONFIG.API_KEY = '';
        PINATA_CONFIG.SECRET_KEY = '';
    } else if (apiKey && secretKey) {
        PINATA_CONFIG.API_KEY = apiKey;
        PINATA_CONFIG.SECRET_KEY = secretKey;
        PINATA_CONFIG.JWT = '';
    }
    
    // 保存到本地存储
    try {
        if (jwt) {
            localStorage.setItem('pinata_jwt', jwt);
            localStorage.removeItem('pinata_api_key');
            localStorage.removeItem('pinata_secret_key');
        } else {
            localStorage.setItem('pinata_api_key', apiKey);
            localStorage.setItem('pinata_secret_key', secretKey);
            localStorage.removeItem('pinata_jwt');
        }
    } catch (error) {
        console.warn('无法保存 Pinata 凭据到本地存储:', error);
    }
}

// 从本地存储加载凭据
function loadPinataCredentials() {
    try {
        const jwt = localStorage.getItem('pinata_jwt');
        const apiKey = localStorage.getItem('pinata_api_key');
        const secretKey = localStorage.getItem('pinata_secret_key');
        
        if (jwt) {
            PINATA_CONFIG.JWT = jwt;
        } else if (apiKey && secretKey) {
            PINATA_CONFIG.API_KEY = apiKey;
            PINATA_CONFIG.SECRET_KEY = secretKey;
        }
    } catch (error) {
        console.warn('无法从本地存储加载 Pinata 凭据:', error);
    }
}

// 清除凭据
function clearPinataCredentials() {
    PINATA_CONFIG.API_KEY = '';
    PINATA_CONFIG.SECRET_KEY = '';
    PINATA_CONFIG.JWT = '';
    
    try {
        localStorage.removeItem('pinata_api_key');
        localStorage.removeItem('pinata_secret_key');
        localStorage.removeItem('pinata_jwt');
    } catch (error) {
        console.warn('无法清除本地存储的 Pinata 凭据:', error);
    }
}

// 测试 Pinata 连接
async function testPinataConnection() {
    try {
        const response = await fetch(`${PINATA_CONFIG.API_URL}/data/testAuthentication`, {
            method: 'GET',
            headers: {
                ...getPinataAuthHeaders()
            }
        });
        
        if (response.ok) {
            const data = await response.json();
            return { success: true, message: '连接成功', data };
        } else {
            return { success: false, message: '认证失败，请检查API密钥' };
        }
    } catch (error) {
        return { success: false, message: `连接失败: ${error.message}` };
    }
}

// 导出配置和函数
if (typeof module !== 'undefined' && module.exports) {
    // Node.js 环境
    module.exports = {
        PINATA_CONFIG,
        validatePinataConfig,
        getPinataAuthHeaders,
        setPinataCredentials,
        loadPinataCredentials,
        clearPinataCredentials,
        testPinataConnection
    };
} else {
    // 浏览器环境
    window.PINATA_CONFIG = PINATA_CONFIG;
    window.validatePinataConfig = validatePinataConfig;
    window.getPinataAuthHeaders = getPinataAuthHeaders;
    window.setPinataCredentials = setPinataCredentials;
    window.loadPinataCredentials = loadPinataCredentials;
    window.clearPinataCredentials = clearPinataCredentials;
    window.testPinataConnection = testPinataConnection;
}