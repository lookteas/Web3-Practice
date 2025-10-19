// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title ITokenReceiver
 * @dev 代币接收者接口，用于实现代币转账回调
 */
interface ITokenReceiver {
    /**
     * @dev 当接收到代币时调用的回调函数
     * @param from 发送者地址
     * @param amount 代币数量
     * @param data 附加数据
     */
    function tokensReceived(address from, uint256 amount, bytes calldata data) external;
}