// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title AutomatedBank
 * @dev 一个支持 ChainLink Automation 的银行合约
 * 当存款超过指定阈值时，自动转移一半存款到 owner 地址
 */
contract AutomatedBank {
    // 状态变量
    address public owner;
    uint256 public totalDeposits;
    uint256 public threshold; // 触发自动转账的阈值
    uint256 public lastTransferTime;
    uint256 public constant MIN_INTERVAL = 1 hours; // 最小转账间隔
    
    // 用户存款映射
    mapping(address => uint256) public deposits;
    
    // 事件
    event Deposit(address indexed user, uint256 amount, uint256 newTotal);
    event AutoTransfer(uint256 amount, uint256 remainingBalance, uint256 timestamp);
    event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event Withdrawal(address indexed user, uint256 amount);
    
    // 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier validAmount() {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        _;
    }
    
    /**
     * @dev 构造函数
     * @param _threshold 触发自动转账的阈值（以 wei 为单位）
     */
    constructor(uint256 _threshold) {
        owner = msg.sender;
        threshold = _threshold;
        lastTransferTime = block.timestamp;
    }
    
    /**
     * @dev 用户存款函数
     */
    function deposit() external payable validAmount {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value, totalDeposits);
    }
    
    /**
     * @dev 用户提取自己的存款
     * @param amount 提取金额
     */
    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        require(address(this).balance >= amount, "Contract insufficient balance");
        
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;
        
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
    
    /**
     * @dev ChainLink Automation 检查函数
     * 检查是否需要执行自动转账
     * @return upkeepNeeded 是否需要执行维护
     * @return performData 执行数据（此处为空）
     */
    function checkUpkeep(bytes calldata /* checkData */) 
        external 
        view 
        returns (bool upkeepNeeded, bytes memory /* performData */) 
    {
        // 检查条件：
        // 1. 总存款超过阈值
        // 2. 距离上次转账已过最小间隔
        // 3. 合约有足够余额
        upkeepNeeded = (
            totalDeposits >= threshold &&
            (block.timestamp - lastTransferTime) >= MIN_INTERVAL &&
            address(this).balance >= totalDeposits / 2
        );
        
        return (upkeepNeeded, "");
    }
    
    /**
     * @dev ChainLink Automation 执行函数
     * 当条件满足时自动执行转账
     * @param performData 执行数据（此处未使用）
     */
    function performUpkeep(bytes calldata /* performData */) external {
        // 重新验证条件（安全最佳实践）
        bool upkeepNeeded = (
            totalDeposits >= threshold &&
            (block.timestamp - lastTransferTime) >= MIN_INTERVAL &&
            address(this).balance >= totalDeposits / 2
        );
        
        require(upkeepNeeded, "Upkeep conditions not met");
        
        // 计算转账金额（一半存款）
        uint256 transferAmount = totalDeposits / 2;
        
        // 更新状态
        totalDeposits -= transferAmount;
        lastTransferTime = block.timestamp;
        
        // 执行转账
        payable(owner).transfer(transferAmount);
        
        emit AutoTransfer(transferAmount, totalDeposits, block.timestamp);
    }
    
    /**
     * @dev 更新阈值（仅 owner）
     * @param _newThreshold 新的阈值
     */
    function updateThreshold(uint256 _newThreshold) external onlyOwner {
        uint256 oldThreshold = threshold;
        threshold = _newThreshold;
        emit ThresholdUpdated(oldThreshold, _newThreshold);
    }
    
    /**
     * @dev 获取合约余额
     * @return 合约当前余额
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev 获取用户存款余额
     * @param user 用户地址
     * @return 用户存款余额
     */
    function getUserBalance(address user) external view returns (uint256) {
        return deposits[user];
    }
    
    /**
     * @dev 获取距离下次可转账的时间
     * @return 剩余时间（秒）
     */
    function getTimeUntilNextTransfer() external view returns (uint256) {
        uint256 timePassed = block.timestamp - lastTransferTime;
        if (timePassed >= MIN_INTERVAL) {
            return 0;
        }
        return MIN_INTERVAL - timePassed;
    }
    
    /**
     * @dev 检查是否满足转账条件（用于前端显示）
     * @return 各项条件的检查结果
     */
    function getUpkeepStatus() external view returns (
        bool thresholdMet,
        bool intervalMet,
        bool balanceSufficient,
        uint256 currentDeposits,
        uint256 currentThreshold,
        uint256 timeRemaining
    ) {
        thresholdMet = totalDeposits >= threshold;
        intervalMet = (block.timestamp - lastTransferTime) >= MIN_INTERVAL;
        balanceSufficient = address(this).balance >= totalDeposits / 2;
        currentDeposits = totalDeposits;
        currentThreshold = threshold;
        
        uint256 timePassed = block.timestamp - lastTransferTime;
        timeRemaining = timePassed >= MIN_INTERVAL ? 0 : MIN_INTERVAL - timePassed;
    }
    
    /**
     * @dev 紧急提取函数（仅 owner，用于紧急情况）
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        payable(owner).transfer(balance);
    }
    
    /**
     * @dev 接收以太币的回退函数
     */
    receive() external payable {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value, totalDeposits);
    }
}