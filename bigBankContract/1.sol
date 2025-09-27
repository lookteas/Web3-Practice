pragma solidity ^0.8.9;
interface IBank {
    function deposit() external payable;
    function getTopDepositors() external view returns (address[3] memory, uint[3] memory);
    function withdraw() external;
}

//这里的Bank还是昨天的Bank合约，但满足Bank实现IBank的要求
contract Bank is IBank{
    address public admin; 
    mapping(address => uint) public deposits;
    
    // 存储存款金额前3名的地址
    address[3] public topDepositors;

    uint8 private constant TOP_COUNT = 3;
    
    constructor() {
        //构造函数执行的时候指定部署合约的人就是管理员
        admin = msg.sender;
    }
    
    // 接收ETH并记录存款
    receive() external payable virtual { 
        _handleDeposit();
    }
    
    // 存款函数，允许用户显式调用存款
    function deposit() external payable virtual {
        _handleDeposit();
    }
    
    function _handleDeposit() internal {
        // 更新用户存款金额
        deposits[msg.sender] += msg.value;
        updateTopDepositors(msg.sender);
    }
    
    // 更新前3名存款人
    function updateTopDepositors(address depositor) internal {
        uint depositorBalance = deposits[depositor];
        
        // 如果存款人已经在前3名中，直接更新排序
        for (uint8 i = 0; i < TOP_COUNT; i++) {
            if (topDepositors[i] == depositor) {
                _updateRanking();
                return;
            }
        }
        
        // 检查是否应该加入前3名
        for (uint8 i = 0; i < TOP_COUNT; i++) {
            address currentAddr = topDepositors[i];
            // 如果位置为空或者新存款人的存款金额大于当前位置的存款金额
            if (currentAddr == address(0) || depositorBalance > deposits[currentAddr]) {
                // 将新存款人插入到当前位置，并将其他存款人向后移动
                for (uint8 j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j-1];
                }
                topDepositors[i] = depositor;
                break;
            }
        }
    }
    
    function _updateRanking() internal {
        for (uint8 i = 1; i < TOP_COUNT; i++) {
            address key = topDepositors[i];
            if (key == address(0)) continue; // 跳过空地址
            
            uint keyDeposit = deposits[key];
            int8 j = int8(i) - 1;
            
            while (j >= 0 && (topDepositors[uint8(j)] == address(0) || deposits[topDepositors[uint8(j)]] < keyDeposit)) {
                topDepositors[uint8(j + 1)] = topDepositors[uint8(j)];
                j--;
            }
            
            topDepositors[uint8(j + 1)] = key;
        }
    }
    
    // 获取前3名存款人及其存款金额
    function getTopDepositors() external view returns (address[3] memory, uint[3] memory) {
        uint[3] memory amounts;
        for (uint8 i = 0; i < TOP_COUNT; i++) {
            amounts[i] = deposits[topDepositors[i]];
        }
        return (topDepositors, amounts);
    }
    
    // 只有管理员可以提取所有ETH
    function withdraw() external {
        // 检查调用者是否为管理员
        require(msg.sender == admin, "Only admin can withdraw");
        
        // 获取合约余额
        uint balance = address(this).balance;
        
        // 确保有余额可提取
        require(balance > 0, "No balance to withdraw");
        
        // 将所有ETH转给管理员
        (bool success, ) = admin.call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}

contract BigBank is Bank {
    address public immutable owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    // 函数修改器modifier要求存款金额大于0.001 ether才能存款
    modifier depositAmountGreaterThan001() {
        require(msg.value > 0.001 ether, "Deposit amount must be greater than 0.001 ether");
        _;
    }
    // 显式转账需要满足条件
    function deposit() external payable override depositAmountGreaterThan001 {
        _handleDeposit();
    }

    // 直接转账也需要满足条件
    receive() external payable override {
        require(msg.value > 0.001 ether, "Deposit amount must be greater than 0.001 ether");
        _handleDeposit();
    }

    // 实现BigBank 合约支持转移管理员的功能
    function changeAdmin(address newAdmin) external {
        require(msg.sender == owner, "Only owner can change admin");
        require(newAdmin != address(0), "New admin cannot be zero address");
        admin = newAdmin;
    }
}

contract Admin {
    address public immutable admin;
    
    constructor() {
        admin = msg.sender;
    }
    
    // 添加receive函数以接收ETH
    receive() external payable {}
    
    // 修改adminWithdraw函数，确保Bank合约的admin是Admin合约地址
    function adminWithdraw(IBank bank) external {
        require(msg.sender == admin, "Only admin can withdraw");
        bank.withdraw();
    }
    
    // 添加函数让Admin合约的admin可以提取合约中的ETH
    function withdrawToOwner() external {
        require(msg.sender == admin, "Only admin can withdraw");
        uint balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = admin.call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}