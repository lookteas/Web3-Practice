// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MemeTWAP.sol";

// Mock合约用于测试
contract MockMemeToken {
    string public name;
    string public symbol;
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
}

contract MemeTWAPTest is Test {
    MemeTWAP public twapContract;
    MockMemeToken public memeToken1;
    MockMemeToken public memeToken2;
    
    address public owner;
    address public user1;
    address public user2;
    
    // 测试用的价格数据
    uint256[] public priceTestData = [
        1 ether,      // 1 ETH
        1.5 ether,    // 1.5 ETH
        2 ether,      // 2 ETH
        1.8 ether,    // 1.8 ETH
        2.2 ether,    // 2.2 ETH
        1.9 ether,    // 1.9 ETH
        2.5 ether,    // 2.5 ETH
        2.1 ether     // 2.1 ETH
    ];
    
    // 时间间隔（秒）
    uint256 public constant TIME_INTERVAL = 300; // 5分钟
    
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
        // 部署合约
        twapContract = new MemeTWAP(address(0x123)); // Mock factory address
        memeToken1 = new MockMemeToken("TEST1", "T1");
        memeToken2 = new MockMemeToken("TEST2", "T2");
    }
    
    /**
     * @dev 测试基本的价格更新功能
     */
    function testBasicPriceUpdate() public {
        uint256 initialPrice = 1 ether;
        
        // 更新价格
        twapContract.updatePrice(address(memeToken1), initialPrice);
        
        // 验证价格更新
        (uint256 latestPrice, uint256 timestamp) = twapContract.getLatestPriceInfo(address(memeToken1));
        
        assertEq(latestPrice, initialPrice, "Price should match");
        assertEq(timestamp, block.timestamp, "Timestamp should match");
        
        // 验证历史记录
        uint256 historyLength = twapContract.getPriceHistoryLength(address(memeToken1));
        assertEq(historyLength, 1, "History length should be 1");
    }
    
    /**
     * @dev 测试批量价格更新功能
     */
    function testBatchPriceUpdate() public {
        address[] memory tokens = new address[](2);
        uint256[] memory prices = new uint256[](2);
        
        tokens[0] = address(memeToken1);
        tokens[1] = address(memeToken2);
        prices[0] = 1.5 ether;
        prices[1] = 2.0 ether;
        
        // 批量更新价格
        twapContract.batchUpdatePrices(tokens, prices);
        
        // 验证价格更新
        (uint256 latestPrice1,) = twapContract.getLatestPriceInfo(address(memeToken1));
        (uint256 latestPrice2,) = twapContract.getLatestPriceInfo(address(memeToken2));
        
        assertEq(latestPrice1, 1.5 ether, "Token1 price should match");
        assertEq(latestPrice2, 2.0 ether, "Token2 price should match");
    }
    
    /**
     * @dev 测试多个时间点的价格更新和TWAP计算
     */
    function testMultipleTimePointsAndTWAP() public {
        uint256 startTime = block.timestamp;
        
        // 模拟多个时间点的价格更新
        for (uint256 i = 0; i < 4; i++) {
            // 跳过时间间隔
            if (i > 0) {
                vm.warp(block.timestamp + TIME_INTERVAL);
            }
            
            // 更新价格
            twapContract.updatePrice(address(memeToken1), priceTestData[i]);
        }
        
        // 验证历史记录数量
        uint256 historyLength = twapContract.getPriceHistoryLength(address(memeToken1));
        assertEq(historyLength, 4, "History count should be 4");
        
        // 计算前3个时间段的TWAP
        uint256 twapStartTime = startTime;
        uint256 twapEndTime = startTime + (3 * TIME_INTERVAL);
        
        uint256 twapPrice = twapContract.getTWAP(address(memeToken1), twapStartTime, twapEndTime);
        
        // TWAP应该大于0
        assertGt(twapPrice, 0, "TWAP should be greater than 0");
    }
    
    /**
     * @dev 测试长时间段的TWAP计算
     */
    function testLongTermTWAP() public {
        uint256 startTime = block.timestamp;
        
        // 模拟24小时内每小时的价格更新
        uint256 hourlyInterval = 3600; // 1小时
        
        // 更新12小时的价格
        for (uint256 i = 0; i < 12; i++) {
            vm.warp(block.timestamp + hourlyInterval);
            
            // 使用循环价格模式
            uint256 priceIndex = i % priceTestData.length;
            twapContract.updatePrice(address(memeToken1), priceTestData[priceIndex]);
        }
        
        // 计算12小时的TWAP
        uint256 twapEndTime = startTime + (12 * hourlyInterval);
        uint256 longTermTWAP = twapContract.getTWAP(address(memeToken1), startTime, twapEndTime);
        
        assertGt(longTermTWAP, 0, "Long term TWAP should be greater than 0");
    }
    
    /**
     * @dev 测试获取最近的TWAP数据
     */
    function testRecentTWAPs() public {
        // 先更新一些价格数据
        for (uint256 i = 0; i < 5; i++) {
            vm.warp(block.timestamp + TIME_INTERVAL);
            twapContract.updatePrice(address(memeToken1), priceTestData[i]);
        }
        
        // 获取最近的TWAP数据
        uint256[] memory recentTWAPs = twapContract.getRecentTWAPs(
            address(memeToken1), 
            3,  // 3个时间段
            TIME_INTERVAL  // 每个时间段的持续时间
        );
        
        assertGt(recentTWAPs.length, 0, "Should have recent TWAP data");
    }
    
    /**
     * @dev 测试更新频率限制
     */
    function testUpdateFrequencyLimit() public {
        // 第一次更新应该成功
        twapContract.updatePrice(address(memeToken1), 1 ether);
        
        // 立即再次更新应该失败（频率限制）
        vm.expectRevert("Update too frequent");
        twapContract.updatePrice(address(memeToken1), 1.1 ether);
        
        // 等待足够时间后应该成功
        vm.warp(block.timestamp + TIME_INTERVAL);
        twapContract.updatePrice(address(memeToken1), 1.1 ether);
    }
    
    /**
     * @dev 测试无效输入
     */
    function testInvalidInputs() public {
        // 测试零地址
        vm.expectRevert("Invalid token address");
        twapContract.updatePrice(address(0), 1 ether);
        
        // 测试零价格
        vm.expectRevert("Price must be greater than 0");
        twapContract.updatePrice(address(memeToken1), 0);
    }
    
    /**
     * @dev 测试边界情况的TWAP计算
     */
    function testEdgeCaseTWAP() public {
        // 更新一个价格
        twapContract.updatePrice(address(memeToken1), 1 ether);
        
        uint256 currentTime = block.timestamp;
        
        // 测试未来时间应该失败
        vm.expectRevert("End time in future");
        twapContract.getTWAP(address(memeToken1), currentTime, currentTime + 1000);
        
        // 测试开始时间大于结束时间
        vm.expectRevert("Invalid time range");
        twapContract.getTWAP(address(memeToken1), currentTime + 100, currentTime);
    }
    
    /**
     * @dev 测试大规模价格更新
     */
    function testLargeScalePriceUpdates() public {
        // 创建大量代币地址和价格
        address[] memory tokens = new address[](10);
        uint256[] memory prices = new uint256[](10);
        
        for (uint256 i = 0; i < 10; i++) {
            tokens[i] = address(uint160(0x1000 + i)); // 生成不同的地址
            prices[i] = (i + 1) * 1 ether;
        }
        
        // 批量更新
        twapContract.batchUpdatePrices(tokens, prices);
        
        // 验证所有价格都已更新
        for (uint256 i = 0; i < 10; i++) {
            (uint256 latestPrice,) = twapContract.getLatestPriceInfo(tokens[i]);
            assertEq(latestPrice, prices[i], "Price should match for each token");
        }
    }
    
    /**
     * @dev 测试多个代币的TWAP计算
     */
    function testMultipleTokensTWAP() public {
        // 为两个代币更新价格
        twapContract.updatePrice(address(memeToken1), 1 ether);
        twapContract.updatePrice(address(memeToken2), 2 ether);
        
        vm.warp(block.timestamp + TIME_INTERVAL);
        
        twapContract.updatePrice(address(memeToken1), 1.5 ether);
        twapContract.updatePrice(address(memeToken2), 2.5 ether);
        
        // 验证两个代币都有历史记录
        uint256 history1 = twapContract.getPriceHistoryLength(address(memeToken1));
        uint256 history2 = twapContract.getPriceHistoryLength(address(memeToken2));
        
        assertEq(history1, 2, "Token1 should have 2 price records");
        assertEq(history2, 2, "Token2 should have 2 price records");
    }
    
    /**
     * @dev 测试价格范围（模糊测试）
     */
    function testFuzzPrices(uint256 price) public {
        // 限制价格范围避免溢出
        vm.assume(price > 0 && price <= 1000000 ether);
        
        twapContract.updatePrice(address(memeToken1), price);
        
        (uint256 latestPrice,) = twapContract.getLatestPriceInfo(address(memeToken1));
        assertEq(latestPrice, price, "Price should match exactly");
    }
}