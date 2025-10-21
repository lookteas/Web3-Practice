// 部署脚本 - deploy.js
// 使用 ethers.js 部署 AutomatedBank 合约

const { ethers } = require('ethers');
require('dotenv').config();

async function main() {
    // 配置网络和钱包
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL || 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY');
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    console.log('部署账户:', wallet.address);
    console.log('账户余额:', ethers.formatEther(await provider.getBalance(wallet.address)), 'ETH');
    
    // 合约 ABI 和字节码（需要编译后获取）
    const contractABI = [
        "constructor(uint256 _threshold)",
        "function deposit() external payable",
        "function withdraw(uint256 amount) external",
        "function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory)",
        "function performUpkeep(bytes calldata) external",
        "function updateThreshold(uint256 _newThreshold) external",
        "function getContractBalance() external view returns (uint256)",
        "function getUserBalance(address user) external view returns (uint256)",
        "function getUpkeepStatus() external view returns (bool, bool, bool, uint256, uint256, uint256)",
        "function totalDeposits() external view returns (uint256)",
        "function threshold() external view returns (uint256)",
        "function owner() external view returns (address)",
        "event Deposit(address indexed user, uint256 amount, uint256 newTotal)",
        "event AutoTransfer(uint256 amount, uint256 remainingBalance, uint256 timestamp)",
        "event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold)"
    ];
    
    // 设置阈值为 1 ETH (1000000000000000000 wei)
    const threshold = ethers.parseEther("1.0");
    
    try {
        console.log('开始部署合约...');
        console.log('阈值设置为:', ethers.formatEther(threshold), 'ETH');
        
        // 注意：这里需要合约的字节码，实际部署时需要先编译合约
        // 可以使用 Remix IDE 或 Hardhat 编译获取字节码
        console.log('请先使用 Remix IDE 编译 Bank.sol 合约获取字节码');
        console.log('然后将字节码添加到此脚本中');
        
        // 示例部署代码（需要实际字节码）
        /*
        const contractFactory = new ethers.ContractFactory(contractABI, bytecode, wallet);
        const contract = await contractFactory.deploy(threshold);
        await contract.waitForDeployment();
        
        console.log('合约部署成功!');
        console.log('合约地址:', await contract.getAddress());
        console.log('交易哈希:', contract.deploymentTransaction().hash);
        */
        
    } catch (error) {
        console.error('部署失败:', error);
    }
}

// 验证合约函数
async function verifyContract(contractAddress) {
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    const contractABI = [
        "function totalDeposits() external view returns (uint256)",
        "function threshold() external view returns (uint256)",
        "function owner() external view returns (address)",
        "function getContractBalance() external view returns (uint256)"
    ];
    
    const contract = new ethers.Contract(contractAddress, contractABI, wallet);
    
    try {
        console.log('验证合约状态...');
        console.log('合约所有者:', await contract.owner());
        console.log('当前阈值:', ethers.formatEther(await contract.threshold()), 'ETH');
        console.log('总存款:', ethers.formatEther(await contract.totalDeposits()), 'ETH');
        console.log('合约余额:', ethers.formatEther(await contract.getContractBalance()), 'ETH');
    } catch (error) {
        console.error('验证失败:', error);
    }
}

// 测试存款函数
async function testDeposit(contractAddress, amount) {
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    const contractABI = [
        "function deposit() external payable",
        "function getUserBalance(address user) external view returns (uint256)",
        "function totalDeposits() external view returns (uint256)"
    ];
    
    const contract = new ethers.Contract(contractAddress, contractABI, wallet);
    
    try {
        console.log(`测试存款 ${ethers.formatEther(amount)} ETH...`);
        
        const tx = await contract.deposit({ value: amount });
        await tx.wait();
        
        console.log('存款成功!');
        console.log('交易哈希:', tx.hash);
        console.log('用户余额:', ethers.formatEther(await contract.getUserBalance(wallet.address)), 'ETH');
        console.log('总存款:', ethers.formatEther(await contract.totalDeposits()), 'ETH');
    } catch (error) {
        console.error('存款失败:', error);
    }
}

// 检查 upkeep 状态
async function checkUpkeepStatus(contractAddress) {
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    const contractABI = [
        "function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory)",
        "function getUpkeepStatus() external view returns (bool, bool, bool, uint256, uint256, uint256)"
    ];
    
    const contract = new ethers.Contract(contractAddress, contractABI, wallet);
    
    try {
        console.log('检查 Upkeep 状态...');
        
        const [upkeepNeeded] = await contract.checkUpkeep("0x");
        const [thresholdMet, intervalMet, balanceSufficient, currentDeposits, currentThreshold, timeRemaining] = 
            await contract.getUpkeepStatus();
        
        console.log('需要执行 Upkeep:', upkeepNeeded);
        console.log('阈值满足:', thresholdMet);
        console.log('时间间隔满足:', intervalMet);
        console.log('余额充足:', balanceSufficient);
        console.log('当前存款:', ethers.formatEther(currentDeposits), 'ETH');
        console.log('阈值:', ethers.formatEther(currentThreshold), 'ETH');
        console.log('剩余等待时间:', timeRemaining.toString(), '秒');
        
    } catch (error) {
        console.error('检查失败:', error);
    }
}

// 导出函数供外部使用
module.exports = {
    main,
    verifyContract,
    testDeposit,
    checkUpkeepStatus
};

// 如果直接运行此脚本
if (require.main === module) {
    main().catch(console.error);
}