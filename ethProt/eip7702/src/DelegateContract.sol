// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @title IERC1271
 * @dev Interface for ERC-1271 signature validation
 */
interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

/**
 * @title DelegateContract
 * @dev EIP-7702 委托合约，支持批量执行和nonce管理
 * @notice 此合约将被EOA通过EIP-7702授权机制临时设置为代码
 */
contract DelegateContract is IERC1271 {
    // ERC-1271 magic value
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    
    // 用户nonce映射，防止重放攻击
    mapping(address => uint256) public nonces;
    
    // 批量执行事件
    event BatchExecuted(address indexed user, uint256 nonce, uint256 executedCount);
    
    // 执行失败事件
    event ExecutionFailed(address indexed target, bytes data, string reason);
    
    // 错误定义
    error InvalidNonce();
    error BatchExecutionFailed();
    error EmptyCalldata();
    
    /**
     * @dev 批量执行多个合约调用
     * @param targets 目标合约地址数组
     * @param values 每个调用的ETH数量数组
     * @param calldatas 每个调用的calldata数组
     * @param expectedNonce 期望的nonce值，用于防止重放攻击
     */
    function batchExecute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        uint256 expectedNonce
    ) external payable {
        // 验证nonce
        if (nonces[msg.sender] != expectedNonce) {
            revert InvalidNonce();
        }
        
        // 验证数组长度一致
        require(
            targets.length == values.length && 
            values.length == calldatas.length,
            "Array length mismatch"
        );
        
        require(targets.length > 0, "Empty targets array");
        
        // 增加nonce
        nonces[msg.sender]++;
        
        uint256 executedCount = 0;
        
        // 执行批量调用
        for (uint256 i = 0; i < targets.length; i++) {
            if (calldatas[i].length == 0) {
                emit ExecutionFailed(targets[i], calldatas[i], "Empty calldata");
                continue;
            }
            
            (bool success, bytes memory returnData) = targets[i].call{value: values[i]}(calldatas[i]);
            
            if (success) {
                executedCount++;
            } else {
                // 解析失败原因
                string memory reason = "Unknown error";
                if (returnData.length > 0) {
                    assembly {
                        let returnDataSize := mload(returnData)
                        revert(add(32, returnData), returnDataSize)
                    }
                } else {
                    reason = "Call reverted without reason";
                }
                emit ExecutionFailed(targets[i], calldatas[i], reason);
            }
        }
        
        emit BatchExecuted(msg.sender, expectedNonce, executedCount);
    }
    
    /**
     * @dev 获取用户当前nonce
     * @param user 用户地址
     * @return 当前nonce值
     */
    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }
    
    /**
     * @dev ERC-1271签名验证（基础实现）
     * @param hash 消息哈希
     * @param signature 签名数据
     * @return magicValue 如果签名有效返回magic value
     */
    function isValidSignature(bytes32 hash, bytes memory signature) 
        external 
        view 
        override 
        returns (bytes4 magicValue) 
    {
        // 基础实现：总是返回有效
        // 在实际应用中，这里应该实现真正的签名验证逻辑
        return MAGICVALUE;
    }
    
    /**
     * @dev 接收ETH
     */
    receive() external payable {}
    
    /**
     * @dev fallback函数
     */
    fallback() external payable {}
}