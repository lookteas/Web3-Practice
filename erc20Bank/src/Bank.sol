// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./IBank.sol";
import "./ITokenReceiver.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title Bank 合约
 * @dev 实现存款、提款和记录前3名存款用户功能，支持ETH和ERC20代币，实现 IBank 和 ITokenReceiver 接口
 */
contract Bank is IBank, ITokenReceiver {
    // 合约管理员
    address public override admin;
    
    // 支持的ERC20代币地址
    address public tokenAddress;
    
    // 防重入攻击锁
    bool private locked;
    
    // 记录每个地址的ETH存款金额
    mapping(address => uint256) public deposits;
    
    // 记录每个地址的ERC20代币存款金额
    mapping(address => uint256) public tokenDeposits;
    
    // 存款金额前3名用户（基于ETH存款）
    address[3] public topDepositors;
    
    // 代币存款金额前3名用户
    address[3] public topTokenDepositors;
    
    // 所有存款用户地址列表
    address[] public depositors;
    
    // 所有代币存款用户地址列表
    address[] public tokenDepositors;
    
    // 修饰：仅管理员可调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can call");
        _;
    }
    
    // 防重入攻击修饰符
    modifier nonReentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }
    
    /**
     * @dev 构造函数，设置合约部署者为管理员
     * @param _tokenAddress 支持的ERC20代币地址，传入address(0)表示不支持代币
     */
    constructor(address _tokenAddress) {
        admin = msg.sender;
        tokenAddress = _tokenAddress;
    }
    
    /**
     * @dev 设置支持的ERC20代币地址，仅管理员可调用
     * @param _tokenAddress 新的代币地址
     */
    function setTokenAddress(address _tokenAddress) external onlyAdmin {
        tokenAddress = _tokenAddress;
    }
    
    /**
     * @dev 存款函数，接收以太币存款
     * 用户可以通过 Metamask 等钱包直接向合约地址发送以太币
     */
    receive() external payable virtual {
        deposit();
    }
    
    /**
     * @dev 存款函数
     */
    function deposit() public payable virtual override {
        require(msg.value > 0, "deposit amount must be greater than 0");
        
        // 如果是首次存款，添加到存款用户列表
        if (deposits[msg.sender] == 0) {
            depositors.push(msg.sender);
        }
        
        // 更新存款金额
        deposits[msg.sender] += msg.value;
        
        // 更新前3名存款用户
        updateTopDepositors();
        
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev ERC20代币存款函数
     * @param amount 存款金额
     */
    function depositToken(uint256 amount) external virtual {
        require(tokenAddress != address(0), "Token not supported");
        require(amount > 0, "deposit amount must be greater than 0");
        
        // 从用户账户转移代币到合约
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        
        // 如果是首次代币存款，添加到代币存款用户列表
        if (tokenDeposits[msg.sender] == 0) {
            tokenDepositors.push(msg.sender);
        }
        
        // 更新代币存款金额
        tokenDeposits[msg.sender] += amount;
        
        // 更新前3名代币存款用户
        updateTopTokenDepositors();
        
        emit Deposit(msg.sender, amount);
    }
    
    /**
     * @dev 实现ITokenReceiver接口，处理代币回调
     */
    function tokensReceived(address _from, address _to, uint256 _value) external override {
        require(msg.sender == tokenAddress, "Only supported token can call");
        require(_to == address(this), "Invalid recipient");
        
        // 如果是首次代币存款，添加到代币存款用户列表
        if (tokenDeposits[_from] == 0) {
            tokenDepositors.push(_from);
        }
        
        // 更新代币存款金额
        tokenDeposits[_from] += _value;
        
        // 更新前3名代币存款用户
        updateTopTokenDepositors();
        
        emit Deposit(_from, _value);
    }
    
    /**
     * @dev 提款函数，仅管理员可调用
     * @param amount 提款金额
     */
    function withdraw(uint256 amount) external override onlyAdmin nonReentrant {
        require(amount > 0, "withdraw amount must be greater than 0");
        require(address(this).balance >= amount, "no balance to withdraw");
        
        // 将以太币发送给管理员
        payable(admin).transfer(amount);
        
        emit Withdrawal(admin, amount);
    }
    
    /**
     * @dev 提取合约中的所有资金，仅管理员可调用
     */
    function withdrawAll() external override onlyAdmin nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "no balance to withdraw");
        
        payable(admin).transfer(balance);
        
        emit Withdrawal(admin, balance);
    }
    
    /**
     * @dev 提取代币，仅管理员可调用
     * @param amount 提取金额
     */
    function withdrawToken(uint256 amount) external onlyAdmin nonReentrant {
        require(tokenAddress != address(0), "Token not supported");
        require(amount > 0, "withdraw amount must be greater than 0");
        
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenBalance >= amount, "no token balance to withdraw");
        
        // 将代币发送给管理员
        IERC20(tokenAddress).transfer(admin, amount);
        
        emit Withdrawal(admin, amount);
    }
    
    /**
     * @dev 提取合约中的所有代币，仅管理员可调用
     */
    function withdrawAllTokens() external onlyAdmin nonReentrant {
        require(tokenAddress != address(0), "Token not supported");
        
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenBalance > 0, "no token balance to withdraw");
        
        // 将所有代币发送给管理员
        IERC20(tokenAddress).transfer(admin, tokenBalance);
        
        emit Withdrawal(admin, tokenBalance);
    }
    
    /**
     * @dev 更新前3名存款用户
     */
    function updateTopDepositors() internal {
        address tempAddr;
        uint256 tempAmount;
        
        // 将当前用户加入临时数组进行排序
        address[4] memory candidates;
        uint256[4] memory amounts;
        
        // 复制现有的前3名
        for (uint i = 0; i < 3; i++) {
            candidates[i] = topDepositors[i];
            if (candidates[i] != address(0)) {
                amounts[i] = deposits[candidates[i]];
            }
        }
        
        // 添加当前存款用户
        candidates[3] = msg.sender;
        amounts[3] = deposits[msg.sender];
        
        // 冒泡排序，按存款金额降序排列
        for (uint i = 0; i < 4; i++) {
            for (uint j = 0; j < 3 - i; j++) {
                if (amounts[j] < amounts[j + 1]) {
                    // 交换金额
                    tempAmount = amounts[j];
                    amounts[j] = amounts[j + 1];
                    amounts[j + 1] = tempAmount;
                    
                    // 交换地址
                    tempAddr = candidates[j];
                    candidates[j] = candidates[j + 1];
                    candidates[j + 1] = tempAddr;
                }
            }
        }
        
        // 更新前3名，去除重复地址
        uint256 count = 0;
        address[3] memory newTopDepositors;
        
        for (uint i = 0; i < 4 && count < 3; i++) {
            if (candidates[i] != address(0) && amounts[i] > 0) {
                bool isDuplicate = false;
                for (uint j = 0; j < count; j++) {
                    if (newTopDepositors[j] == candidates[i]) {
                        isDuplicate = true;
                        break;
                    }
                }
                if (!isDuplicate) {
                    newTopDepositors[count] = candidates[i];
                    count++;
                }
            }
        }
        
        topDepositors = newTopDepositors;
        emit TopDepositorsUpdated(topDepositors);
    }
    
    /**
     * @dev 更新前3名代币存款用户
     */
    function updateTopTokenDepositors() internal {
        address tempAddr;
        uint256 tempAmount;
        
        // 将当前用户加入临时数组进行排序
        address[4] memory candidates;
        uint256[4] memory amounts;
        
        // 复制现有的前3名
        for (uint i = 0; i < 3; i++) {
            candidates[i] = topTokenDepositors[i];
            if (candidates[i] != address(0)) {
                amounts[i] = tokenDeposits[candidates[i]];
            }
        }
        
        // 添加当前用户
        candidates[3] = msg.sender;
        amounts[3] = tokenDeposits[msg.sender];
        
        // 冒泡排序，按存款金额降序排列
        for (uint i = 0; i < 4; i++) {
            for (uint j = 0; j < 3 - i; j++) {
                if (amounts[j] < amounts[j + 1]) {
                    // 交换金额
                    tempAmount = amounts[j];
                    amounts[j] = amounts[j + 1];
                    amounts[j + 1] = tempAmount;
                    
                    // 交换地址
                    tempAddr = candidates[j];
                    candidates[j] = candidates[j + 1];
                    candidates[j + 1] = tempAddr;
                }
            }
        }
        
        // 更新前3名，去除重复地址
        uint256 count = 0;
        address[3] memory newTopTokenDepositors;
        
        for (uint i = 0; i < 4 && count < 3; i++) {
            if (candidates[i] != address(0) && amounts[i] > 0) {
                bool isDuplicate = false;
                for (uint j = 0; j < count; j++) {
                    if (newTopTokenDepositors[j] == candidates[i]) {
                        isDuplicate = true;
                        break;
                    }
                }
                if (!isDuplicate) {
                    newTopTokenDepositors[count] = candidates[i];
                    count++;
                }
            }
        }
        
        topTokenDepositors = newTopTokenDepositors;
        emit TopDepositorsUpdated(topTokenDepositors);
    }
    
    /**
     * @dev 获取合约余额
     */
    function getContractBalance() external view override returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev 获取指定地址的存款金额
     */
    function getDeposit(address depositor) external view override returns (uint256) {
        return deposits[depositor];
    }
    
    /**
     * @dev 获取前3名存款用户
     */
    function getTopDepositors() external view override returns (address[3] memory) {
        return topDepositors;
    }
    
    /**
     * @dev 获取前3名存款用户及其存款金额
     */
    function getTopDepositorsWithAmounts() external view override returns (address[3] memory, uint256[3] memory) {
        uint256[3] memory amounts;
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i] != address(0)) {
                amounts[i] = deposits[topDepositors[i]];
            }
        }
        return (topDepositors, amounts);
    }
    
    /**
     * @dev 获取所有存款用户数量
     */
    function getDepositorsCount() external view override returns (uint256) {
        return depositors.length;
    }
    
    /**
     * @dev 转移管理员权限
     */
    function transferAdmin(address newAdmin) external override onlyAdmin {
        require(newAdmin != address(0), "only admin can transfer");
        admin = newAdmin;
    }
    
    // ========== 代币相关的getter函数 ==========
    
    /**
     * @dev 获取合约代币余额
     */
    function getContractTokenBalance() external view returns (uint256) {
        if (tokenAddress == address(0)) return 0;
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    
    /**
     * @dev 获取指定地址的代币存款金额
     */
    function getTokenDeposit(address depositor) external view returns (uint256) {
        return tokenDeposits[depositor];
    }
    
    /**
     * @dev 获取前3名代币存款用户
     */
    function getTopTokenDepositors() external view returns (address[3] memory) {
        return topTokenDepositors;
    }
    
    /**
     * @dev 获取前3名代币存款用户及其存款金额
     */
    function getTopTokenDepositorsWithAmounts() external view returns (address[3] memory, uint256[3] memory) {
        uint256[3] memory amounts;
        for (uint i = 0; i < 3; i++) {
            if (topTokenDepositors[i] != address(0)) {
                amounts[i] = tokenDeposits[topTokenDepositors[i]];
            }
        }
        return (topTokenDepositors, amounts);
    }
    
    /**
     * @dev 获取所有代币存款用户数量
     */
    function getTokenDepositorsCount() external view returns (uint256) {
        return tokenDepositors.length;
    }
    
    /**
     * @dev 获取支持的代币地址
     */
    function getTokenAddress() external view returns (address) {
        return tokenAddress;
    }
}