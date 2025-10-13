// IPFS 上传工具函数
// 使用 Pinata 服务进行 IPFS 文件上传

/**
 * 上传文件到 IPFS (通过 Pinata)
 * @param {File} file - 要上传的文件
 * @param {Object} options - 上传选项
 * @param {Function} onProgress - 进度回调函数
 * @returns {Promise<Object>} 上传结果
 */
async function uploadFileToIPFS(file, options = {}, onProgress = null) {
    try {
        // 验证配置
        if (!validatePinataConfig()) {
            throw new Error('请先配置 Pinata API 密钥');
        }

        // 验证文件
        if (!file) {
            throw new Error('请选择要上传的文件');
        }

        // 检查文件大小
        if (file.size > PINATA_CONFIG.OPTIONS.MAX_FILE_SIZE) {
            throw new Error(`文件大小超过限制 (${PINATA_CONFIG.OPTIONS.MAX_FILE_SIZE / 1024 / 1024}MB)`);
        }

        // 检查文件类型（如果是图片）
        if (file.type.startsWith('image/') && 
            !PINATA_CONFIG.OPTIONS.SUPPORTED_IMAGE_TYPES.includes(file.type)) {
            throw new Error('不支持的图片格式');
        }

        // 创建 FormData
        const formData = new FormData();
        formData.append('file', file);

        // 设置元数据
        const metadata = {
            name: options.name || file.name,
            keyvalues: {
                ...PINATA_CONFIG.OPTIONS.DEFAULT_IMAGE_OPTIONS.keyvalues,
                ...options.keyvalues,
                originalName: file.name,
                fileType: file.type,
                fileSize: file.size.toString(),
                uploadTime: new Date().toISOString()
            }
        };

        formData.append('pinataMetadata', JSON.stringify(metadata));

        // 设置选项
        const pinataOptions = {
            cidVersion: 1,
            ...options.pinataOptions
        };
        formData.append('pinataOptions', JSON.stringify(pinataOptions));

        // 创建 XMLHttpRequest 以支持进度回调
        return new Promise((resolve, reject) => {
            const xhr = new XMLHttpRequest();

            // 设置进度监听
            if (onProgress) {
                xhr.upload.addEventListener('progress', (event) => {
                    if (event.lengthComputable) {
                        const percentComplete = (event.loaded / event.total) * 100;
                        onProgress(percentComplete);
                    }
                });
            }

            // 设置完成监听
            xhr.addEventListener('load', () => {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        
                        // 使用多网关逻辑获取最佳URL
                        getBestGatewayUrl(response.IpfsHash).then(bestUrl => {
                            resolve({
                                success: true,
                                ipfsHash: response.IpfsHash,
                                pinSize: response.PinSize,
                                timestamp: response.Timestamp,
                                url: bestUrl,
                                gatewayUrl: bestUrl,
                                allGatewayUrls: PINATA_CONFIG.GATEWAY_URLS.map(gateway => `${gateway}/${response.IpfsHash}`),
                                metadata: metadata
                            });
                        }).catch(error => {
                            // 如果获取最佳网关失败，使用默认网关
                            console.warn('获取最佳网关失败，使用默认网关:', error);
                            resolve({
                                success: true,
                                ipfsHash: response.IpfsHash,
                                pinSize: response.PinSize,
                                timestamp: response.Timestamp,
                                url: `${PINATA_CONFIG.GATEWAY_URL}/${response.IpfsHash}`,
                                gatewayUrl: `${PINATA_CONFIG.GATEWAY_URL}/${response.IpfsHash}`,
                                allGatewayUrls: PINATA_CONFIG.GATEWAY_URLS.map(gateway => `${gateway}/${response.IpfsHash}`),
                                metadata: metadata
                            });
                        });
                    } catch (error) {
                        reject(new Error('解析响应失败: ' + error.message));
                    }
                } else {
                    try {
                        const errorResponse = JSON.parse(xhr.responseText);
                        reject(new Error(errorResponse.error?.details || '上传失败'));
                    } catch {
                        reject(new Error(`上传失败: HTTP ${xhr.status}`));
                    }
                }
            });

            // 设置错误监听
            xhr.addEventListener('error', () => {
                reject(new Error('网络错误，请检查网络连接'));
            });

            // 设置超时监听
            xhr.addEventListener('timeout', () => {
                reject(new Error('上传超时，请重试'));
            });

            // 配置请求
            xhr.open('POST', `${PINATA_CONFIG.API_URL}/pinning/pinFileToIPFS`);
            xhr.timeout = 60000; // 60秒超时

            // 设置请求头
            const authHeaders = getPinataAuthHeaders();
            Object.keys(authHeaders).forEach(key => {
                xhr.setRequestHeader(key, authHeaders[key]);
            });

            // 发送请求
            xhr.send(formData);
        });

    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * 上传 JSON 数据到 IPFS (通过 Pinata)
 * @param {Object} jsonData - 要上传的 JSON 数据
 * @param {Object} options - 上传选项
 * @returns {Promise<Object>} 上传结果
 */
async function uploadJSONToIPFS(jsonData, options = {}) {
    const maxRetries = 3;
    const retryDelay = 2000; // 2秒
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            // 验证配置
            if (!validatePinataConfig()) {
                throw new Error('请先配置 Pinata API 密钥');
            }

            // 验证数据
            if (!jsonData || typeof jsonData !== 'object') {
                throw new Error('请提供有效的 JSON 数据');
            }

            // 准备请求数据
            const requestData = {
                pinataContent: jsonData,
                pinataMetadata: {
                    name: options.name || 'NFT Metadata',
                    keyvalues: {
                        ...PINATA_CONFIG.OPTIONS.DEFAULT_METADATA_OPTIONS.keyvalues,
                        ...options.keyvalues,
                        uploadTime: new Date().toISOString()
                    }
                },
                pinataOptions: {
                    cidVersion: 1,
                    ...options.pinataOptions
                }
            };

            // 创建带超时的 fetch 请求
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 60000); // 60秒超时

            try {
                // 发送请求
                const response = await fetch(`${PINATA_CONFIG.API_URL}/pinning/pinJSONToIPFS`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        ...getPinataAuthHeaders()
                    },
                    body: JSON.stringify(requestData),
                    signal: controller.signal
                });

                clearTimeout(timeoutId);

                if (response.ok) {
                    const result = await response.json();
                    
                    // 使用多网关逻辑获取最佳URL
                    const bestUrl = await getBestGatewayUrl(result.IpfsHash);
                    
                    return {
                        success: true,
                        ipfsHash: result.IpfsHash,
                        pinSize: result.PinSize,
                        timestamp: result.Timestamp,
                        url: bestUrl,
                        gatewayUrl: bestUrl,
                        allGatewayUrls: PINATA_CONFIG.GATEWAY_URLS.map(gateway => `${gateway}/${result.IpfsHash}`),
                        metadata: requestData.pinataMetadata
                    };
                } else {
                    const errorData = await response.json();
                    throw new Error(errorData.error?.details || `HTTP ${response.status}: 上传失败`);
                }
            } catch (error) {
                clearTimeout(timeoutId);
                
                if (error.name === 'AbortError') {
                    throw new Error('请求超时，请检查网络连接');
                }
                throw error;
            }

        } catch (error) {
            console.warn(`JSON上传尝试 ${attempt}/${maxRetries} 失败:`, error.message);
            
            // 如果是最后一次尝试或者是配置错误，直接返回失败
            if (attempt === maxRetries || error.message.includes('请先配置') || error.message.includes('请提供有效')) {
                return {
                    success: false,
                    error: error.message,
                    attempts: attempt
                };
            }
            
            // 等待后重试
            await new Promise(resolve => setTimeout(resolve, retryDelay * attempt));
        }
    }
}

/**
 * 生成 NFT 元数据
 * @param {Object} nftData - NFT 数据
 * @returns {Object} 标准的 NFT 元数据
 */
function generateNFTMetadata(nftData) {
    const {
        name,
        description,
        imageUrl,
        attributes = [],
        externalUrl = '',
        animationUrl = '',
        backgroundColor = ''
    } = nftData;

    const metadata = {
        name: name || 'Untitled NFT',
        description: description || 'A unique NFT created with our marketplace',
        image: imageUrl,
        external_url: externalUrl,
        attributes: attributes.map(attr => ({
            trait_type: attr.trait_type || attr.name,
            value: attr.value,
            ...(attr.display_type && { display_type: attr.display_type })
        }))
    };

    // 可选字段
    if (animationUrl) metadata.animation_url = animationUrl;
    if (backgroundColor) metadata.background_color = backgroundColor;

    // 添加创建时间戳
    metadata.attributes.push({
        trait_type: 'Created',
        value: new Date().toISOString(),
        display_type: 'date'
    });

    return metadata;
}

/**
 * 完整的 NFT 创建流程：上传图片 -> 生成元数据 -> 上传元数据
 * @param {File} imageFile - 图片文件
 * @param {Object} nftData - NFT 数据
 * @param {Function} onProgress - 进度回调
 * @returns {Promise<Object>} 创建结果
 */
async function createNFTWithIPFS(imageFile, nftData, onProgress = null) {
    try {
        const totalSteps = 3;
        let currentStep = 0;

        const updateProgress = (stepProgress) => {
            if (onProgress) {
                const totalProgress = (currentStep / totalSteps) * 100 + (stepProgress / totalSteps);
                onProgress(Math.min(totalProgress, 100), getCurrentStepName(currentStep));
            }
        };

        const getCurrentStepName = (step) => {
            const steps = ['上传图片到 IPFS', '生成元数据', '上传元数据到 IPFS'];
            return steps[step] || '处理中';
        };

        // 步骤 1: 上传图片
        updateProgress(0);
        const imageUploadResult = await uploadFileToIPFS(
            imageFile,
            {
                name: `${nftData.name || 'NFT'} - Image`,
                keyvalues: {
                    type: 'nft-image',
                    nftName: nftData.name || 'Untitled'
                }
            },
            (progress) => updateProgress(progress)
        );

        if (!imageUploadResult.success) {
            throw new Error('图片上传失败: ' + imageUploadResult.error);
        }

        currentStep = 1;
        updateProgress(0);

        // 步骤 2: 生成元数据
        const metadata = generateNFTMetadata({
            ...nftData,
            imageUrl: imageUploadResult.url
        });

        currentStep = 2;
        updateProgress(50);

        // 步骤 3: 上传元数据
        const metadataUploadResult = await uploadJSONToIPFS(metadata, {
            name: `${nftData.name || 'NFT'} - Metadata`,
            keyvalues: {
                type: 'nft-metadata',
                nftName: nftData.name || 'Untitled'
            }
        });

        if (!metadataUploadResult.success) {
            throw new Error('元数据上传失败: ' + metadataUploadResult.error);
        }

        updateProgress(100);

        return {
            success: true,
            imageHash: imageUploadResult.ipfsHash,
            imageUrl: imageUploadResult.url,
            metadataHash: metadataUploadResult.ipfsHash,
            metadataUrl: metadataUploadResult.url,
            metadata: metadata
        };

    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * 获取用户的 Pinata 使用情况
 * @returns {Promise<Object>} 使用情况数据
 */
async function getPinataUsage() {
    try {
        if (!validatePinataConfig()) {
            throw new Error('请先配置 Pinata API 密钥');
        }

        const response = await fetch(`${PINATA_CONFIG.API_URL}/data/userPinnedDataTotal`, {
            method: 'GET',
            headers: getPinataAuthHeaders()
        });

        if (response.ok) {
            const data = await response.json();
            return {
                success: true,
                pinCount: data.pin_count,
                pinSizeTotal: data.pin_size_total,
                pinSizeWithReplicationsTotal: data.pin_size_with_replications_total
            };
        } else {
            throw new Error('获取使用情况失败');
        }
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * 删除 IPFS 上的文件 (通过 Pinata)
 * @param {string} ipfsHash - IPFS 哈希
 * @returns {Promise<Object>} 删除结果
 */
async function unpinFromIPFS(ipfsHash) {
    try {
        if (!validatePinataConfig()) {
            throw new Error('请先配置 Pinata API 密钥');
        }

        const response = await fetch(`${PINATA_CONFIG.API_URL}/pinning/unpin/${ipfsHash}`, {
            method: 'DELETE',
            headers: getPinataAuthHeaders()
        });

        if (response.ok) {
            return {
                success: true,
                message: '文件已从 IPFS 移除'
            };
        } else {
            const errorData = await response.json();
            throw new Error(errorData.error || '移除失败');
        }
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
}

// 导出函数
if (typeof module !== 'undefined' && module.exports) {
    // Node.js 环境
    module.exports = {
        uploadFileToIPFS,
        uploadJSONToIPFS,
        generateNFTMetadata,
        createNFTWithIPFS,
        getPinataUsage,
        unpinFromIPFS
    };
} else {
    // 浏览器环境
    window.uploadFileToIPFS = uploadFileToIPFS;
    window.uploadJSONToIPFS = uploadJSONToIPFS;
    window.generateNFTMetadata = generateNFTMetadata;
    window.createNFTWithIPFS = createNFTWithIPFS;
    window.getPinataUsage = getPinataUsage;
    window.unpinFromIPFS = unpinFromIPFS;
}