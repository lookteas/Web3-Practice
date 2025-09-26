// 部署和测试脚本
// 使用 Node.js 和 ethers.js 进行合约部署和交互测试

const { ethers } = require('ethers');
const fs = require('fs');

// 合约 ABI 和字节码（需要从编译后的合约中获取）
// 注意：实际使用时需要先编译合约获取 ABI 和 Bytecode

class ContractDeployer {
    constructor(providerUrl, privateKeys) {
        this.provider = new ethers.JsonRpcProvider(providerUrl);
        this.wallets = privateKeys.map(key => new ethers.Wallet(key, this.provider));
        this.deployer = this.wallets[0]; // 第一个钱包作为部署者
        this.users = this.wallets.slice(1); // 其他钱包作为用户
    }

    async deployContracts() {
        console.log('🚀 开始部署合约...');
        
        try {
            // 部署 BigBank 合约
            console.log('📦 部署 BigBank 合约...');
            const BigBankFactory = new ethers.ContractFactory(
                BIGBANK_ABI, 
                BIGBANK_BYTECODE, 
                this.deployer
            );
            this.bigBank = await BigBankFactory.deploy();
            await this.bigBank.waitForDeployment();
            console.log(`✅ BigBank 合约部署成功: ${await this.bigBank.getAddress()}`);

            // 部署 Admin 合约
            console.log('📦 部署 Admin 合约...');
            const AdminFactory = new ethers.ContractFactory(
                ADMIN_ABI, 
                ADMIN_BYTECODE, 
                this.deployer
            );
            this.admin = await AdminFactory.deploy();
            await this.admin.waitForDeployment();
            console.log(`✅ Admin 合约部署成功: ${await this.admin.getAddress()}`);

            // 转移 BigBank 的管理员权限给 Admin 合约
            console.log('🔄 转移 BigBank 管理员权限给 Admin 合约...');
            const transferTx = await this.bigBank.transferAdmin(await this.admin.getAddress());
            await transferTx.wait();
            console.log('✅ 管理员权限转移成功');

            return {
                bigBank: await this.bigBank.getAddress(),
                admin: await this.admin.getAddress()
            };
        } catch (error) {
            console.error('❌ 部署失败:', error);
            throw error;
        }
    }

    async simulateUserDeposits() {
        console.log('\n💰 模拟用户存款...');
        
        const deposits = [
            { user: 0, amount: '0.005' }, // 0.005 ETH
            { user: 1, amount: '0.01' },  // 0.01 ETH
            { user: 2, amount: '0.002' }, // 0.002 ETH
            { user: 0, amount: '0.003' }, // 用户0再次存款
        ];

        for (const deposit of deposits) {
            try {
                const userWallet = this.users[deposit.user];
                const bigBankWithUser = this.bigBank.connect(userWallet);
                
                console.log(`👤 用户 ${deposit.user + 1} (${userWallet.address}) 存款 ${deposit.amount} ETH...`);
                
                const tx = await bigBankWithUser.deposit({
                    value: ethers.parseEther(deposit.amount)
                });
                await tx.wait();
                
                console.log(`✅ 存款成功，交易哈希: ${tx.hash}`);
                
                // 查询用户存款余额
                const userBalance = await this.bigBank.getDeposit(userWallet.address);
                console.log(`💳 用户当前存款余额: ${ethers.formatEther(userBalance)} ETH`);
                
            } catch (error) {
                console.error(`❌ 用户 ${deposit.user + 1} 存款失败:`, error.message);
            }
        }
    }

    async checkContractStatus() {
        console.log('\n📊 检查合约状态...');
        
        // 检查 BigBank 余额
        const bankBalance = await this.bigBank.getContractBalance();
        console.log(`🏦 BigBank 合约余额: ${ethers.formatEther(bankBalance)} ETH`);
        
        // 检查前3名存款用户
        const [topDepositors, amounts] = await this.bigBank.getTopDepositorsWithAmounts();
        console.log('🏆 前3名存款用户:');
        for (let i = 0; i < 3; i++) {
            if (topDepositors[i] !== ethers.ZeroAddress) {
                console.log(`  ${i + 1}. ${topDepositors[i]}: ${ethers.formatEther(amounts[i])} ETH`);
            }
        }
        
        // 检查 Admin 合约余额
        const adminBalance = await this.admin.getContractBalance();
        console.log(`👑 Admin 合约余额: ${ethers.formatEther(adminBalance)} ETH`);
        
        // 检查 BigBank 的管理员
        const bankAdmin = await this.bigBank.admin();
        console.log(`🔑 BigBank 当前管理员: ${bankAdmin}`);
        console.log(`🔑 Admin 合约地址: ${await this.admin.getAddress()}`);
        console.log(`✅ 管理员权限转移${bankAdmin === await this.admin.getAddress() ? '成功' : '失败'}`);
    }

    async executeAdminWithdraw() {
        console.log('\n💸 执行管理员提取资金...');
        
        try {
            // Admin 合约的 owner 调用 adminWithdraw
            const adminWithOwner = this.admin.connect(this.deployer);
            
            console.log('🔄 Admin 合约 Owner 调用 adminWithdraw...');
            const withdrawTx = await adminWithOwner.adminWithdraw(await this.bigBank.getAddress());
            await withdrawTx.wait();
            
            console.log(`✅ 资金提取成功，交易哈希: ${withdrawTx.hash}`);
            
            // 检查提取后的状态
            await this.checkContractStatus();
            
        } catch (error) {
            console.error('❌ 管理员提取资金失败:', error.message);
        }
    }

    async runFullDemo() {
        console.log('🎬 开始完整演示流程...\n');
        
        try {
            // 1. 部署合约
            const addresses = await this.deployContracts();
            
            // 2. 模拟用户存款
            await this.simulateUserDeposits();
            
            // 3. 检查合约状态
            await this.checkContractStatus();
            
            // 4. 执行管理员提取
            await this.executeAdminWithdraw();
            
            console.log('\n🎉 演示完成！');
            console.log('📋 合约地址汇总:');
            console.log(`  BigBank: ${addresses.bigBank}`);
            console.log(`  Admin: ${addresses.admin}`);
            
        } catch (error) {
            console.error('❌ 演示过程中出现错误:', error);
        }
    }
}

// 配置信息（需要根据实际环境修改）
const CONFIG = {
    // 测试网络 RPC URL（例如 Sepolia）
    PROVIDER_URL: 'https://sepolia.infura.io/v3/YOUR_PROJECT_ID',
    
    // 测试私钥（请使用测试账户，不要使用真实资金）
    PRIVATE_KEYS: [
        '0x...', // 部署者/Admin Owner
        '0x...', // 用户1
        '0x...', // 用户2
        '0x...', // 用户3
    ]
};

// 合约 ABI 和 Bytecode 占位符
// 实际使用时需要从编译后的合约中获取
const BIGBANK_ABI = [
    // BigBank 合约 ABI
    // 需要从编译后的合约中复制
];

const BIGBANK_BYTECODE = "0x..."; // BigBank 合约字节码

const ADMIN_ABI = [
    // Admin 合约 ABI
    // 需要从编译后的合约中复制
];

const ADMIN_BYTECODE = "0x..."; // Admin 合约字节码

// 主函数
async function main() {
    if (CONFIG.PRIVATE_KEYS.some(key => key === '0x...')) {
        console.log('⚠️  请先配置正确的私钥和 RPC URL');
        console.log('📝 编辑 deploy.js 文件中的 CONFIG 对象');
        console.log('🔧 编译合约并复制 ABI 和 Bytecode');
        return;
    }
    
    const deployer = new ContractDeployer(CONFIG.PROVIDER_URL, CONFIG.PRIVATE_KEYS);
    await deployer.runFullDemo();
}

// 如果直接运行此脚本
if (require.main === module) {
    main().catch(console.error);
}

module.exports = { ContractDeployer };