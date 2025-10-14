// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/MemeFactory.sol";
import "../src/MemeToken.sol";

/**
 * @title MemeFactory Test Suite
 * @dev 完整的 MemeFactory 和 MemeToken 测试套件
 */
contract MemeFactoryTest is Test {
    MemeFactory public factory;
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    
    // 测试常量
    uint256 constant DEPLOYMENT_FEE = 0.001 ether;
    uint256 constant MINTING_FEE = 0.0001 ether;
    uint256 constant TOKEN_PRICE = 0.01 ether; // 每次铸造的价格
    uint256 constant INITIAL_BALANCE = 10 ether;
    
    // 事件声明（用于测试）
    event TokenDeployed(
        address indexed tokenAddress,
        string symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price,
        address indexed deployer
    );
    
    event TokenMinted(
        address indexed tokenAddress,
        address indexed to,
        uint256 amount,
        uint256 fee,
        address indexed minter
    );
    
    function setUp() public {
        // 设置测试账户
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // 给测试账户分配 ETH
        vm.deal(user1, INITIAL_BALANCE);
        vm.deal(user2, INITIAL_BALANCE);
        vm.deal(user3, INITIAL_BALANCE);
        
        // 部署工厂合约
        factory = new MemeFactory();
        
        // 设置费用
        factory.setFees(DEPLOYMENT_FEE, MINTING_FEE);
    }
    
    // ============ 基础功能测试 ============
    
    function testFactoryDeployment() public {
        // 测试工厂合约部署
        assertEq(factory.owner(), owner);
        assertEq(factory.deploymentFee(), DEPLOYMENT_FEE);
        assertEq(factory.mintingFee(), MINTING_FEE);
        assertEq(factory.getDeployedTokensCount(), 0);
        assertTrue(factory.getImplementation() != address(0));
    }
    
    function testDeployMeme() public {
        vm.startPrank(user1);
        
        // 测试成功部署代币
        vm.expectEmit(false, true, true, true);
        emit TokenDeployed(address(0), "TEST", 1000000 * 10**18, 1000 * 10**18, TOKEN_PRICE, user1);
        
        address tokenAddr = factory.deployMeme{value: DEPLOYMENT_FEE}(
            "TEST",
            1000000 * 10**18,  // 1M total supply
            1000 * 10**18,     // 1K per mint
            TOKEN_PRICE        // price per mint
        );
        
        // 验证部署结果
        assertTrue(tokenAddr != address(0));
        assertEq(factory.getDeployedTokensCount(), 1);
        assertEq(factory.symbolToToken("TEST"), tokenAddr);
        assertEq(factory.tokenToSymbol(tokenAddr), "TEST");
        assertEq(factory.tokenToDeployer(tokenAddr), user1);
        assertEq(factory.tokenToPrice(tokenAddr), TOKEN_PRICE);
        assertTrue(factory.isDeployedToken(tokenAddr));
        
        // 验证代币合约
        MemeToken token = MemeToken(tokenAddr);
        assertEq(token.name(), "Meme TEST");
        assertEq(token.symbol(), "TEST");
        assertEq(token.totalSupplyLimit(), 1000000 * 10**18);
        assertEq(token.perMint(), 1000 * 10**18);
        assertEq(token.owner(), address(factory));
        
        vm.stopPrank();
    }
    
    function testMintMeme() public {
        // 先部署代币
        vm.prank(user1);
        address tokenAddr = factory.deployMeme{value: DEPLOYMENT_FEE}(
            "MINT",
            1000000 * 10**18,
            1000 * 10**18,
            TOKEN_PRICE
        );
        
        // 测试铸造
        vm.startPrank(user2);
        
        vm.expectEmit(true, true, false, true);
        emit TokenMinted(tokenAddr, user2, 1000 * 10**18, TOKEN_PRICE, user2);
        
        factory.mintMeme{value: TOKEN_PRICE}(tokenAddr);
        
        // 验证铸造结果
        MemeToken token = MemeToken(tokenAddr);
        assertEq(token.balanceOf(user2), 1000 * 10**18);
        assertEq(token.mintedAmount(), 1000 * 10**18);
        
        vm.stopPrank();
    }
    
    // ============ 边界条件测试 ============
    
    function testDeployMemeInvalidParams() public {
        vm.startPrank(user1);
        
        // 测试空符号
        vm.expectRevert("Symbol cannot be empty");
        factory.deployMeme{value: DEPLOYMENT_FEE}("", 1000, 100, TOKEN_PRICE);
        
        // 测试符号过长
        vm.expectRevert("Symbol too long");
        factory.deployMeme{value: DEPLOYMENT_FEE}("VERYLONGSYMBOL", 1000, 100, TOKEN_PRICE);
        
        // 测试总供应量为0
        vm.expectRevert("Total supply must be greater than 0");
        factory.deployMeme{value: DEPLOYMENT_FEE}("TEST", 0, 100, TOKEN_PRICE);
        
        // 测试每次铸造量为0
        vm.expectRevert("Per mint must be greater than 0");
        factory.deployMeme{value: DEPLOYMENT_FEE}("TEST", 1000, 0, TOKEN_PRICE);
        
        // 测试每次铸造量大于总供应量
        vm.expectRevert("Per mint cannot exceed total supply");
        factory.deployMeme{value: DEPLOYMENT_FEE}("TEST", 100, 1000, TOKEN_PRICE);
        
        // 测试价格为0
        vm.expectRevert("Price must be greater than 0");
        factory.deployMeme{value: DEPLOYMENT_FEE}("TEST", 1000, 100, 0);
        
        // 测试费用不足
        vm.expectRevert("Insufficient deployment fee");
        factory.deployMeme{value: DEPLOYMENT_FEE - 1}("TEST", 1000, 100, TOKEN_PRICE);
        
        vm.stopPrank();
    }
    
    function testDuplicateSymbol() public {
        // 部署第一个代币
        vm.prank(user1);
        factory.deployMeme{value: DEPLOYMENT_FEE}("DUP", 1000000 * 10**18, 1000 * 10**18, TOKEN_PRICE);
        
        // 尝试部署相同符号的代币
        vm.prank(user2);
        vm.expectRevert("Symbol already exists");
        factory.deployMeme{value: DEPLOYMENT_FEE}("DUP", 2000000 * 10**18, 2000 * 10**18, TOKEN_PRICE);
    }
    
    function testMintMemeInvalidToken() public {
        vm.startPrank(user1);
        
        // 测试无效地址
        vm.expectRevert("Invalid token address");
        factory.mintMeme{value: TOKEN_PRICE}(address(0));
        
        // 测试非工厂部署的代币
        vm.expectRevert("Token not deployed by this factory");
        factory.mintMeme{value: TOKEN_PRICE}(address(0x123));
        
        // 测试费用不足
        address tokenAddr = factory.deployMeme{value: DEPLOYMENT_FEE}("FEE", 1000, 100, TOKEN_PRICE);
        vm.expectRevert("Insufficient payment");
        factory.mintMeme{value: TOKEN_PRICE - 1}(tokenAddr);
        
        vm.stopPrank();
    }
    
    // ============ 批量铸造测试 ============
    
    function testBatchMintMeme() public {
        // 部署代币
        vm.prank(user1);
        address tokenAddr = factory.deployMeme{value: DEPLOYMENT_FEE}(
            "BATCH",
            10000 * 10**18,
            100 * 10**18,
            TOKEN_PRICE
        );
        
        // 批量铸造
        vm.prank(user2);
        factory.batchMintMeme{value: TOKEN_PRICE * 3}(tokenAddr, 3);
        
        // 验证结果
        MemeToken token = MemeToken(tokenAddr);
        assertEq(token.balanceOf(user2), 300 * 10**18);
        assertEq(token.mintedAmount(), 300 * 10**18);
    }
    
    function testBatchMintInvalidCount() public {
        vm.prank(user1);
        address tokenAddr = factory.deployMeme{value: DEPLOYMENT_FEE}("COUNT", 1000 * 10**18, 100 * 10**18, TOKEN_PRICE);
        
        vm.startPrank(user2);
        
        // 测试数量为0
        vm.expectRevert("Invalid count (1-5)");
        factory.batchMintMeme{value: TOKEN_PRICE}(tokenAddr, 0);
        
        // 测试数量超过限制
        vm.expectRevert("Invalid count (1-5)");
        factory.batchMintMeme{value: TOKEN_PRICE * 6}(tokenAddr, 6);
        
        // 测试费用不足
        vm.expectRevert("Insufficient payment");
        factory.batchMintMeme{value: TOKEN_PRICE * 2}(tokenAddr, 3);
        
        vm.stopPrank();
    }
    
    // ============ 代币限制测试 ============
    
    function testMintingLimits() public {
        // 部署小供应量代币
        vm.prank(user1);
        address tokenAddr = factory.deployMeme{value: DEPLOYMENT_FEE}(
            "LIMIT",
            500 * 10**18,   // 500 total
            100 * 10**18,   // 100 per mint
            TOKEN_PRICE
        );
        
        MemeToken token = MemeToken(tokenAddr);
        
        // 用户2铸造5次（达到总供应量）
        vm.startPrank(user2);
        for (uint i = 0; i < 5; i++) {
            factory.mintMeme{value: TOKEN_PRICE}(tokenAddr);
        }
        vm.stopPrank();
        
        // 验证总供应量已达到
        assertEq(token.mintedAmount(), 500 * 10**18);
        assertEq(token.balanceOf(user2), 500 * 10**18);
        
        // 尝试继续铸造应该失败
        vm.prank(user3);
        vm.expectRevert("Cannot mint to this address");
        factory.mintMeme{value: TOKEN_PRICE}(tokenAddr);
    }
    
    // ============ 查询功能测试 ============
    
    function testGetTokenInfo() public {
        vm.prank(user1);
        address tokenAddr = factory.deployMeme{value: DEPLOYMENT_FEE}(
            "INFO",
            1000 * 10**18,
            50 * 10**18,
            TOKEN_PRICE
        );
        
        // 铸造一些代币
        vm.prank(user2);
        factory.mintMeme{value: TOKEN_PRICE}(tokenAddr);
        
        // 获取代币信息
        (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 perMint,
            uint256 mintedAmount,
            uint256 remainingSupply,
            uint256 price,
            address deployer
        ) = factory.getTokenInfo(tokenAddr);
        
        assertEq(name, "Meme INFO");
        assertEq(symbol, "INFO");
        assertEq(totalSupply, 1000 * 10**18);
        assertEq(perMint, 50 * 10**18);
        assertEq(mintedAmount, 50 * 10**18);
        assertEq(remainingSupply, 950 * 10**18);
        assertEq(deployer, user1);
        assertEq(price, TOKEN_PRICE);
    }
    
    function testGetDeployedTokens() public {
        // 部署多个代币
        vm.startPrank(user1);
        address token1 = factory.deployMeme{value: DEPLOYMENT_FEE}("TOK1", 1000 * 10**18, 100 * 10**18, TOKEN_PRICE);
        address token2 = factory.deployMeme{value: DEPLOYMENT_FEE}("TOK2", 2000 * 10**18, 200 * 10**18, TOKEN_PRICE);
        address token3 = factory.deployMeme{value: DEPLOYMENT_FEE}("TOK3", 3000 * 10**18, 300 * 10**18, TOKEN_PRICE);
        vm.stopPrank();
        
        // 测试分页查询
        (address[] memory tokens, string[] memory symbols) = factory.getDeployedTokens(0, 2);
        
        assertEq(tokens.length, 2);
        assertEq(symbols.length, 2);
        assertEq(tokens[0], token1);
        assertEq(tokens[1], token2);
        assertEq(symbols[0], "TOK1");
        assertEq(symbols[1], "TOK2");
        
        // 测试第二页
        (tokens, symbols) = factory.getDeployedTokens(2, 2);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], token3);
        assertEq(symbols[0], "TOK3");
    }
    
    function testGetTokenBySymbol() public {
        vm.prank(user1);
        address tokenAddr = factory.deployMeme{value: DEPLOYMENT_FEE}("SYM", 1000 * 10**18, 100 * 10**18, TOKEN_PRICE);
        
        assertEq(factory.getTokenBySymbol("SYM"), tokenAddr);
        assertEq(factory.getTokenBySymbol("NONEXISTENT"), address(0));
    }
    
    function testIsSymbolAvailable() public {
        assertTrue(factory.isSymbolAvailable("AVAILABLE"));
        
        vm.prank(user1);
        factory.deployMeme{value: DEPLOYMENT_FEE}("TAKEN", 1000 * 10**18, 100 * 10**18, TOKEN_PRICE);
        
        assertFalse(factory.isSymbolAvailable("TAKEN"));
        assertTrue(factory.isSymbolAvailable("STILLAVAILABLE"));
    }
    
    // ============ 所有者功能测试 ============
    
    function testSetFees() public {
        uint256 newDeployFee = 0.002 ether;
        uint256 newMintFee = 0.0002 ether;
        
        factory.setFees(newDeployFee, newMintFee);
        
        assertEq(factory.deploymentFee(), newDeployFee);
        assertEq(factory.mintingFee(), newMintFee);
    }
    
    function testSetFeesOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        factory.setFees(0.002 ether, 0.0002 ether);
    }
    
    function testWithdraw() public {
        // 先收集一些费用
        vm.prank(user1);
        factory.deployMeme{value: DEPLOYMENT_FEE}("WITHDRAW", 1000 * 10**18, 100 * 10**18, TOKEN_PRICE);
        
        uint256 initialBalance = address(this).balance;
        uint256 contractBalance = address(factory).balance;
        
        factory.withdraw();
        
        assertEq(address(factory).balance, 0);
        assertEq(address(this).balance, initialBalance + contractBalance);
    }
    
    function testWithdrawOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        factory.withdraw();
    }
    
    function testWithdrawNoFunds() public {
        vm.expectRevert("No funds to withdraw");
        factory.withdraw();
    }
    
    // ============ 重入攻击测试 ============
    
    function testReentrancyProtection() public {
        // 这里可以添加重入攻击测试
        // 由于使用了 ReentrancyGuard，应该能防止重入攻击
    }
    
    function testFeeDistribution() public {
        // 部署代币
        vm.prank(user1);
        address tokenAddr = factory.deployMeme{value: DEPLOYMENT_FEE}(
            "FEE",
            1000000 * 10**18,
            1000 * 10**18,
            TOKEN_PRICE
        );
        
        // 记录初始余额
        uint256 ownerBalanceBefore = owner.balance;
        uint256 deployerBalanceBefore = user1.balance;
        
        // 铸造代币
        vm.prank(user2);
        factory.mintMeme{value: TOKEN_PRICE}(tokenAddr);
        
        // 计算预期费用分配
        uint256 projectFee = TOKEN_PRICE * 100 / 10000; // 1%
        uint256 deployerFee = TOKEN_PRICE - projectFee; // 99%
        
        // 验证费用分配
        assertEq(owner.balance, ownerBalanceBefore + projectFee);
        assertEq(user1.balance, deployerBalanceBefore + deployerFee);
    }
    
    // ============ 辅助函数 ============
    
    receive() external payable {}
}