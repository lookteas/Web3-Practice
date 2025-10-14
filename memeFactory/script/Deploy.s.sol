// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/MemeFactory.sol";

/**
 * @title Deploy Script for MemeFactory
 * @dev 部署 MemeFactory 合约的脚本
 * 
 * 使用方法：
 * 本地部署: forge script script/Deploy.s.sol --rpc-url anvil --broadcast --private-key $PRIVATE_KEY
 * Sepolia 部署: forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --private-key $PRIVATE_KEY --verify
 */
contract DeployScript is Script {
    // 部署配置
    struct DeployConfig {
        uint256 deploymentFee;  // 部署费用 (wei)
        uint256 mintingFee;     // 铸造费用 (wei)
        address owner;          // 合约所有者
    }
    
    // 网络配置
    mapping(uint256 => DeployConfig) public configs;
    
    // 事件
    event MemeFactoryDeployed(
        address indexed factory,
        address indexed implementation,
        address indexed owner,
        uint256 deploymentFee,
        uint256 mintingFee
    );
    
    function setUp() public {
        // 本地网络配置 (Chain ID: 31337)
        configs[31337] = DeployConfig({
            deploymentFee: 0,           // 本地免费
            mintingFee: 0,              // 本地免费
            owner: msg.sender
        });
        
        // Sepolia 测试网配置 (Chain ID: 11155111)
        configs[11155111] = DeployConfig({
            deploymentFee: 0.001 ether, // 0.001 ETH
            mintingFee: 0.0001 ether,   // 0.0001 ETH
            owner: msg.sender
        });
        
        // 以太坊主网配置 (Chain ID: 1) - 仅作参考
        configs[1] = DeployConfig({
            deploymentFee: 0.01 ether,  // 0.01 ETH
            mintingFee: 0.001 ether,    // 0.001 ETH
            owner: msg.sender
        });
    }
    
    function run() external {
        uint256 chainId = block.chainid;
        DeployConfig memory config = configs[chainId];
        
        // 验证配置
        require(config.owner != address(0), "Invalid config for this chain");
        
        console.log("=== Meme Factory Deployment ===");
        console.log("Chain ID:", chainId);
        console.log("Deployer:", msg.sender);
        console.log("Owner:", config.owner);
        console.log("Deployment Fee:", config.deploymentFee);
        console.log("Minting Fee:", config.mintingFee);
        
        vm.startBroadcast();
        
        // 部署 MemeFactory 合约
        MemeFactory factory = new MemeFactory();
        
        // 设置费用
        if (config.deploymentFee > 0 || config.mintingFee > 0) {
            factory.setFees(config.deploymentFee, config.mintingFee);
        }
        
        // 如果所有者不是部署者，转移所有权
        if (config.owner != msg.sender) {
            factory.transferOwnership(config.owner);
        }
        
        vm.stopBroadcast();
        
        // 获取实现合约地址
        address implementation = factory.getImplementation();
        
        console.log("=== Deployment Results ===");
        console.log("MemeFactory Address:", address(factory));
        console.log("Implementation Address:", implementation);
        console.log("Owner:", factory.owner());
        console.log("Deployment Fee:", factory.deploymentFee());
        console.log("Minting Fee:", factory.mintingFee());
        
        // 发出事件
        emit MemeFactoryDeployed(
            address(factory),
            implementation,
            factory.owner(),
            factory.deploymentFee(),
            factory.mintingFee()
        );
        
        // 保存部署信息到文件
        _saveDeploymentInfo(chainId, address(factory), implementation);
        
        // 验证部署
        _verifyDeployment(factory);
    }
    
    /**
     * @dev 保存部署信息到 JSON 文件
     */
    function _saveDeploymentInfo(
        uint256 chainId,
        address factory,
        address implementation
    ) internal {
        string memory json = "deployment";
        
        vm.serializeUint(json, "chainId", chainId);
        vm.serializeAddress(json, "factory", factory);
        vm.serializeAddress(json, "implementation", implementation);
        vm.serializeUint(json, "timestamp", block.timestamp);
        vm.serializeAddress(json, "deployer", msg.sender);
        
        string memory finalJson = vm.serializeString(json, "network", _getNetworkName(chainId));
        
        // 注释掉文件写入功能，避免权限问题
        // string memory fileName = string(abi.encodePacked("./deployments/deployment-", vm.toString(chainId), ".json"));
        // vm.writeJson(finalJson, fileName);
        
        console.log("Deployment JSON:", finalJson);
    }
    
    /**
     * @dev 获取网络名称
     */
    function _getNetworkName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "mainnet";
        if (chainId == 11155111) return "sepolia";
        if (chainId == 31337) return "anvil";
        return "unknown";
    }
    
    /**
     * @dev 验证部署结果
     */
    function _verifyDeployment(MemeFactory factory) internal view {
        console.log("=== Deployment Verification ===");
        
        // 检查合约是否正确部署
        require(address(factory) != address(0), "Factory deployment failed");
        require(factory.getImplementation() != address(0), "Implementation deployment failed");
        
        // 检查所有者
        require(factory.owner() != address(0), "Owner not set");
        
        // 检查基本功能
        require(factory.getDeployedTokensCount() == 0, "Initial token count should be 0");
        
        console.log(" Factory contract deployed successfully");
        console.log(" Implementation contract deployed successfully");
        console.log(" Owner set correctly");
        console.log(" Initial state verified");
        console.log(" All checks passed!");
    }
}

/**
 * @title Deploy Script for Testing
 * @dev 用于测试的部署脚本，包含示例代币部署
 */
contract DeployWithExamplesScript is Script {
    function run() external {
        // 首先运行主部署脚本
        DeployScript deployScript = new DeployScript();
        deployScript.setUp();
        deployScript.run();
        
        // 获取部署的工厂地址（这里需要手动设置或从文件读取）
        // 在实际使用中，可以从部署输出或配置文件中获取
        console.log("=== Deploying Example Tokens ===");
        console.log("Please run the example deployment separately after noting the factory address");
    }
    
    /**
     * @dev 部署示例代币（需要先部署工厂合约）
     */
    function deployExampleTokens(address payable factoryAddress) external {
        require(factoryAddress != address(0), "Invalid factory address");
        
        vm.startBroadcast();
        
        MemeFactory factory = MemeFactory(factoryAddress);
        
        // 部署示例代币 1: PEPE
        address pepe = factory.deployInscription{value: factory.deploymentFee()}(
            "PEPE",
            1000000 * 10**18,  // 1M total supply
            1000 * 10**18      // 1K per mint
        );
        
        // 部署示例代币 2: DOGE
        address doge = factory.deployInscription{value: factory.deploymentFee()}(
            "DOGE",
            500000 * 10**18,   // 500K total supply
            500 * 10**18       // 500 per mint
        );
        
        vm.stopBroadcast();
        
        console.log("Example PEPE token deployed at:", pepe);
        console.log("Example DOGE token deployed at:", doge);
    }
}