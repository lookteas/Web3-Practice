// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title 简单多签钱包合约
 * @dev 允许多个所有者共同管理资产，需要达到指定数量的确认才能执行交易
 */
contract SimpleMultiSigWallet {
    /// @dev 所有者地址列表
    address[] public owners;
    /// @dev 地址是否为所有者的映射
    mapping(address => bool) public isOwner;
    /// @dev 执行交易所需的最小确认数
    uint256 public required;

    /// @dev 交易结构体
    struct Transaction {
        address to;                     // 目标地址
        uint256 value;                  // 转账金额（wei）
        bytes data;                     // 调用数据
        bool executed;                  // 是否已执行
        uint256 confirmationCount;      // 确认数量
        mapping(address => bool) confirmed; // 地址是否已确认
    }

    /// @dev 交易列表
    Transaction[] public transactions;

    /// @dev 记录已提交的交易哈希，防止重复提交
    mapping(bytes32 => bool) public transactionExists;

    /// @dev 事件：提交交易
    event SubmitTransaction(uint256 indexed txIndex, address indexed owner, address to, uint256 value, bytes data);
    /// @dev 事件：确认交易
    event ConfirmTransaction(uint256 indexed txIndex, address indexed owner);
    /// @dev 事件：执行交易
    event ExecuteTransaction(uint256 indexed txIndex, address indexed to, uint256 value, bool success);

    /// @dev 修饰器：仅所有者可调用
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    /// @dev 修饰器：验证交易索引有效性
    modifier validTxIndex(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Invalid transaction index");
        _;
    }

    /**
     * @dev 构造函数
     * @param _owners 所有者地址数组
     * @param _required 执行交易所需的最小确认人数
     */
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number");

        // 初始化所有者列表
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Duplicate owner");
            owners.push(owner);
            isOwner[owner] = true;
        }
        required = _required;
    }

    /**
     * @dev 提交新交易
     * @param _to 目标合约地址
     * @param _value 转账金额（wei）
     * @param _data 调用数据（如函数选择器和参数）
     * @return 交易索引
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner returns (uint256) {
        require(_to != address(0), "Invalid recipient");

        // 生成交易唯一哈希（to + value + data）
        bytes32 txHash = keccak256(abi.encodePacked(_to, _value, _data));
        // 检查是否已存在相同交易
        require(!transactionExists[txHash], "Transaction already submitted");
        // 标记该交易哈希为已存在
        transactionExists[txHash] = true;
        
        uint256 txIndex = transactions.length;
        
        // 创建新交易 - 分步初始化包含 mapping 的结构体
        transactions.push();
        Transaction storage newTx = transactions[txIndex];
        newTx.to = _to;
        newTx.value = _value;
        newTx.data = _data;
        newTx.executed = false;
        newTx.confirmationCount = 0;
        
        // 自动确认提交者
        _confirmTransaction(txIndex, msg.sender);
        
        emit SubmitTransaction(txIndex, msg.sender, _to, _value, _data);
        return txIndex;
    }

    /**
     * @dev 确认交易
     * @param _txIndex 交易索引
     */
    function confirmTransaction(uint256 _txIndex) 
        external 
        onlyOwner 
        validTxIndex(_txIndex) 
    {
        _confirmTransaction(_txIndex, msg.sender);
    }

    /**
     * @dev 内部确认交易函数
     * @param _txIndex 交易索引
     * @param _owner 确认者地址
     */
    function _confirmTransaction(uint256 _txIndex, address _owner) internal {
        Transaction storage transaction = transactions[_txIndex];
        require(!transaction.executed, "Already executed");
        require(!transaction.confirmed[_owner], "Already confirmed");

        transaction.confirmed[_owner] = true;
        transaction.confirmationCount++;
        emit ConfirmTransaction(_txIndex, _owner);
    }

    /**
     * @dev 获取交易确认数量
     * @param _txIndex 交易索引
     * @return 确认数量
     */
    function getConfirmationCount(uint256 _txIndex) 
        public 
        view 
        validTxIndex(_txIndex) 
        returns (uint256) 
    {
        return transactions[_txIndex].confirmationCount;
    }

    /**
     * @dev 检查地址是否已确认指定交易
     * @param _txIndex 交易索引
     * @param _owner 要检查的地址
     * @return 是否已确认
     */
    function isConfirmed(uint256 _txIndex, address _owner) 
        public 
        view 
        validTxIndex(_txIndex) 
        returns (bool) 
    {
        return transactions[_txIndex].confirmed[_owner];
    }

    /**
     * @dev 执行交易
     * @param _txIndex 交易索引
     */
    function executeTransaction(uint256 _txIndex) 
        external 
        validTxIndex(_txIndex) 
    {
        Transaction storage transaction = transactions[_txIndex];
        require(!transaction.executed, "Already executed");
        require(transaction.confirmationCount >= required, "Not enough confirmations");

        transaction.executed = true;

        // 使用底层call执行交易
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);

        require(success, "Transaction execution failed");

        //记录交易事件
        emit ExecuteTransaction(_txIndex, transaction.to, transaction.value, true);
        
    }

    /**
     * @dev 获取交易总数
     * @return 交易数量
     */
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    /**
     * @dev 获取所有所有者地址
     * @return 所有者地址数组
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /**
     * @dev 接收ETH的回退函数
     */
    receive() external payable {}
}