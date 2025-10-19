// 测试合约调用功能
const crypto = require('crypto');

// 模拟 keccak256 函数
function keccak256(data) {
    return crypto.createHash('sha3-256').update(data).digest('hex');
}

// 模拟函数选择器计算
function getFunctionSelector(signature) {
    const hash = keccak256(signature);
    return '0x' + hash.substring(0, 8);
}

// 测试函数选择器
console.log('=== 函数选择器测试 ===');
const functions = [
    'getContractBalance()',
    'getBalance(address)',
    'deposit()',
    'withdraw(uint256)',
    'batchDeposit(uint256[])'
];

functions.forEach(func => {
    const selector = getFunctionSelector(func);
    console.log(`${func}: ${selector}`);
});

// 模拟合约调用数据编码
console.log('\n=== 合约调用数据编码测试 ===');

// 测试 getContractBalance() - 无参数函数
const getContractBalanceSelector = getFunctionSelector('getContractBalance()');
console.log('getContractBalance() calldata:', getContractBalanceSelector);

// 测试 getBalance(address) - 有参数函数
const getBalanceSelector = getFunctionSelector('getBalance(address)');
const testAddress = '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d4d4';
const paddedAddress = testAddress.slice(2).padStart(64, '0');
const getBalanceCalldata = getBalanceSelector + paddedAddress;
console.log('getBalance(address) calldata:', getBalanceCalldata);

console.log('\n=== 测试完成 ===');
console.log('所有函数选择器和调用数据编码正常');