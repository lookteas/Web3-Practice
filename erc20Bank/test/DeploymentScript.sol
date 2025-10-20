// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../src/ERC20Token.sol";
import "../src/Bank.sol";
import "../src/BigBank.sol";

/**
 * @title DeploymentScript
 * @dev 演示ERC20代币与银行合约的正确部署流程
 */
contract DeploymentScript {
    ERC20Token public token;
    Bank public bank;
    BigBank public bigBank;
    
    address public deployer;
    
    event ContractDeployed(string contractName, address contractAddress);
    event DeploymentCompleted(address tokenAddress, address bankAddress, address bigBankAddress);
    
    constructor() {
        deployer = msg.sender;
    }
    
    /**
     * @dev 执行完整的部署流程
     */
    function deployAll() external {
        require(msg.sender == deployer, "Only deployer can execute");
        
        // 步骤1: 部署ERC20代币合约
        deployToken();
        
        // 步骤2: 部署Bank合约
        deployBank();
        
        // 步骤3: 部署BigBank合约
        deployBigBank();
        
        // 步骤4: 配置和验证
        configureContracts();
        
        emit DeploymentCompleted(address(token), address(bank), address(bigBank));
    }
    
    /**
     * @dev 部署ERC20代币合约
     */
    function deployToken() public {
        require(msg.sender == deployer, "Only deployer can execute");
        require(address(token) == address(0), "Token already deployed");
        
        token = new ERC20Token("Test Token", "TEST", 1000000 * 10**18);
        emit ContractDeployed("ERC20Token", address(token));
    }
    
    /**
     * @dev 部署Bank合约
     */
    function deployBank() public {
        require(msg.sender == deployer, "Only deployer can execute");
        require(address(token) != address(0), "Token must be deployed first");
        require(address(bank) == address(0), "Bank already deployed");
        
        bank = new Bank(address(token));
        emit ContractDeployed("Bank", address(bank));
    }
    
    /**
     * @dev 部署BigBank合约
     */
    function deployBigBank() public {
        require(msg.sender == deployer, "Only deployer can execute");
        require(address(token) != address(0), "Token must be deployed first");
        require(address(bigBank) == address(0), "BigBank already deployed");
        
        bigBank = new BigBank(address(token));
        emit ContractDeployed("BigBank", address(bigBank));
    }
    
    /**
     * @dev 配置合约
     */
    function configureContracts() public {
        require(msg.sender == deployer, "Only deployer can execute");
        require(address(token) != address(0), "Token not deployed");
        require(address(bank) != address(0), "Bank not deployed");
        require(address(bigBank) != address(0), "BigBank not deployed");
        
        // 验证合约配置
        require(bank.getTokenAddress() == address(token), "Bank token address not set correctly");
        require(bigBank.getTokenAddress() == address(token), "BigBank token address not set correctly");
        
        // 验证管理员权限
        require(bank.admin() == deployer, "Bank admin not set correctly");
        require(bigBank.admin() == deployer, "BigBank admin not set correctly");
        
        // 可选：分配一些代币给测试账户
        // token.transfer(testAccount, amount);
    }
    
    /**
     * @dev 获取部署信息
     */
    function getDeploymentInfo() external view returns (
        address tokenAddr,
        address bankAddr,
        address bigBankAddr,
        address deployerAddr,
        bool isDeployed
    ) {
        return (
            address(token),
            address(bank),
            address(bigBank),
            deployer,
            address(token) != address(0) && address(bank) != address(0) && address(bigBank) != address(0)
        );
    }
    
    /**
     * @dev 验证部署状态
     */
    function verifyDeployment() external view returns (bool success, string memory message) {
        if (address(token) == address(0)) {
            return (false, "Token not deployed");
        }
        if (address(bank) == address(0)) {
            return (false, "Bank not deployed");
        }
        if (address(bigBank) == address(0)) {
            return (false, "BigBank not deployed");
        }
        
        // 验证配置
        if (bank.getTokenAddress() != address(token)) {
            return (false, "Bank token address incorrect");
        }
        if (bigBank.getTokenAddress() != address(token)) {
            return (false, "BigBank token address incorrect");
        }
        
        return (true, "All contracts deployed and configured correctly");
    }
    
    /**
     * @dev 紧急情况下转移管理员权限
     */
    function transferAdminRights(address newAdmin) external {
        require(msg.sender == deployer, "Only deployer can transfer admin rights");
        require(newAdmin != address(0), "New admin cannot be zero address");
        
        if (address(bank) != address(0)) {
            bank.transferAdmin(newAdmin);
        }
        if (address(bigBank) != address(0)) {
            bigBank.transferAdmin(newAdmin);
        }
    }
}