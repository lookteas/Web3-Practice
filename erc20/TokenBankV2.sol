// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ITokenReceiver.sol";
import "./BaseERC20.sol";

/**
 * TokenBankV2：继承基础银行功能，并支持自动回调存款
 */
contract TokenBankV2 is TokenBank {
    constructor(address _tokenAddress) TokenBank(_tokenAddress) {
        // 初始化父合约
    }

    /**
     * 回调函数：当 BaseERC20 调用 transferWithCallback 发送代币到本合约时触发
     */
    function tokensReceived(address _from, address _to, uint256 _value) external {
        // 安全检查：确保调用者是代币合约，且接收方是本合约
        require(msg.sender == address(token), "Only token contract can trigger callback");
        require(_to == address(this), "Callback receiver mismatch");

        // 自动记录存款（无需用户额外调用 deposit）
        deposits[_from] += _value;
    }
}