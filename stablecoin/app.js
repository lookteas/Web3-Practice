// 使用 CDN 导入 viem 库（浏览器兼容）
import { createPublicClient, createWalletClient, http, parseEther, formatEther, getContract } from 'https://esm.sh/viem@2.21.19';
import { anvil } from 'https://esm.sh/viem@2.21.19/chains';
import { privateKeyToAccount } from 'https://esm.sh/viem@2.21.19/accounts';

// 合约配置
const CONTRACT_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
const RPC_URL = 'http://localhost:8545';

// 合约 ABI
const CONTRACT_ABI = [
    {
        "type": "function",
        "name": "name",
        "inputs": [],
        "outputs": [{"type": "string", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "symbol",
        "inputs": [],
        "outputs": [{"type": "string", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "totalSupply",
        "inputs": [],
        "outputs": [{"type": "uint256", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "balanceOf",
        "inputs": [{"type": "address", "name": "account"}],
        "outputs": [{"type": "uint256", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "sharesOf",
        "inputs": [{"type": "address", "name": "account"}],
        "outputs": [{"type": "uint256", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "totalShares",
        "inputs": [],
        "outputs": [{"type": "uint256", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "transfer",
        "inputs": [
            {"type": "address", "name": "to"},
            {"type": "uint256", "name": "amount"}
        ],
        "outputs": [{"type": "bool", "name": ""}],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "rebase",
        "inputs": [],
        "outputs": [{"type": "uint256", "name": ""}],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "canRebase",
        "inputs": [],
        "outputs": [{"type": "bool", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "lastRebaseTime",
        "inputs": [],
        "outputs": [{"type": "uint256", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "rebaseInterval",
        "inputs": [],
        "outputs": [{"type": "uint256", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getTimeUntilNextRebase",
        "inputs": [],
        "outputs": [{"type": "uint256", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "owner",
        "inputs": [],
        "outputs": [{"type": "address", "name": ""}],
        "stateMutability": "view"
    },
    {
        "type": "event",
        "name": "Transfer",
        "inputs": [
            {"type": "address", "name": "from", "indexed": true},
            {"type": "address", "name": "to", "indexed": true},
            {"type": "uint256", "name": "value", "indexed": false}
        ]
    },
    {
        "type": "event",
        "name": "Rebase",
        "inputs": [
            {"type": "uint256", "name": "newTotalSupply", "indexed": false},
            {"type": "int256", "name": "supplyDelta", "indexed": false}
        ]
    }
];

// Anvil 测试账户私钥
const PRIVATE_KEYS = [
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', // Account 0 (Owner)
    '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d', // Account 1
    '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'  // Account 2
];

// 全局变量
let publicClient;
let accounts = [];
let walletClients = [];
let contract;
let autoScrollEnabled = true;
let currentTimeInterval; // 用于存储当前时间更新的定时器

// 初始化应用
async function initializeApp() {
    try {
        addLog('info', '正在初始化应用...');
        
        // 创建公共客户端
        publicClient = createPublicClient({
            chain: anvil,
            transport: http(RPC_URL)
        });
        
        // 创建账户
        accounts = PRIVATE_KEYS.map(privateKey => privateKeyToAccount(privateKey));
        
        // 创建钱包客户端
        walletClients = accounts.map(account => createWalletClient({
            account,
            chain: anvil,
            transport: http(RPC_URL)
        }));
        
        // 创建合约实例
        contract = getContract({
            address: CONTRACT_ADDRESS,
            abi: CONTRACT_ABI,
            client: {
                public: publicClient,
                wallet: walletClients[0] // 默认使用第一个账户
            }
        });
        
        // 更新 UI
        updateNetworkStatus('已连接');
        updateContractAddress(CONTRACT_ADDRESS);
        updateAccountAddresses();
        
        // 加载合约信息
        await loadContractInfo();
        await loadBalances();
        await updateRebaseStatus();
        
        // 启动实时时间更新
        startRealTimeUpdate();
        
        addLog('success', '应用初始化完成！');
        
    } catch (error) {
        addLog('error', `初始化失败: ${error.message}`);
        updateNetworkStatus('连接失败');
    }
}

// 加载合约基本信息
async function loadContractInfo() {
    try {
        addLog('info', '正在加载合约信息...');
        
        const [name, symbol, totalSupply, owner, lastRebaseTime, rebaseInterval] = await Promise.all([
            contract.read.name(),
            contract.read.symbol(),
            contract.read.totalSupply(),
            contract.read.owner(),
            contract.read.lastRebaseTime(),
            contract.read.rebaseInterval()
        ]);
        
        document.getElementById('token-name').textContent = name;
        document.getElementById('token-symbol').textContent = symbol;
        document.getElementById('total-supply').textContent = `${formatEther(totalSupply)} RDT`;
        document.getElementById('owner').textContent = owner;
        document.getElementById('last-rebase').textContent = new Date(Number(lastRebaseTime) * 1000).toLocaleString();
        document.getElementById('rebase-interval').textContent = `${Number(rebaseInterval)} 秒`;
        
        addLog('success', '合约信息加载完成');
        
    } catch (error) {
        addLog('error', `加载合约信息失败: ${error.message}`);
    }
}

// 加载账户余额
async function loadBalances() {
    try {
        addLog('info', '正在加载账户余额...');
        
        for (let i = 0; i < accounts.length; i++) {
            const address = accounts[i].address;
            const [balance, shares] = await Promise.all([
                contract.read.balanceOf([address]),
                contract.read.sharesOf([address])
            ]);
            
            document.getElementById(`account${i + 1}-balance`).textContent = `${formatEther(balance)} RDT`;
            document.getElementById(`account${i + 1}-shares`).textContent = formatEther(shares);
        }
        
        addLog('success', '账户余额加载完成');
        
    } catch (error) {
        addLog('error', `加载账户余额失败: ${error.message}`);
    }
}

// 更新网络状态
function updateNetworkStatus(status) {
    const element = document.getElementById('network-status');
    element.textContent = status;
    element.className = 'status-value ' + (status === '已连接' ? 'success' : 'error');
}

// 更新合约地址
function updateContractAddress(address) {
    document.getElementById('contract-address').textContent = address;
}

// 更新账户地址显示
function updateAccountAddresses() {
    for (let i = 0; i < accounts.length; i++) {
        document.getElementById(`account${i + 1}-address`).textContent = accounts[i].address;
    }
}

// 模拟时间推进
async function simulateTimeProgress() {
    try {
        addLog('info', '正在模拟时间推进...');
        
        const rebaseInterval = await contract.read.rebaseInterval();
        
        await publicClient.request({
            method: 'evm_increaseTime',
            params: [Number(rebaseInterval)]
        });
        
        await publicClient.request({
            method: 'evm_mine',
            params: []
        });
        
        addLog('success', `时间已推进 ${Number(rebaseInterval)} 秒`);
        await updateRebaseStatus();
        
    } catch (error) {
        addLog('error', `时间推进失败: ${error.message}`);
    }
}

// 更新 Rebase 状态
// 启动实时时间更新
function startRealTimeUpdate() {
    // 清除之前的定时器（如果存在）
    if (currentTimeInterval) {
        clearInterval(currentTimeInterval);
    }
    
    // 立即更新一次当前时间
    updateCurrentTime();
    
    // 每秒更新当前时间
    currentTimeInterval = setInterval(updateCurrentTime, 1000);
}

// 更新当前时间显示
function updateCurrentTime() {
    const currentTimeElement = document.getElementById('current-time');
    if (currentTimeElement) {
        const now = new Date();
        currentTimeElement.textContent = now.toLocaleString('zh-CN');
    }
}

async function updateRebaseStatus() {
    try {
        console.log('开始更新 Rebase 状态...');
        
        const [canRebase, timeUntilNext, lastRebaseTime, rebaseInterval] = await Promise.all([
            contract.read.canRebase(),
            contract.read.getTimeUntilNextRebase(),
            contract.read.lastRebaseTime(),
            contract.read.rebaseInterval()
        ]);
        
        console.log('合约数据:', { canRebase, timeUntilNext, lastRebaseTime, rebaseInterval });
        
        const statusElement = document.getElementById('rebase-status');
        const timeElement = document.getElementById('time-until-rebase');
        const currentTimeElement = document.getElementById('current-time');
        const nextRebaseTimeElement = document.getElementById('next-rebase-time');
        
        console.log('DOM 元素:', { 
            statusElement, 
            timeElement, 
            currentTimeElement, 
            nextRebaseTimeElement 
        });
        
        // 更新当前时间（不再在这里更新，因为有实时更新）
        // const now = new Date();
        // if (currentTimeElement) {
        //     currentTimeElement.textContent = now.toLocaleString('zh-CN');
        //     console.log('已更新当前时间:', now.toLocaleString('zh-CN'));
        // } else {
        //     console.error('找不到 current-time 元素');
        // }
        
        // 计算下次 Rebase 时间
        const lastRebaseTimestamp = Number(lastRebaseTime) * 1000; // 转换为毫秒
        const intervalMs = Number(rebaseInterval) * 1000; // 转换为毫秒
        const nextRebaseTimestamp = lastRebaseTimestamp + intervalMs;
        const nextRebaseDate = new Date(nextRebaseTimestamp);
        
        if (nextRebaseTimeElement) {
            nextRebaseTimeElement.textContent = nextRebaseDate.toLocaleString('zh-CN');
            console.log('已更新下次 Rebase 时间:', nextRebaseDate.toLocaleString('zh-CN'));
        } else {
            console.error('找不到 next-rebase-time 元素');
        }
        
        if (canRebase) {
            statusElement.textContent = '可以执行';
            statusElement.className = 'status-ready';
            timeElement.textContent = '0 秒';
        } else {
            statusElement.textContent = '等待中';
            statusElement.className = 'status-waiting';
            timeElement.textContent = `${timeUntilNext} 秒`;
        }
        
        console.log('Rebase 状态更新完成');
    } catch (error) {
        console.error('更新 Rebase 状态失败:', error);
    }
}

// 添加日志
function addLog(type, message) {
    const logContent = document.getElementById('log-content');
    const timestamp = new Date().toLocaleTimeString();
    
    const logEntry = document.createElement('div');
    logEntry.className = `log-entry ${type}`;
    logEntry.innerHTML = `
        <span class="timestamp">[${timestamp}]</span>
        <span class="message">${message}</span>
    `;
    
    logContent.appendChild(logEntry);
    
    // 自动滚动到底部
    if (autoScrollEnabled) {
        logContent.scrollTop = logContent.scrollHeight;
    }
}

// 清空日志
function clearLog() {
    document.getElementById('log-content').innerHTML = '';
    addLog('info', '日志已清空');
}

// 切换自动滚动
function toggleAutoScroll() {
    autoScrollEnabled = !autoScrollEnabled;
    const button = document.getElementById('auto-scroll');
    button.classList.toggle('active', autoScrollEnabled);
    button.textContent = autoScrollEnabled ? '📜 自动滚动' : '📜 手动滚动';
}

// 监听合约事件
async function startEventListening() {
    try {
        addLog('info', '开始监听合约事件...');
        
        // 监听 Transfer 事件
        const transferUnwatch = publicClient.watchContractEvent({
            address: CONTRACT_ADDRESS,
            abi: CONTRACT_ABI,
            eventName: 'Transfer',
            onLogs: (logs) => {
                logs.forEach(log => {
                    const { from, to, value } = log.args;
                    addLog('info', `🔄 转账事件: ${formatEther(value)} RDT 从 ${from} 到 ${to}`);
                    // 自动刷新余额
                    setTimeout(loadBalances, 1000);
                });
            }
        });
        
        // 监听 Rebase 事件
        const rebaseUnwatch = publicClient.watchContractEvent({
            address: CONTRACT_ADDRESS,
            abi: CONTRACT_ABI,
            eventName: 'Rebase',
            onLogs: (logs) => {
                logs.forEach(log => {
                    const { newTotalSupply, supplyDelta } = log.args;
                    addLog('success', `⚡ Rebase 事件: 新总供应量 ${formatEther(newTotalSupply)} RDT，变化 ${formatEther(supplyDelta)} RDT`);
                    // 自动刷新所有信息
                    setTimeout(() => {
                        loadContractInfo();
                        loadBalances();
                        updateRebaseStatus();
                    }, 1000);
                });
            }
        });
        
        addLog('success', '事件监听已启动');
        
        // 返回取消监听的函数
        return () => {
            transferUnwatch();
            rebaseUnwatch();
            addLog('info', '事件监听已停止');
        };
        
    } catch (error) {
        addLog('error', `启动事件监听失败: ${error.message}`);
        return null;
    }
}

// 添加加载状态管理
function setLoading(elementId, isLoading) {
    const element = document.getElementById(elementId);
    if (isLoading) {
        element.disabled = true;
        const originalText = element.textContent;
        element.dataset.originalText = originalText;
        element.innerHTML = '<div class="loading"></div> 处理中...';
    } else {
        element.disabled = false;
        element.textContent = element.dataset.originalText || element.textContent;
    }
}

// 增强的转账函数
async function executeTransfer() {
    const transferButton = document.getElementById('execute-transfer');
    
    try {
        setLoading('execute-transfer', true);
        
        const fromIndex = parseInt(document.getElementById('from-account').value);
        const toIndex = parseInt(document.getElementById('to-account').value);
        const amount = document.getElementById('transfer-amount').value;
        
        if (!amount || amount <= 0) {
            addLog('error', '请输入有效的转账金额');
            return;
        }
        
        if (fromIndex === toIndex) {
            addLog('error', '不能向同一个账户转账');
            return;
        }
        
        // 检查余额是否足够
        const fromAddress = accounts[fromIndex].address;
        const currentBalance = await contract.read.balanceOf([fromAddress]);
        const transferAmount = parseEther(amount);
        
        if (currentBalance < transferAmount) {
            addLog('error', `余额不足！当前余额: ${formatEther(currentBalance)} RDT`);
            return;
        }
        
        const toAddress = accounts[toIndex].address;
        
        addLog('info', `正在从账户 ${fromIndex + 1} 向账户 ${toIndex + 1} 转账 ${amount} RDT...`);
        
        // 使用对应的钱包客户端
        const transferContract = getContract({
            address: CONTRACT_ADDRESS,
            abi: CONTRACT_ABI,
            client: {
                public: publicClient,
                wallet: walletClients[fromIndex]
            }
        });
        
        const txHash = await transferContract.write.transfer([toAddress, transferAmount]);
        addLog('info', `交易已提交，哈希: ${txHash}`);
        
        await publicClient.waitForTransactionReceipt({ hash: txHash });
        addLog('success', '转账成功！');
        
        // 清空表单
        document.getElementById('transfer-amount').value = '';
        
    } catch (error) {
        addLog('error', `转账失败: ${error.message}`);
    } finally {
        setLoading('execute-transfer', false);
    }
}

// 增强的 Rebase 函数
async function executeRebase() {
    try {
        setLoading('execute-rebase', true);
        
        addLog('info', '正在检查 Rebase 条件...');
        
        const canRebase = await contract.read.canRebase();
        if (!canRebase) {
            addLog('warning', '当前不能执行 Rebase，请先推进时间');
            return;
        }
        
        addLog('info', '正在执行 Rebase...');
        
        const txHash = await contract.write.rebase();
        addLog('info', `Rebase 交易已提交，哈希: ${txHash}`);
        
        const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
        addLog('success', 'Rebase 执行成功！');
        
    } catch (error) {
        addLog('error', `Rebase 失败: ${error.message}`);
    } finally {
        setLoading('execute-rebase', false);
    }
}



// 添加键盘快捷键支持
function setupKeyboardShortcuts() {
    document.addEventListener('keydown', (event) => {
        // Ctrl + R: 刷新余额
        if (event.ctrlKey && event.key === 'r') {
            event.preventDefault();
            loadBalances();
            addLog('info', '快捷键: 刷新余额');
        }
        
        // Ctrl + T: 聚焦到转账金额输入框
        if (event.ctrlKey && event.key === 't') {
            event.preventDefault();
            document.getElementById('transfer-amount').focus();
            addLog('info', '快捷键: 聚焦转账输入框');
        }
        
        // Ctrl + L: 清空日志
        if (event.ctrlKey && event.key === 'l') {
            event.preventDefault();
            clearLog();
        }
    });
}

// 添加网络连接检查
async function checkNetworkConnection() {
    try {
        const blockNumber = await publicClient.getBlockNumber();
        updateNetworkStatus('已连接');
        return true;
    } catch (error) {
        updateNetworkStatus('连接失败');
        addLog('error', `网络连接检查失败: ${error.message}`);
        return false;
    }
}

// 事件监听器
document.addEventListener('DOMContentLoaded', async () => {
    // 初始化应用
    await initializeApp();
    
    // 启动事件监听
    await startEventListening();
    
    // 设置键盘快捷键
    setupKeyboardShortcuts();
    
    // 绑定事件
    document.getElementById('refresh-info').addEventListener('click', async () => {
        setLoading('refresh-info', true);
        await loadContractInfo();
        setLoading('refresh-info', false);
    });
    
    document.getElementById('refresh-balances').addEventListener('click', async () => {
        setLoading('refresh-balances', true);
        await loadBalances();
        setLoading('refresh-balances', false);
    });
    
    document.getElementById('execute-transfer').addEventListener('click', executeTransfer);
    document.getElementById('simulate-time').addEventListener('click', simulateTimeProgress);
    document.getElementById('execute-rebase').addEventListener('click', executeRebase);
    document.getElementById('clear-log').addEventListener('click', clearLog);
    document.getElementById('auto-scroll').addEventListener('click', toggleAutoScroll);
    
    // 表单验证
    document.getElementById('transfer-amount').addEventListener('input', (event) => {
        const value = parseFloat(event.target.value);
        const button = document.getElementById('execute-transfer');
        button.disabled = !value || value <= 0;
    });
    
    // 定期更新状态
    setInterval(async () => {
        await updateRebaseStatus();
        await checkNetworkConnection();
    }, 10000); // 每10秒更新一次
    
    // 添加使用说明
    addLog('info', '💡 使用提示:');
    addLog('info', '• Ctrl+R: 刷新余额');
    addLog('info', '• Ctrl+T: 聚焦转账输入框');
    addLog('info', '• Ctrl+L: 清空日志');
    addLog('info', '• 页面会自动监听合约事件并更新数据');
});

// 导出函数供全局使用
window.app = {
    initializeApp,
    loadContractInfo,
    loadBalances,
    executeTransfer,
    simulateTimeProgress,
    executeRebase,
    clearLog,
    toggleAutoScroll,
    startRealTimeUpdate,
    updateCurrentTime
};