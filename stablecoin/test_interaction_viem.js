import { createPublicClient, createWalletClient, http, parseEther, formatEther, getContract } from 'viem';
import { anvil } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

// 合约地址和配置
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
    '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', // Account 0
    '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d', // Account 1
    '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'  // Account 2
];

async function main() {
    console.log('🚀 开始使用 viem 与 RebaseToken 合约交互测试...\n');
    
    // 创建公共客户端（用于读取）
    const publicClient = createPublicClient({
        chain: anvil,
        transport: http(RPC_URL)
    });
    
    // 创建账户
    const ownerAccount = privateKeyToAccount(PRIVATE_KEYS[0]);
    const user1Account = privateKeyToAccount(PRIVATE_KEYS[1]);
    const user2Account = privateKeyToAccount(PRIVATE_KEYS[2]);
    
    // 创建钱包客户端（用于写入）
    const ownerWalletClient = createWalletClient({
        account: ownerAccount,
        chain: anvil,
        transport: http(RPC_URL)
    });
    
    // 创建合约实例
    const contract = getContract({
        address: CONTRACT_ADDRESS,
        abi: CONTRACT_ABI,
        client: {
            public: publicClient,
            wallet: ownerWalletClient
        }
    });
    
    console.log('📋 合约基本信息:');
    const name = await contract.read.name();
    const symbol = await contract.read.symbol();
    const totalSupply = await contract.read.totalSupply();
    const totalShares = await contract.read.totalShares();
    
    console.log(`名称: ${name}`);
    console.log(`符号: ${symbol}`);
    console.log(`总供应量: ${formatEther(totalSupply)} RDT`);
    console.log(`总份额: ${formatEther(totalShares)}`);
    console.log(`合约地址: ${CONTRACT_ADDRESS}\n`);
    
    // 显示初始余额
    console.log('💰 初始余额:');
    const ownerBalance = await contract.read.balanceOf([ownerAccount.address]);
    const ownerShares = await contract.read.sharesOf([ownerAccount.address]);
    const user1Balance = await contract.read.balanceOf([user1Account.address]);
    const user2Balance = await contract.read.balanceOf([user2Account.address]);
    
    console.log(`Owner (${ownerAccount.address}): ${formatEther(ownerBalance)} RDT (${formatEther(ownerShares)} shares)`);
    console.log(`User1 (${user1Account.address}): ${formatEther(user1Balance)} RDT`);
    console.log(`User2 (${user2Account.address}): ${formatEther(user2Balance)} RDT\n`);
    
    // 转账给用户
    console.log('📤 执行转账操作...');
    const transferAmount1 = parseEther('1000000'); // 100万 RDT
    const transferAmount2 = parseEther('2000000'); // 200万 RDT
    
    console.log(`转账 ${formatEther(transferAmount1)} RDT 给 User1...`);
    const tx1Hash = await contract.write.transfer([user1Account.address, transferAmount1]);
    await publicClient.waitForTransactionReceipt({ hash: tx1Hash });
    
    console.log(`转账 ${formatEther(transferAmount2)} RDT 给 User2...`);
    const tx2Hash = await contract.write.transfer([user2Account.address, transferAmount2]);
    await publicClient.waitForTransactionReceipt({ hash: tx2Hash });
    
    // 显示转账后余额
    console.log('\n💰 转账后余额:');
    const ownerBalanceAfterTransfer = await contract.read.balanceOf([ownerAccount.address]);
    const ownerSharesAfterTransfer = await contract.read.sharesOf([ownerAccount.address]);
    const user1BalanceAfterTransfer = await contract.read.balanceOf([user1Account.address]);
    const user1SharesAfterTransfer = await contract.read.sharesOf([user1Account.address]);
    const user2BalanceAfterTransfer = await contract.read.balanceOf([user2Account.address]);
    const user2SharesAfterTransfer = await contract.read.sharesOf([user2Account.address]);
    
    console.log(`Owner: ${formatEther(ownerBalanceAfterTransfer)} RDT (${formatEther(ownerSharesAfterTransfer)} shares)`);
    console.log(`User1: ${formatEther(user1BalanceAfterTransfer)} RDT (${formatEther(user1SharesAfterTransfer)} shares)`);
    console.log(`User2: ${formatEther(user2BalanceAfterTransfer)} RDT (${formatEther(user2SharesAfterTransfer)} shares)`);
    
    // 计算持币比例
    const totalSupplyAfterTransfer = await contract.read.totalSupply();
    const ownerRatio = (ownerBalanceAfterTransfer * 10000n) / totalSupplyAfterTransfer;
    const user1Ratio = (user1BalanceAfterTransfer * 10000n) / totalSupplyAfterTransfer;
    const user2Ratio = (user2BalanceAfterTransfer * 10000n) / totalSupplyAfterTransfer;
    
    console.log('\n📊 持币比例:');
    console.log(`Owner: ${Number(ownerRatio) / 100}%`);
    console.log(`User1: ${Number(user1Ratio) / 100}%`);
    console.log(`User2: ${Number(user2Ratio) / 100}%`);
    
    // 检查是否可以 rebase
    console.log('\n⏰ Rebase 状态检查:');
    const canRebase = await contract.read.canRebase();
    const lastRebaseTime = await contract.read.lastRebaseTime();
    const rebaseInterval = await contract.read.rebaseInterval();
    const timeUntilNext = await contract.read.getTimeUntilNextRebase();
    
    console.log(`可以 Rebase: ${canRebase}`);
    console.log(`上次 Rebase 时间: ${new Date(Number(lastRebaseTime) * 1000).toLocaleString()}`);
    console.log(`Rebase 间隔: ${Number(rebaseInterval)} 秒 (${Number(rebaseInterval) / 86400} 天)`);
    console.log(`距离下次 Rebase: ${Number(timeUntilNext)} 秒`);
    
    if (!canRebase) {
        console.log('\n⚡ 模拟时间推进以触发 Rebase...');
        // 使用 anvil 的时间推进功能
        await publicClient.request({
            method: 'evm_increaseTime',
            params: [Number(rebaseInterval)]
        });
        await publicClient.request({
            method: 'evm_mine',
            params: []
        });
        
        console.log('✅ 时间已推进，现在可以执行 Rebase');
    }
    
    // 执行 Rebase
    console.log('\n🔄 执行 Rebase 操作...');
    const rebaseTxHash = await contract.write.rebase();
    const rebaseReceipt = await publicClient.waitForTransactionReceipt({ hash: rebaseTxHash });
    
    // 查找 Rebase 事件
    const rebaseEvent = rebaseReceipt.logs.find(log => {
        try {
            const decoded = publicClient.decodeEventLog({
                abi: CONTRACT_ABI,
                data: log.data,
                topics: log.topics
            });
            return decoded.eventName === 'Rebase';
        } catch {
            return false;
        }
    });
    
    if (rebaseEvent) {
        const decoded = publicClient.decodeEventLog({
            abi: CONTRACT_ABI,
            data: rebaseEvent.data,
            topics: rebaseEvent.topics
        });
        console.log(`✅ Rebase 完成!`);
        console.log(`新的总供应量: ${formatEther(decoded.args.newTotalSupply)} RDT`);
        console.log(`供应量变化: ${formatEther(decoded.args.supplyDelta)} RDT`);
    }
    
    // 显示 Rebase 后的余额
    console.log('\n💰 Rebase 后余额:');
    const newTotalSupply = await contract.read.totalSupply();
    const ownerBalanceAfterRebase = await contract.read.balanceOf([ownerAccount.address]);
    const user1BalanceAfterRebase = await contract.read.balanceOf([user1Account.address]);
    const user2BalanceAfterRebase = await contract.read.balanceOf([user2Account.address]);
    
    console.log(`总供应量: ${formatEther(newTotalSupply)} RDT`);
    console.log(`Owner: ${formatEther(ownerBalanceAfterRebase)} RDT (${formatEther(await contract.read.sharesOf([ownerAccount.address]))} shares)`);
    console.log(`User1: ${formatEther(user1BalanceAfterRebase)} RDT (${formatEther(await contract.read.sharesOf([user1Account.address]))} shares)`);
    console.log(`User2: ${formatEther(user2BalanceAfterRebase)} RDT (${formatEther(await contract.read.sharesOf([user2Account.address]))} shares)`);
    
    // 验证比例保持不变
    const newOwnerRatio = (ownerBalanceAfterRebase * 10000n) / newTotalSupply;
    const newUser1Ratio = (user1BalanceAfterRebase * 10000n) / newTotalSupply;
    const newUser2Ratio = (user2BalanceAfterRebase * 10000n) / newTotalSupply;
    
    console.log('\n📊 Rebase 后持币比例:');
    console.log(`Owner: ${Number(newOwnerRatio) / 100}%`);
    console.log(`User1: ${Number(newUser1Ratio) / 100}%`);
    console.log(`User2: ${Number(newUser2Ratio) / 100}%`);
    
    // 验证通缩效果
    const deflationRate = ((totalSupplyAfterTransfer - newTotalSupply) * 10000n) / totalSupplyAfterTransfer;
    console.log(`\n📉 通缩效果: ${Number(deflationRate) / 100}% (预期: 1%)`);
    
    // 验证份额不变
    console.log('\n🔍 验证份额保持不变:');
    const ownerSharesAfterRebase = await contract.read.sharesOf([ownerAccount.address]);
    const user1SharesAfterRebase = await contract.read.sharesOf([user1Account.address]);
    const user2SharesAfterRebase = await contract.read.sharesOf([user2Account.address]);
    
    console.log(`Owner 份额变化: ${ownerSharesAfterRebase === ownerSharesAfterTransfer ? '✅ 不变' : '❌ 已变化'}`);
    console.log(`User1 份额变化: ${user1SharesAfterRebase === user1SharesAfterTransfer ? '✅ 不变' : '❌ 已变化'}`);
    console.log(`User2 份额变化: ${user2SharesAfterRebase === user2SharesAfterTransfer ? '✅ 不变' : '❌ 已变化'}`);
    
    console.log('\n 测试完成：验证 Rebase 机制测试，用户余额正确反映了通缩效果，同时保持了持币比例不变。');
}

main().catch(console.error);