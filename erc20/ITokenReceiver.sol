// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev 接收代币回调的标准接口
 */
interface ITokenReceiver {
    function tokensReceived(address _from, address _to, uint256 _value) external;
}