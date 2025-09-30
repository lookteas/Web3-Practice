// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyToken
 * @dev ERC20代币合约，用于DeFi生态系统
 * @notice 这是一个标准的ERC20代币，具有铸造和销毁功能
 */
contract MyToken is ERC20, Ownable {
    /// @dev 代币总供应量：1000万个代币
    uint256 public constant TOTAL_SUPPLY = 10_000_000 * 10**18; // 10 million tokens
    
    /**
     * @dev 构造函数，初始化代币
     * @notice 创建名为"My Token"，符号为"MD"的ERC20代币
     * 将所有初始供应量铸造给合约部署者
     */
    constructor() ERC20("My Token", "MD") Ownable(msg.sender) {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
    
    /**
     * @dev 铸造新的代币
     * @param to 接收新铸造代币的地址
     * @param amount 要铸造的代币数量（以wei为单位）
     * @notice 只有合约所有者可以调用此函数才会增加代币的总供应量
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    /**
     * @dev 销毁调用者持有的代币
     * @param amount 要销毁的代币数量（以wei为单位）
     * @notice 任何持有代币的用户都可以销毁自己的代币
     * @notice 这会减少代币的总供应量
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
