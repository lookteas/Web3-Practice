// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AutomatedBank
 * @dev 一个支持 ChainLink Automation 的银行合约
 * 当存款超过指定阈值时，自动转移一半存款到 owner 地址
 * 包含重入保护和改进的安全机制
 */
contract AutomatedBank is ReentrancyGuard {
    // 状态变量
    address public owner;
    uint256 public totalDeposits;
    uint256 public threshold; // 触发自动转账的阈值
    uint256 public lastTransferTime;
    uint256 public constant MIN_INTERVAL = 1 hours; // 最小转账间隔
    uint256 public constant MIN_TRANSFER_AMOUNT = 1000; // 最小转账金额，避免微小转账
    
    // 用户存款映射
    mapping(address => uint256) public deposits;
    
    // 事件
    event Deposit(address indexed user, uint256 amount, uint256 newTotal);
    event AutoTransfer(uint256 amount, uint256 remainingBalance, uint256 timestamp);
    event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event Withdrawal(address indexed user, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // 错误定义
    error InsufficientBalance();
    error TransferAmountTooSmall();
    error UpkeepConditionsNotMet();
    error ZeroAddressNotAllowed();
    error InvalidThreshold();
    
    // 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier validAmount() {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        _;
    }
    
    modifier notZeroAddress(address _address) {
        if (_address == address(0)) revert ZeroAddressNotAllowed();
        _;
    }
    
    /**
     * @dev 构造函数
     * @param _threshold 触发自动转账的阈值（以 wei 为单位）
     */
    constructor(uint256 _threshold) {
        if (_threshold == 0) revert InvalidThreshold();
        owner = msg.sender;
        threshold = _threshold;
        lastTransferTime = block.timestamp;
    }
    
    /**
     * @dev 用户存款函数
     */
    function deposit() external payable nonReentrant validAmount {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value, totalDeposits);
    }
    
    /**
     * @dev 用户提取自己的存款
     * @param amount 提取金额
     */
    function withdraw(uint256 amount) external nonReentrant {
        if (deposits[msg.sender] < amount) revert InsufficientBalance();
        if (address(this).balance < amount) revert InsufficientBalance();
        
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;
        
        // 使用 call 而不是 transfer，但配合重入保护
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    /**
     * @dev 内部维护条件检查函数
     * @return 是否满足执行条件
     */
    function _shouldPerformUpkeep() internal view returns (bool) {
        if (totalDeposits < threshold) return false;
        if ((block.timestamp - lastTransferTime) < MIN_INTERVAL) return false;
        
        uint256 transferAmount = totalDeposits / 2;
        if (transferAmount < MIN_TRANSFER_AMOUNT) return false;
        if (address(this).balance < transferAmount) return false;
        
        return true;
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
        upkeepNeeded = _shouldPerformUpkeep();
        return (upkeepNeeded, "");
    }
    
    /**
     * @dev ChainLink Automation 执行函数
     * 当条件满足时自动执行转账
     */
    function performUpkeep(bytes calldata) external nonReentrant {
        // 重新验证条件（安全最佳实践）
        if (!_shouldPerformUpkeep()) revert UpkeepConditionsNotMet();
        
        // 计算转账金额（一半存款）
        uint256 transferAmount = totalDeposits / 2;
        if (transferAmount < MIN_TRANSFER_AMOUNT) revert TransferAmountTooSmall();
        
        // 更新状态（在转账之前更新状态，遵循检查-效果-交互模式）
        totalDeposits -= transferAmount;
        lastTransferTime = block.timestamp;
        
        // 执行转账
        (bool success, ) = payable(owner).call{value: transferAmount}("");
        require(success, "Transfer to owner failed");
        
        emit AutoTransfer(transferAmount, totalDeposits, block.timestamp);
    }
    
    /**
     * @dev 更新阈值（仅 owner）
     * @param _newThreshold 新的阈值
     */
    function updateThreshold(uint256 _newThreshold) external onlyOwner {
        if (_newThreshold == 0) revert InvalidThreshold();
        
        uint256 oldThreshold = threshold;
        threshold = _newThreshold;
        emit ThresholdUpdated(oldThreshold, _newThreshold);
    }
    
    /**
     * @dev 转移合约所有权（仅 owner）
     * @param newOwner 新的所有者地址
     */
    function transferOwnership(address newOwner) external onlyOwner notZeroAddress(newOwner) {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
     * @return thresholdMet 阈值是否满足
     * @return intervalMet 时间间隔是否满足
     * @return balanceSufficient 余额是否充足
     * @return amountValid 金额是否有效
     * @return upkeepNeeded 是否需要执行维护
     * @return currentDeposits 当前存款总额
     * @return currentThreshold 当前阈值
     * @return timeRemaining 剩余时间
     * @return calculatedTransferAmount 计算的转账金额
     */
    function getUpkeepStatus() external view returns (
        bool thresholdMet,
        bool intervalMet,
        bool balanceSufficient,
        bool amountValid,
        bool upkeepNeeded,
        uint256 currentDeposits,
        uint256 currentThreshold,
        uint256 timeRemaining,
        uint256 calculatedTransferAmount
    ) {
        thresholdMet = totalDeposits >= threshold;
        
        uint256 timePassed = block.timestamp - lastTransferTime;
        intervalMet = timePassed >= MIN_INTERVAL;
        
        calculatedTransferAmount = totalDeposits / 2;
        balanceSufficient = address(this).balance >= calculatedTransferAmount;
        amountValid = calculatedTransferAmount >= MIN_TRANSFER_AMOUNT;
        
        upkeepNeeded = thresholdMet && intervalMet && balanceSufficient && amountValid;
        currentDeposits = totalDeposits;
        currentThreshold = threshold;
        timeRemaining = timePassed >= MIN_INTERVAL ? 0 : MIN_INTERVAL - timePassed;
    }
    
    /**
     * @dev 获取预计转账金额
     * @return 下次自动转账的预计金额
     */
    function getExpectedTransferAmount() external view returns (uint256) {
        return totalDeposits / 2;
    }
    
    /**
     * @dev 紧急提取函数（仅 owner，用于紧急情况）
     * 注意：这会破坏存款记录，仅在紧急情况下使用
     */
    function emergencyWithdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        // 重置存款记录（因为余额被清空）
        totalDeposits = 0;
        
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Emergency transfer failed");
    }
    
    /**
     * @dev 接收以太币的回退函数
     */
    receive() external payable {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value, totalDeposits);
    }
    
    /**
     * @dev 防止意外调用不存在的函数
     */
    fallback() external payable {
        revert("Function does not exist");
    }
}