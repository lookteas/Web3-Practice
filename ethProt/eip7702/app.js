// ============================================
// Viem 导入 - 使用本地安装的包 (v2.39.0+)
// ============================================
import { 
    createWalletClient, 
    createPublicClient,
    custom,
    http,
    parseEther,
    formatEther,
    encodeFunctionData,
    getAddress
} from 'viem';

import { sepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

// EIP-7702 专用功能
import { 
    prepareAuthorization,
    signAuthorization 
} from 'viem/experimental';

// ============================================
// 全局变量
// ============================================
window.walletClient = null;
window.publicClient = null;
window.account = null;

// 合约地址（Sepolia 测试网）
window.DELEGATE_CONTRACT_ADDRESS = '0xb9a31c2697b5DdAF00ce55B7323c9358b4A68175';
window.TOKEN_BANK_ADDRESS = '0x23343331C3ff07974c28ECC69cE5a2Fe525910Da';

// 合约 ABI
window.DELEGATE_ABI = [
    {
        "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
        "name": "getNonce",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "address[]", "name": "targets", "type": "address[]"},
            {"internalType": "uint256[]", "name": "values", "type": "uint256[]"},
            {"internalType": "bytes[]", "name": "calldatas", "type": "bytes[]"},
            {"internalType": "uint256", "name": "expectedNonce", "type": "uint256"}
        ],
        "name": "batchExecute",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "anonymous": false,
        "inputs": [
            {"indexed": true, "internalType": "address", "name": "user", "type": "address"},
            {"indexed": false, "internalType": "uint256", "name": "nonce", "type": "uint256"},
            {"indexed": false, "internalType": "uint256", "name": "executedCount", "type": "uint256"}
        ],
        "name": "BatchExecuted",
        "type": "event"
    }
];

window.TOKEN_BANK_ABI = [
    {
        "inputs": [],
        "name": "deposit",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "address", "name": "user", "type": "address"}],
        "name": "getBalance",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getContractBalance",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getUserCount",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "name": "userList",
        "outputs": [{"internalType": "address", "name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "address[]", "name": "users", "type": "address[]"},
            {"internalType": "uint256[]", "name": "amounts", "type": "uint256[]"}
        ],
        "name": "batchDeposit",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "anonymous": false,
        "inputs": [
            {"indexed": true, "internalType": "address", "name": "user", "type": "address"},
            {"indexed": false, "internalType": "uint256", "name": "amount", "type": "uint256"},
            {"indexed": false, "internalType": "uint256", "name": "newBalance", "type": "uint256"}
        ],
        "name": "Deposit",
        "type": "event"
    }
];

// ============================================
// 初始化客户端
// ============================================
async function initClients() {
    try {
        if (!window.ethereum) {
            throw new Error('请安装 MetaMask');
        }

        // 创建 Public Client（用于读取）
        // 从 .env 文件读取 SEPOLIA_RPC_URL
        let rpcUrl = null;
        try {
            rpcUrl = __SEPOLIA_RPC_URL__;
        } catch (e) {
            console.error('❌ 无法读取 __SEPOLIA_RPC_URL__:', e.message);
        }
        
        console.log('='.repeat(60));
        console.log('📋 RPC 配置信息:');
        console.log('  读取到的 RPC URL:', rpcUrl);
        console.log('='.repeat(60));
        
        if (!rpcUrl || rpcUrl === 'undefined') {
            const errorMsg = '❌ 请在 .env 文件中配置 SEPOLIA_RPC_URL，然后重启 Vite 服务器\n' +
                           '提示：.env 文件应该在项目根目录，格式为：\n' +
                           'SEPOLIA_RPC_URL=https://your-rpc-url';
            console.error(errorMsg);
            throw new Error(errorMsg);
        }
        
        window.publicClient = createPublicClient({
            chain: sepolia,
            transport: http(rpcUrl)
        });

        console.log('✅ Viem 客户端初始化成功');
        return true;
    } catch (error) {
        console.error('❌ 初始化客户端失败:', error);
        showStatus('connectionStatus', '初始化失败: ' + error.message, 'error');
        return false;
    }
}

// ============================================
// 连接钱包（仅使用 MetaMask，用于 ERC-5792）
// ============================================
window.connectWallet = async function() {
    try {
        // 强制使用 MetaMask（因为 wallet_sendCalls 需要 MetaMask）
        console.log('🦊 使用 MetaMask 模式（ERC-5792 要求）');
        
        if (!window.ethereum) {
            throw new Error('请安装 MetaMask');
        }

        // 请求账户访问
        const accounts = await window.ethereum.request({
            method: 'eth_requestAccounts'
        });

        if (!accounts || accounts.length === 0) {
            throw new Error('未获取到账户');
        }

        // 创建 Wallet Client（用于签名和发送交易）
        window.walletClient = createWalletClient({
            account: accounts[0],
            chain: sepolia,
            transport: custom(window.ethereum)
        });

        window.account = {
            address: getAddress(accounts[0])
        };

        // 更新 UI
        document.getElementById('currentAccount').textContent = window.account.address;
        showStatus('connectionStatus', '✅ MetaMask 连接成功！', 'success');

        // 检查网络
        const chainId = await window.ethereum.request({ method: 'eth_chainId' });
        console.log('当前网络 chainId:', chainId);
        
        if (chainId !== '0xaa36a7') { // Sepolia chainId
            showStatus('connectionStatus', '⚠️ 请切换到 Sepolia 测试网', 'error');
            return;
        }

        console.log('✅ MetaMask 连接成功:', window.account.address);

        // 自动检查授权状态
        setTimeout(() => checkDelegation(), 1000);

    } catch (error) {
        console.error('❌ 连接钱包失败:', error);
        showStatus('connectionStatus', '连接失败: ' + error.message, 'error');
    }
};

// ============================================
// 工具函数
// ============================================
window.showStatus = function(elementId, message, type) {
    const element = document.getElementById(elementId);
    if (element) {
        element.textContent = message;
        element.className = `status ${type}`;
        element.style.display = 'block';
        
        if (type === 'success') {
            setTimeout(() => {
                element.style.display = 'none';
            }, 5000);
        }
    }
};

// ============================================
// EIP-7702 授权功能
// ============================================

// 检查 EOA 是否已设置代码（授权状态）
window.checkDelegation = async function() {
    try {
        if (!window.publicClient || !window.account) {
            throw new Error('请先连接钱包');
        }

        showStatus('authorizationStatus', '正在检查授权状态...', 'info');

        // 获取 EOA 的字节码
        const code = await window.publicClient.getCode({
            address: window.account.address
        });

        console.log('EOA 字节码:', code);

        // EIP-7702 设置的代码会有特殊的前缀
        const isDelegated = code && code !== '0x' && code.length > 2;

        // 更新 UI（如果元素存在）
        const authStatusEl = document.getElementById('authStatus');
        if (authStatusEl) {
            authStatusEl.textContent = isDelegated ? '✅ 已授权' : '⭕ 未授权';
        }
        
        const delegatedToEl = document.getElementById('delegatedTo');
        if (delegatedToEl) {
            delegatedToEl.textContent = isDelegated ? window.DELEGATE_CONTRACT_ADDRESS : '-';
        }

        if (isDelegated) {
            console.log('✅ EOA 已授权给 DelegateContract');
        } else {
            console.log('⭕ EOA 尚未授权');
        }

        return isDelegated;
    } catch (error) {
        console.error('❌ 检查授权失败:', error);
        showStatus('authorizationStatus', '检查失败: ' + error.message, 'error');
        return false;
    }
};

// 准备 EIP-7702 授权对象（不签名，在交易时由 MetaMask 处理）
async function prepareAuthorizationForContract() {
    try {
        if (!window.walletClient || !window.account) {
            throw new Error('请先连接钱包');
        }

        console.log('📝 准备 EIP-7702 授权对象...');
        console.log('代理合约地址:', window.DELEGATE_CONTRACT_ADDRESS);
        console.log('EOA 地址:', window.account.address);
        console.log('WalletClient 配置:', {
            chain: window.walletClient.chain,
            transport: window.walletClient.transport
        });
        
        // 使用 prepareAuthorization 准备授权对象
        // 参考: https://viem.sh/docs/eip7702/prepareAuthorization
        const authorization = await prepareAuthorization(window.walletClient, {
            contractAddress: window.DELEGATE_CONTRACT_ADDRESS,
        });

        console.log('✅ 授权对象准备完成:', authorization);
        return authorization;
    } catch (error) {
        console.error('❌ 准备授权失败:', error);
        throw error;
    }
}

// 撤销授权（发送空授权列表的交易）
window.revokeAuthorization = async function() {
    try {
        if (!window.walletClient || !window.account) {
            throw new Error('请先连接钱包');
        }

        showStatus('advancedStatus', '正在撤销授权...', 'info');

        // 发送带空授权列表的交易来撤销
        const hash = await window.walletClient.sendTransaction({
            account: window.account.address,
            to: window.account.address,
            authorizationList: [], // 空列表撤销授权
            data: '0x',
            value: 0n
        });

        console.log('撤销授权交易已发送:', hash);
        showStatus('advancedStatus', '⏳ 等待交易确认...', 'info');

        // 等待交易确认
        const receipt = await window.publicClient.waitForTransactionReceipt({ hash });
        
        if (receipt.status === 'success') {
            showStatus('advancedStatus', '✅ 授权已撤销！', 'success');
            document.getElementById('authStatus').textContent = '⭕ 未授权';
            document.getElementById('delegatedTo').textContent = '-';
        } else {
            throw new Error('交易失败');
        }

        return hash;
    } catch (error) {
        console.error('❌ 撤销授权失败:', error);
        showStatus('advancedStatus', '撤销失败: ' + error.message, 'error');
    }
};

// 查看 EOA 字节码
window.viewAccountCode = async function() {
    try {
        if (!window.publicClient || !window.account) {
            throw new Error('请先连接钱包');
        }

        const code = await window.publicClient.getCode({
            address: window.account.address
        });

        const codeInfo = code && code !== '0x' ? 
            `字节码长度: ${code.length} 字符\n\n${code}` : 
            '无字节码（普通 EOA）';

        alert('EOA 字节码信息:\n\n' + codeInfo);
        console.log('EOA 字节码:', code);
    } catch (error) {
        console.error('❌ 查看字节码失败:', error);
        showStatus('advancedStatus', '查看失败: ' + error.message, 'error');
    }
};

// ============================================
// 存款功能
// ============================================

// 一键存款（自动处理授权）
window.oneClickDeposit = async function() {
    try {
        if (!window.walletClient || !window.account) {
            throw new Error('请先连接钱包');
        }

        const amountInput = document.getElementById('depositAmount').value;
        if (!amountInput || parseFloat(amountInput) <= 0) {
            throw new Error('请输入有效的存款金额');
        }

        const amount = parseEther(amountInput);
        showStatus('depositStatus', '⏳ 正在处理存款...', 'info');

        // 1. 准备 EIP-7702 授权
        console.log('📝 步骤 1: 准备授权...');
        const authorization = await prepareAuthorizationForContract();

        // 2. 构建 deposit 的 calldata
        const depositCalldata = encodeFunctionData({
            abi: window.TOKEN_BANK_ABI,
            functionName: 'deposit',
            args: []
        });

        // 3. 发送 EIP-7702 交易
        // 参考: https://viem.sh/docs/eip7702/sending-transactions
        console.log('🚀 步骤 2: 发送 EIP-7702 交易...');
        
        // 直接使用 EIP-7702 - MetaMask 和 Viem 2.39.0 已完全支持
        const hash = await window.walletClient.sendTransaction({
            account: window.walletClient.account,
            to: window.TOKEN_BANK_ADDRESS,  // 直接调用 TokenBank
            authorizationList: [authorization],
            data: depositCalldata,
            value: amount
        });

        console.log('✅ 交易已发送:', hash);
        showStatus('depositStatus', `⏳ 交易已发送，等待确认...\n交易哈希: ${hash.slice(0, 10)}...`, 'info');

        // 6. 等待交易确认
        const receipt = await window.publicClient.waitForTransactionReceipt({ hash });
        
        if (receipt.status === 'success') {
            showStatus('depositStatus', 
                `✅ 存款成功！\n金额: ${amountInput} ETH\n交易哈希: ${hash}`, 'success');
            document.getElementById('depositAmount').value = '';
            
            // 更新授权状态和余额
            setTimeout(() => {
                checkDelegation();
                queryMyBalance();
            }, 2000);
        } else {
            throw new Error('交易失败');
        }

        return hash;
    } catch (error) {
        console.error('❌ 存款失败:', error);
        showStatus('depositStatus', '存款失败: ' + error.message, 'error');
    }
};

// 批量存款 - 使用 ERC-5792 wallet_sendCalls
window.batchDeposit = async function() {
    try {
        if (!window.account) {
            throw new Error('请先连接钱包');
        }

        const amountsInput = document.getElementById('batchDepositAmounts')?.value;
        if (!amountsInput) {
            showStatus('batchStatus', '请输入存款金额列表', 'error');
            return;
        }

        const amounts = amountsInput.split(',')
            .map(a => a.trim())
            .filter(a => a && parseFloat(a) > 0);

        if (amounts.length === 0) {
            throw new Error('请输入有效的存款金额列表');
        }

        showStatus('batchStatus', '⏳ 正在处理批量存款...', 'info');

        // 获取当前网络的 chainId
        const currentChainId = await window.ethereum.request({ method: 'eth_chainId' });
        
        // 构建多个 deposit 调用
        const calls = amounts.map(amount => {
            const depositCalldata = encodeFunctionData({
                abi: window.TOKEN_BANK_ABI,
                functionName: 'deposit',
                args: []
            });
            
            return {
                to: window.TOKEN_BANK_ADDRESS,
                value: `0x${parseEther(amount).toString(16)}`,
                data: depositCalldata
            };
        });

        console.log('🚀 使用 wallet_sendCalls 发送批量交易...', calls);
        
        // 使用 ERC-5792 wallet_sendCalls
        const result = await window.ethereum.request({
            method: 'wallet_sendCalls',
            params: [{
                version: '2.0.0',
                chainId: currentChainId,
                from: window.account.address,
                atomicRequired: true,
                calls: calls
            }]
        });

        console.log('✅ 批量交易已提交:', result);
        showStatus('batchStatus', `⏳ 批量交易已发送，等待确认...`, 'info');

        // 轮询交易状态
        const checkStatus = setInterval(async () => {
            try {
                const status = await window.ethereum.request({
                    method: 'wallet_getCallsStatus',
                    params: [result.id]
                });
                
                console.log('批量交易状态:', status);
                
                if (status.status === 200 || status.status === 'CONFIRMED') {
                    clearInterval(checkStatus);
                    
                    const totalValue = amounts.reduce((sum, val) => sum + parseEther(val), 0n);
                    
                    if (status.receipts && status.receipts[0]) {
                        const txHash = status.receipts[0].transactionHash;
                        showStatus('batchStatus', 
                            `✅ 批量存款成功！\n存款次数: ${amounts.length}\n总金额: ${formatEther(totalValue)} ETH\n交易哈希: ${txHash}`, 
                            'success');
                    } else {
                        showStatus('batchStatus', 
                            `✅ 批量存款成功！\n存款次数: ${amounts.length}\n总金额: ${formatEther(totalValue)} ETH`, 
                            'success');
                    }
                    
                    document.getElementById('batchDepositAmounts').value = '';
                    setTimeout(() => queryBalance(), 2000);
                } else if (status.status === 100) {
                    console.log('⏳ 批量交易处理中...');
                }
            } catch (err) {
                console.error('查询批量交易状态失败:', err);
            }
        }, 1000);
        
    } catch (error) {
        console.error('❌ 批量存款失败:', error);
        showStatus('batchStatus', '批量存款失败: ' + error.message, 'error');
    }
};

// ============================================
// 余额查询功能
// ============================================

// 查询我的余额（EOA 在 TokenBank 中的余额）
window.queryMyBalance = async function() {
    try {
        if (!window.publicClient || !window.account) {
            throw new Error('请先连接钱包');
        }

        showStatus('queryStatus', '正在查询余额...', 'info');

        // 查询 EOA 地址在 TokenBank 中的余额
        const balance = await window.publicClient.readContract({
            address: window.TOKEN_BANK_ADDRESS,
            abi: window.TOKEN_BANK_ABI,
            functionName: 'getBalance',
            args: [window.account.address]  // 重要：查询 EOA 地址，不是 DelegateContract
        });

        const balanceEth = formatEther(balance);
        const balanceElement = document.getElementById('balanceResult');
        if (balanceElement) {
            balanceElement.textContent = `${balanceEth} ETH`;
        }
        showStatus('queryStatus', `✅ 余额查询成功: ${balanceEth} ETH`, 'success');

        console.log('我的余额:', balanceEth, 'ETH');
        return balance;
    } catch (error) {
        console.error('❌ 查询余额失败:', error);
        showStatus('queryStatus', '查询失败: ' + error.message, 'error');
    }
};

// 查询合约总余额
window.queryContractBalance = async function() {
    try {
        if (!window.publicClient) {
            throw new Error('请先初始化客户端');
        }

        showStatus('queryStatus', '正在查询合约总余额...', 'info');

        const balance = await window.publicClient.readContract({
            address: window.TOKEN_BANK_ADDRESS,
            abi: window.TOKEN_BANK_ABI,
            functionName: 'getContractBalance',
            args: []
        });

        const balanceEth = formatEther(balance);
        const balanceElement = document.getElementById('contractBalanceResult');
        if (balanceElement) {
            balanceElement.textContent = `${balanceEth} ETH`;
        }
        showStatus('queryStatus', `✅ 合约总余额: ${balanceEth} ETH`, 'success');

        console.log('合约总余额:', balanceEth, 'ETH');
        return balance;
    } catch (error) {
        console.error('❌ 查询合约余额失败:', error);
        showStatus('queryStatus', '查询失败: ' + error.message, 'error');
    }
};

// ============================================
// 存款排行榜功能
// ============================================

// 加载存款排行榜
window.loadLeaderboard = async function() {
    try {
        if (!window.publicClient || !window.TOKEN_BANK_ADDRESS) {
            throw new Error('请先初始化客户端并设置合约地址');
        }

        showStatus('leaderboardStatus', '⏳ 正在加载排行榜...', 'info');

        // 1. 获取用户总数
        const userCount = await window.publicClient.readContract({
            address: window.TOKEN_BANK_ADDRESS,
            abi: window.TOKEN_BANK_ABI,
            functionName: 'getUserCount',
            args: []
        });

        console.log('👥 用户总数:', userCount.toString());

        if (userCount === 0n) {
            const leaderboardContent = document.getElementById('leaderboardContent');
            leaderboardContent.innerHTML = '<p style="text-align: center; color: #6c757d;">暂无存款记录</p>';
            showStatus('leaderboardStatus', '暂无存款记录', 'info');
            return;
        }

        // 2. 获取所有用户地址并查询余额
        const userBalances = [];
        
        for (let i = 0; i < Number(userCount); i++) {
            try {
                // 获取用户地址
                const userAddress = await window.publicClient.readContract({
                    address: window.TOKEN_BANK_ADDRESS,
                    abi: window.TOKEN_BANK_ABI,
                    functionName: 'userList',
                    args: [BigInt(i)]
                });

                // 获取用户余额
                const balance = await window.publicClient.readContract({
                    address: window.TOKEN_BANK_ADDRESS,
                    abi: window.TOKEN_BANK_ABI,
                    functionName: 'getBalance',
                    args: [userAddress]
                });
                
                // 只统计余额大于 0 的用户
                if (balance > 0n) {
                    userBalances.push({ address: userAddress, balance });
                    console.log(`💰 用户 ${userAddress}: ${formatEther(balance)} ETH`);
                }
            } catch (err) {
                console.warn(`查询用户 #${i} 失败:`, err);
            }
        }

        // 4. 按余额降序排序
        const sortedUsers = userBalances.sort((a, b) => {
            if (a.balance > b.balance) return -1;
            if (a.balance < b.balance) return 1;
            return 0;
        });

        // 5. 取前三名
        const top3 = sortedUsers.slice(0, 3);

        console.log('🏆 排行榜 Top 3:', top3);

        // 6. 渲染排行榜
        const leaderboardContent = document.getElementById('leaderboardContent');
        
        if (top3.length === 0) {
            leaderboardContent.innerHTML = '<p style="text-align: center; color: #6c757d;">暂无存款记录</p>';
            showStatus('leaderboardStatus', '暂无存款记录', 'info');
            return;
        }

        const rankEmojis = ['🥇', '🥈', '🥉'];
        const rankClasses = ['rank-1', 'rank-2', 'rank-3'];
        
        leaderboardContent.innerHTML = top3.map((user, index) => `
            <div class="leaderboard-item ${rankClasses[index]}">
                <div class="rank-badge">${rankEmojis[index]}</div>
                <div class="user-info">
                    <div class="user-address">${user.address}</div>
                    <div class="user-balance">${formatEther(user.balance)} ETH</div>
                </div>
            </div>
        `).join('');

        showStatus('leaderboardStatus', `✅ 排行榜加载成功！共 ${sortedUsers.length} 位用户有余额`, 'success');

    } catch (error) {
        console.error('❌ 加载排行榜失败:', error);
        showStatus('leaderboardStatus', '加载失败: ' + error.message, 'error');
        document.getElementById('leaderboardContent').innerHTML = 
            '<p style="text-align: center; color: #dc3545;">加载失败，请重试</p>';
    }
};

// ============================================
// 页面加载时初始化
// ============================================
window.addEventListener('load', async () => {
    console.log('🚀 EIP-7702 Viem Demo 加载中...');
    console.log('🔍 环境变量检查:');
    try {
        console.log('  __SEPOLIA_RPC_URL__ 值:', __SEPOLIA_RPC_URL__);
    } catch (e) {
        console.error('  ❌ __SEPOLIA_RPC_URL__ 未定义!', e.message);
    }
    await initClients();
    
    // 绑定事件监听器
    setupEventListeners();
    
    // 如果已经连接，自动获取账户
    if (window.ethereum && window.ethereum.selectedAddress) {
        await connectWallet();
    }
});

// 设置事件监听器
function setupEventListeners() {
    // 连接钱包按钮
    const connectBtn = document.getElementById('connectWalletBtn');
    if (connectBtn) {
        connectBtn.addEventListener('click', () => window.connectWallet());
    }
}

// 暴露给全局作用域
window.parseEther = parseEther;
window.formatEther = formatEther;
window.encodeFunctionData = encodeFunctionData;
window.getAddress = getAddress;

// ============================================
// HTML 中调用的辅助函数
// ============================================

// 设置合约地址
window.setContractAddresses = function() {
    const delegateAddr = document.getElementById('delegateAddress')?.value;
    const tokenBankAddr = document.getElementById('tokenBankAddress')?.value;
    
    if (delegateAddr) {
        window.DELEGATE_CONTRACT_ADDRESS = delegateAddr;
    }
    if (tokenBankAddr) {
        window.TOKEN_BANK_ADDRESS = tokenBankAddr;
    }
    
    showStatus('contractStatus', '✅ 合约地址已更新', 'success');
};

// 获取当前 nonce
window.getCurrentNonce = async function() {
    try {
        if (!window.publicClient || !window.account) {
            throw new Error('请先连接钱包');
        }
        
        const nonce = await window.publicClient.readContract({
            address: window.DELEGATE_CONTRACT_ADDRESS,
            abi: window.DELEGATE_ABI,
            functionName: 'getNonce',
            args: [window.account.address]
        });
        
        document.getElementById('currentNonce').textContent = nonce.toString();
        showStatus('nonceStatus', `✅ 当前 Nonce: ${nonce}`, 'success');
    } catch (error) {
        console.error('❌ 获取 nonce 失败:', error);
        showStatus('nonceStatus', '获取失败: ' + error.message, 'error');
    }
};

// 设置代理合约
window.setDelegateContract = function() {
    const address = document.getElementById('delegateContract')?.value;
    if (address) {
        window.DELEGATE_CONTRACT_ADDRESS = address;
        showStatus('authStatus', '✅ 代理合约地址已设置', 'success');
    }
};

// 检查账户代码
window.checkAccountCode = async function(address) {
    try {
        if (!window.publicClient) {
            throw new Error('请先初始化客户端');
        }
        
        if (!address) {
            address = window.account?.address;
        }
        
        if (!address) {
            throw new Error('请提供账户地址');
        }
        
        const code = await window.publicClient.getCode({ address });
        const hasCode = code && code !== '0x';
        
        document.getElementById('accountCodeStatus').textContent = 
            hasCode ? '✅ 已设置代码' : '⭕ 无代码';
        
        showStatus('authStatus', 
            hasCode ? '账户已设置代码（已授权）' : '账户无代码（未授权）', 
            hasCode ? 'success' : 'info');
    } catch (error) {
        console.error('❌ 检查账户代码失败:', error);
        showStatus('authStatus', '检查失败: ' + error.message, 'error');
    }
};

// 发送授权交易（演示）
window.sendAuthorizationTransaction = async function() {
    try {
        showStatus('authStatus', '⏳ 正在准备授权...', 'info');
        
        const authorization = await prepareAuthorizationForContract();
        
        showStatus('authStatus', '✅ 授权准备成功！可以开始存款操作', 'success');
        
        // 自动检查代码状态
        setTimeout(() => checkAccountCode(window.account.address), 1000);
    } catch (error) {
        console.error('❌ 授权失败:', error);
        showStatus('authStatus', '授权失败: ' + error.message, 'error');
    }
};

// 单次存款 - 使用 ERC-5792 wallet_sendCalls
window.singleDeposit = async function() {
    const amountInput = document.getElementById('singleDepositAmount')?.value;
    if (!amountInput) {
        showStatus('depositStatus', '请输入存款金额', 'error');
        return;
    }
    
    try {
        if (!window.account) {
            throw new Error('请先连接钱包');
        }

        const amount = parseEther(amountInput);
        showStatus('depositStatus', '⏳ 正在处理存款...', 'info');

        // 构建 deposit 的 calldata
        const depositCalldata = encodeFunctionData({
            abi: window.TOKEN_BANK_ABI,
            functionName: 'deposit',
            args: []
        });

        console.log('🚀 使用 wallet_sendCalls 发送交易...');
        
        // 获取当前网络的 chainId
        const currentChainId = await window.ethereum.request({ method: 'eth_chainId' });
        console.log('当前网络 chainId:', currentChainId);
        
        // 使用 ERC-5792 wallet_sendCalls（MetaMask 官方方式）
        const result = await window.ethereum.request({
            method: 'wallet_sendCalls',
            params: [{
                version: '2.0.0', // MetaMask 要求 2.0.0
                chainId: currentChainId, // 使用当前连接的网络
                from: window.account.address,
                atomicRequired: true, // 要求原子执行， EIP-7702 的核心特性之一
                calls: [{
                    to: window.TOKEN_BANK_ADDRESS,
                    value: `0x${amount.toString(16)}`,
                    data: depositCalldata
                }]
            }]
        });

        console.log('✅ 交易已提交:', result);
        showStatus('depositStatus', `⏳ 交易已发送，等待确认...`, 'info');

        // 轮询交易状态
        const checkStatus = setInterval(async () => {
            try {
                const status = await window.ethereum.request({
                    method: 'wallet_getCallsStatus',
                    params: [result.id]  // 传递字符串 ID，不是整个对象
                });
                
                console.log('交易状态:', status);
                
                // 检查交易是否完成
                // status.status 可能是 200 (成功) 或 100 (处理中)
                if (status.status === 200 || status.status === 'CONFIRMED') {
                    clearInterval(checkStatus);
                    
                    if (status.receipts && status.receipts[0]) {
                        const txHash = status.receipts[0].transactionHash;
                        showStatus('depositStatus', 
                            `✅ 存款成功！\n金额: ${amountInput} ETH\n交易哈希: ${txHash}`, 'success');
                    } else {
                        showStatus('depositStatus', '✅ 交易已确认！', 'success');
                    }
                    
                    document.getElementById('singleDepositAmount').value = '';
                    setTimeout(() => queryBalance(), 2000);
                } else if (status.status === 100) {
                    console.log('⏳ 交易处理中...');
                }
            } catch (err) {
                console.error('查询状态失败:', err);
            }
        }, 1000);
        
    } catch (error) {
        console.error('❌ 存款失败:', error);
        showStatus('depositStatus', '存款失败: ' + error.message, 'error');
    }
};

// 查询余额（映射到 queryMyBalance）
window.queryBalance = window.queryMyBalance;
