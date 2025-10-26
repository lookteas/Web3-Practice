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

    // ========== 时间跳跃工具函数 ==========

    /**
     * @dev 跳跃指定的秒数
     */
    function skipTime(uint256 seconds_) internal {
        vm.warp(block.timestamp + seconds_);
    }

    /**
     * @dev 跳跃指定的分钟数
     */
    function skipMinutes(uint256 minutes_) internal {
        skipTime(minutes_ * 60);
    }

    /**
     * @dev 跳跃指定的小时数
     */
    function skipHours(uint256 hours_) internal {
        skipTime(hours_ * 3600);
    }

    /**
     * @dev 跳跃指定的天数
     */
    function skipDays(uint256 days_) internal {
        skipTime(days_ * 86400);
    }

    /**
     * @dev 跳跃指定的周数
     */
    function skipWeeks(uint256 weeks_) internal {
        skipTime(weeks_ * 604800);
    }

    /**
     * @dev 跳跃到指定的时间戳
     */
    function warpTo(uint256 timestamp) internal {
        vm.warp(timestamp);
    }

    /**
     * @dev 获取当前区块时间戳
     */
    function getCurrentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev 批量更新价格并跳跃时间
     */
    function updatePriceAndSkip(
        address token,
        uint256 price,
        uint256 timeToSkip
    ) internal {
        twapContract.updatePrice(token, price);
        if (timeToSkip > 0) {
            skipTime(timeToSkip);
        }
    }

    /**
     * @dev 批量更新多个代币价格并跳跃时间
     */
    function updateMultiplePricesAndSkip(
        address[] memory tokens,
        uint256[] memory prices,
        uint256 timeToSkip
    ) internal {
        require(tokens.length == prices.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < tokens.length; i++) {
            twapContract.updatePrice(tokens[i], prices[i]);
        }
        
        if (timeToSkip > 0) {
            skipTime(timeToSkip);
        }
    }

    /**
     * @dev 模拟交易日（跳跃到下一个工作日的开盘时间）
     */
    function skipToNextTradingDay() internal {
        // 跳跃24小时到下一天
        skipDays(1);
    }

    /**
     * @dev 模拟周末（跳跃到下周一）
     */
    function skipWeekend() internal {
        // 跳跃2天（周末）
        skipDays(2);
    }

    /**
     * @dev 创建时间序列价格更新
     */
    function createTimeSeriesPrices(
        address token,
        uint256[] memory prices,
        uint256[] memory timeIntervals
    ) internal {
        require(prices.length == timeIntervals.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < prices.length; i++) {
            if (i > 0) {
                skipTime(timeIntervals[i-1]);
            }
            twapContract.updatePrice(token, prices[i]);
        }
    }

    /**
     * @dev 模拟市场开盘到收盘的价格变化
     */
    function simulateMarketDay(
        address token,
        uint256 openPrice,
        uint256 closePrice,
        uint256 tradingHours
    ) internal {
        uint256 hourlyInterval = 3600; // 1小时
        uint256 priceStep = (closePrice > openPrice) 
            ? (closePrice - openPrice) / tradingHours
            : (openPrice - closePrice) / tradingHours;
        
        for (uint256 hour = 0; hour < tradingHours; hour++) {
            uint256 currentPrice;
            if (closePrice > openPrice) {
                currentPrice = openPrice + (priceStep * hour);
            } else {
                currentPrice = openPrice - (priceStep * hour);
            }
            
            updatePriceAndSkip(token, currentPrice, hourlyInterval);
        }
    }

    // ========== 使用时间工具函数的示例测试 ==========

    /**
     * @dev 使用时间工具函数的简化测试示例
     */
    function testTimeUtilitiesExample() public {
        uint256 startTime = getCurrentTime();
        
        // 使用工具函数简化时间操作
        twapContract.updatePrice(address(memeToken1), 1 ether);
        
        skipHours(2);
        twapContract.updatePrice(address(memeToken1), 1.5 ether);
        
        skipDays(1);
        twapContract.updatePrice(address(memeToken1), 2 ether);
        
        skipWeeks(1);
        twapContract.updatePrice(address(memeToken1), 1.8 ether);
        
        uint256 endTime = getCurrentTime();
        
        // 计算TWAP
        uint256 twapPrice = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        assertGt(twapPrice, 0, "TWAP should be greater than 0");
        
        console.log("Time utilities example TWAP:", twapPrice);
        console.log("Time elapsed (seconds):", endTime - startTime);
    }

    /**
     * @dev 使用批量更新工具的测试
     */
    function testBatchUpdateUtilities() public {
        uint256 startTime = getCurrentTime();
        
        // 创建多个代币和价格
        address[] memory tokens = new address[](3);
        tokens[0] = address(memeToken1);
        tokens[1] = address(memeToken2);
        tokens[2] = address(uint160(0x5000));
        
        uint256[] memory prices1 = new uint256[](3);
        prices1[0] = 1 ether;
        prices1[1] = 2 ether;
        prices1[2] = 0.5 ether;
        
        uint256[] memory prices2 = new uint256[](3);
        prices2[0] = 1.2 ether;
        prices2[1] = 2.3 ether;
        prices2[2] = 0.6 ether;
        
        // 使用批量更新工具
        updateMultiplePricesAndSkip(tokens, prices1, 3600); // 1小时后
        updateMultiplePricesAndSkip(tokens, prices2, 3600); // 再1小时后
        
        uint256 endTime = getCurrentTime();
        
        // 验证所有代币的TWAP
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenTWAP = twapContract.getTWAP(tokens[i], startTime, endTime);
            assertGt(tokenTWAP, 0, "Token TWAP should be greater than 0");
            console.log("Token TWAP:", tokenTWAP);
        }
    }

    /**
     * @dev 使用市场模拟工具的测试
     */
    function testMarketSimulationUtilities() public {
        uint256 startTime = getCurrentTime();
        
        // 模拟一个交易日：从1 ETH开盘，2 ETH收盘，交易8小时
        simulateMarketDay(address(memeToken1), 1 ether, 2 ether, 8);
        
        uint256 endTime = getCurrentTime();
        
        // 验证市场日TWAP
        uint256 marketDayTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        
        // TWAP应该在开盘价和收盘价之间
        assertGt(marketDayTWAP, 1 ether, "TWAP should be higher than opening price");
        assertLt(marketDayTWAP, 2 ether, "TWAP should be lower than closing price");
        
        console.log("Market day simulation TWAP:", marketDayTWAP);
        console.log("Trading hours: 8");
    }

    /**
     * @dev 使用时间序列工具的测试
     */
    function testTimeSeriesUtilities() public {
        uint256 startTime = getCurrentTime();
        
        // 创建价格序列
        uint256[] memory prices = new uint256[](5);
        prices[0] = 1 ether;
        prices[1] = 1.2 ether;
        prices[2] = 0.9 ether;
        prices[3] = 1.5 ether;
        prices[4] = 1.3 ether;
        
        // 创建时间间隔序列
        uint256[] memory intervals = new uint256[](5);
        intervals[0] = 1800;  // 30分钟
        intervals[1] = 3600;  // 1小时
        intervals[2] = 900;   // 15分钟
        intervals[3] = 7200;  // 2小时
        intervals[4] = 1800;  // 30分钟
        
        // 使用时间序列工具
        createTimeSeriesPrices(address(memeToken1), prices, intervals);
        
        uint256 endTime = getCurrentTime();
        
        // 验证时间序列TWAP
        uint256 timeSeriesTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        assertGt(timeSeriesTWAP, 0, "Time series TWAP should be greater than 0");
        
        console.log("Time series TWAP:", timeSeriesTWAP);
        console.log("Total time elapsed (seconds):", endTime - startTime);
    }
    
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

    // ========== 复杂时间模拟测试 ==========

    /**
     * @dev 测试不规则时间间隔的价格更新
     */
    function testIrregularTimeIntervals() public {
        uint256 startTime = block.timestamp;
        
        // 定义不规则的时间间隔（秒）
        uint256[] memory timeIntervals = new uint256[](6);
        timeIntervals[0] = 300;   // 5分钟
        timeIntervals[1] = 1800;  // 30分钟
        timeIntervals[2] = 600;   // 10分钟
        timeIntervals[3] = 3600;  // 1小时
        timeIntervals[4] = 900;   // 15分钟
        timeIntervals[5] = 7200;  // 2小时
        
        // 对应的价格数据
        uint256[] memory prices = new uint256[](6);
        prices[0] = 1.0 ether;
        prices[1] = 1.2 ether;
        prices[2] = 0.9 ether;
        prices[3] = 1.5 ether;
        prices[4] = 1.3 ether;
        prices[5] = 1.1 ether;
        
        uint256 currentTime = startTime;
        
        // 模拟不规则时间间隔的价格更新
        for (uint256 i = 0; i < timeIntervals.length; i++) {
            currentTime += timeIntervals[i];
            vm.warp(currentTime);
            twapContract.updatePrice(address(memeToken1), prices[i]);
        }
        
        // 验证历史记录数量
        uint256 historyLength = twapContract.getPriceHistoryLength(address(memeToken1));
        assertEq(historyLength, 6, "Should have 6 price records");
        
        // 计算整个时间段的TWAP
        uint256 twapPrice = twapContract.getTWAP(address(memeToken1), startTime, currentTime);
        assertGt(twapPrice, 0, "TWAP should be greater than 0");
        
        console.log("Irregular intervals TWAP:", twapPrice);
    }

    /**
     * @dev 测试高频交易场景
     */
    function testHighFrequencyTrading() public {
        uint256 startTime = block.timestamp;
        
        // 模拟高频交易：每分钟更新一次价格
        uint256 minuteInterval = 60; // 1分钟
        uint256 basePrice = 1 ether;
        
        // 30分钟内的高频更新
        for (uint256 i = 0; i < 30; i++) {
            vm.warp(block.timestamp + minuteInterval);
            
            // 模拟价格小幅波动 (±5%)
            uint256 priceVariation = (basePrice * 5) / 100; // 5%
            uint256 randomFactor = (i * 7) % 11; // 简单的伪随机数
            uint256 currentPrice = basePrice + (priceVariation * randomFactor) / 10 - priceVariation / 2;
            
            twapContract.updatePrice(address(memeToken1), currentPrice);
        }
        
        uint256 endTime = block.timestamp;
        
        // 验证历史记录
        uint256 historyLength = twapContract.getPriceHistoryLength(address(memeToken1));
        assertEq(historyLength, 30, "Should have 30 price records");
        
        // 计算高频交易期间的TWAP
        uint256 hftTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        assertGt(hftTWAP, 0, "HFT TWAP should be greater than 0");
        
        console.log("High frequency trading TWAP:", hftTWAP);
    }

    /**
     * @dev 测试市场开盘和收盘时间模拟
     */
    function testMarketHoursSimulation() public {
        uint256 startTime = block.timestamp;
        
        // 模拟一周的交易（5个工作日）
        uint256 dayInterval = 86400; // 1天
        uint256 hourInterval = 3600; // 1小时
        
        for (uint256 day = 0; day < 5; day++) {
            // 每天开盘时间（上午9点开始）
            uint256 marketOpen = startTime + (day * dayInterval) + (9 * hourInterval);
            
            // 模拟交易日内的价格变化（9小时交易时间）
            for (uint256 hour = 0; hour < 9; hour++) {
                uint256 tradeTime = marketOpen + (hour * hourInterval);
                vm.warp(tradeTime);
                
                // 模拟日内价格波动
                uint256 dayPrice = 1 ether + (day * 0.1 ether); // 每天基础价格递增
                uint256 hourlyVariation = (dayPrice * hour) / 100; // 小时内变化
                uint256 currentPrice = dayPrice + hourlyVariation;
                
                twapContract.updatePrice(address(memeToken1), currentPrice);
            }
        }
        
        uint256 endTime = block.timestamp;
        
        // 验证一周的交易记录
        uint256 historyLength = twapContract.getPriceHistoryLength(address(memeToken1));
        assertEq(historyLength, 45, "Should have 45 price records (5 days * 9 hours)");
        
        // 计算一周的TWAP
        uint256 weeklyTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        assertGt(weeklyTWAP, 0, "Weekly TWAP should be greater than 0");
        
        console.log("Weekly market hours TWAP:", weeklyTWAP);
    }

    /**
     * @dev 测试多代币并发交易
     */
    function testMultiTokenConcurrentTrading() public {
        uint256 startTime = block.timestamp;
        
        // 创建多个代币地址
        address[] memory tokens = new address[](3);
        tokens[0] = address(memeToken1);
        tokens[1] = address(memeToken2);
        tokens[2] = address(uint160(0x3000)); // 第三个代币
        
        // 基础价格
        uint256[] memory basePrices = new uint256[](3);
        basePrices[0] = 1 ether;
        basePrices[1] = 2 ether;
        basePrices[2] = 0.5 ether;
        
        // 模拟2小时的并发交易
        uint256 interval = 600; // 10分钟间隔
        
        for (uint256 i = 0; i < 12; i++) { // 12个时间点
            vm.warp(block.timestamp + interval);
            
            // 为每个代币更新价格
            for (uint256 j = 0; j < tokens.length; j++) {
                // 每个代币有不同的价格变化模式
                uint256 priceMultiplier = 100 + (i * (j + 1) * 5); // 不同的变化率
                uint256 currentPrice = (basePrices[j] * priceMultiplier) / 100;
                
                twapContract.updatePrice(tokens[j], currentPrice);
            }
        }
        
        uint256 endTime = block.timestamp;
        
        // 验证每个代币的历史记录
        for (uint256 k = 0; k < tokens.length; k++) {
            uint256 historyLength = twapContract.getPriceHistoryLength(tokens[k]);
            assertEq(historyLength, 12, "Each token should have 12 price records");
            
            // 计算每个代币的TWAP
            uint256 tokenTWAP = twapContract.getTWAP(tokens[k], startTime, endTime);
            assertGt(tokenTWAP, 0, "Token TWAP should be greater than 0");
            
            console.log("Token", k, "TWAP:", tokenTWAP);
        }
    }

    /**
     * @dev 测试极端时间跳跃场景
     */
    function testExtremeTimeJumps() public {
        uint256 startTime = block.timestamp;
        
        // 第一次价格更新
        twapContract.updatePrice(address(memeToken1), 1 ether);
        
        // 极大的时间跳跃（1年后）
        uint256 oneYear = 365 * 24 * 3600;
        vm.warp(block.timestamp + oneYear);
        twapContract.updatePrice(address(memeToken1), 2 ether);
        
        // 再次大跳跃（6个月后）
        uint256 sixMonths = 180 * 24 * 3600;
        vm.warp(block.timestamp + sixMonths);
        twapContract.updatePrice(address(memeToken1), 1.5 ether);
        
        uint256 endTime = block.timestamp;
        
        // 验证历史记录
        uint256 historyLength = twapContract.getPriceHistoryLength(address(memeToken1));
        assertEq(historyLength, 3, "Should have 3 price records");
        
        // 计算长期TWAP
        uint256 longTermTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        assertGt(longTermTWAP, 0, "Long term TWAP should be greater than 0");
        
        console.log("Extreme time jumps TWAP:", longTermTWAP);
    }

    /**
     * @dev 测试时间倒退保护
     */
    function testTimeReversalProtection() public {
        uint256 currentTime = block.timestamp;
        
        // 正常更新价格
        twapContract.updatePrice(address(memeToken1), 1 ether);
        
        // 向前跳跃时间
        vm.warp(currentTime + 3600);
        twapContract.updatePrice(address(memeToken1), 1.1 ether);
        
        // 尝试回到过去的时间（这应该不会影响TWAP计算）
        vm.warp(currentTime + 1800); // 回到中间时间点
        
        // 验证TWAP计算仍然正确
        uint256 twapPrice = twapContract.getTWAP(
            address(memeToken1), 
            currentTime, 
            currentTime + 3600
        );
         assertGt(twapPrice, 0, "TWAP should handle time inconsistencies");
     }

    // ========== 真实交易场景模拟 ==========

    /**
     * @dev 测试牛市场景
     */
    function testBullMarketScenario() public {
        uint256 startTime = block.timestamp;
        uint256 basePrice = 1 ether;
        
        // 模拟30天的牛市上涨
        uint256 dayInterval = 86400; // 1天
        
        for (uint256 day = 0; day < 30; day++) {
            vm.warp(block.timestamp + dayInterval);
            
            // 牛市特征：价格持续上涨，但有小幅回调
            uint256 trendMultiplier = 100 + (day * 3); // 每天上涨3%
            uint256 dailyVolatility = (day % 3 == 0) ? 95 : 105; // 偶尔回调5%，否则上涨5%
            
            uint256 currentPrice = (basePrice * trendMultiplier * dailyVolatility) / 10000;
            twapContract.updatePrice(address(memeToken1), currentPrice);
        }
        
        uint256 endTime = block.timestamp;
        
        // 验证牛市TWAP
        uint256 bullTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        assertGt(bullTWAP, basePrice, "Bull market TWAP should be higher than starting price");
        
        console.log("Bull market TWAP:", bullTWAP);
        console.log("Price appreciation:", ((bullTWAP - basePrice) * 100) / basePrice, "%");
    }

    /**
     * @dev 测试熊市场景
     */
    function testBearMarketScenario() public {
        uint256 startTime = block.timestamp;
        uint256 basePrice = 10 ether; // 从高价开始
        
        // 初始价格设置
        twapContract.updatePrice(address(memeToken1), basePrice);
        
        // 模拟20天的熊市下跌
        uint256 dayInterval = 86400; // 1天
        
        for (uint256 day = 1; day <= 20; day++) {
            vm.warp(block.timestamp + dayInterval);
            
            // 熊市特征：价格持续下跌，偶有反弹
            uint256 trendMultiplier = 100 - (day * 2); // 每天下跌2%
            uint256 dailyVolatility = (day % 4 == 0) ? 110 : 95; // 偶尔反弹10%，否则继续下跌5%
            
            uint256 currentPrice = (basePrice * trendMultiplier * dailyVolatility) / 10000;
            twapContract.updatePrice(address(memeToken1), currentPrice);
        }
        
        uint256 endTime = block.timestamp;
        
        // 验证熊市TWAP
        uint256 bearTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        assertLt(bearTWAP, basePrice, "Bear market TWAP should be lower than starting price");
        
        console.log("Bear market TWAP:", bearTWAP);
        console.log("Price decline:", ((basePrice - bearTWAP) * 100) / basePrice, "%");
    }

    /**
     * @dev 测试横盘震荡市场
     */
    function testSidewaysMarketScenario() public {
        uint256 startTime = block.timestamp;
        uint256 basePrice = 5 ether;
        
        // 初始价格设置
        twapContract.updatePrice(address(memeToken1), basePrice);
        
        // 模拟60天的横盘震荡
        uint256 dayInterval = 86400; // 1天
        
        for (uint256 day = 1; day <= 60; day++) {
            vm.warp(block.timestamp + dayInterval);
            
            // 横盘特征：价格在基准价格±10%范围内波动
            uint256 volatilityFactor = 90 + ((day * 7) % 21); // 90%-110%范围内波动
            uint256 currentPrice = (basePrice * volatilityFactor) / 100;
            
            twapContract.updatePrice(address(memeToken1), currentPrice);
        }
        
        uint256 endTime = block.timestamp;
        
        // 验证横盘TWAP应该接近基准价格
        uint256 sidewaysTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        
        // TWAP应该在基准价格的±15%范围内
        uint256 lowerBound = (basePrice * 85) / 100;
        uint256 upperBound = (basePrice * 115) / 100;
        
        assertGe(sidewaysTWAP, lowerBound, "Sideways TWAP should be within lower bound");
        assertLe(sidewaysTWAP, upperBound, "Sideways TWAP should be within upper bound");
        
        console.log("Sideways market TWAP:", sidewaysTWAP);
        console.log("Base price:", basePrice);
    }

    /**
     * @dev 测试闪崩和快速恢复场景
     */
    function testFlashCrashRecoveryScenario() public {
        uint256 startTime = block.timestamp;
        uint256 normalPrice = 2 ether;
        
        // 正常交易期（10天）
        uint256 dayInterval = 86400;
        for (uint256 day = 0; day < 10; day++) {
            vm.warp(block.timestamp + dayInterval);
            uint256 dailyPrice = normalPrice + ((day % 3) * 0.1 ether) - 0.1 ether; // 小幅波动
            twapContract.updatePrice(address(memeToken1), dailyPrice);
        }
        
        // 闪崩事件（价格暴跌80%）
        vm.warp(block.timestamp + dayInterval);
        uint256 crashPrice = (normalPrice * 20) / 100; // 下跌80%
        twapContract.updatePrice(address(memeToken1), crashPrice);
        
        // 快速恢复期（5天内恢复到正常水平）
        for (uint256 day = 0; day < 5; day++) {
            vm.warp(block.timestamp + dayInterval);
            uint256 recoveryMultiplier = 20 + (day * 16); // 从20%逐步恢复到100%
            uint256 recoveryPrice = (normalPrice * recoveryMultiplier) / 100;
            twapContract.updatePrice(address(memeToken1), recoveryPrice);
        }
        
        uint256 endTime = block.timestamp;
        
        // 验证闪崩期间的TWAP
        uint256 crashTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        
        // TWAP应该受到闪崩影响，但不会像瞬时价格那样极端
        assertLt(crashTWAP, normalPrice, "Flash crash should impact TWAP");
        assertGt(crashTWAP, crashPrice, "TWAP should be higher than crash price due to time weighting");
        
        console.log("Flash crash scenario TWAP:", crashTWAP);
        console.log("Normal price:", normalPrice);
        console.log("Crash price:", crashPrice);
    }

    /**
     * @dev 测试新代币上市场景
     */
    function testNewTokenListingScenario() public {
        uint256 startTime = block.timestamp;
        address newToken = address(uint160(0x4000));
        
        // 新代币上市：初始价格很低
        uint256 listingPrice = 0.01 ether;
        twapContract.updatePrice(newToken, listingPrice);
        
        // 第一周：价格发现阶段，高波动性
        uint256 hourInterval = 3600;
        uint256 currentPrice = listingPrice;
        
        for (uint256 hour = 1; hour <= 168; hour++) { // 7天 * 24小时
            vm.warp(block.timestamp + hourInterval);
            
            // 模拟高波动性：±50%的价格变化
            uint256 volatilityFactor = 50 + ((hour * 13) % 101); // 50%-150%范围
            currentPrice = (currentPrice * volatilityFactor) / 100;
            
            // 防止价格过低
            if (currentPrice < 0.001 ether) {
                currentPrice = 0.001 ether;
            }
            
            twapContract.updatePrice(newToken, currentPrice);
        }
        
        uint256 endTime = block.timestamp;
        
        // 验证新代币的TWAP
        uint256 newTokenTWAP = twapContract.getTWAP(newToken, startTime, endTime);
        assertGt(newTokenTWAP, 0, "New token TWAP should be greater than 0");
        
        uint256 historyLength = twapContract.getPriceHistoryLength(newToken);
        assertEq(historyLength, 169, "Should have 169 price records (1 + 168 hours)");
        
        console.log("New token listing TWAP:", newTokenTWAP);
        console.log("Listing price:", listingPrice);
        console.log("Final price:", currentPrice);
    }

    /**
     * @dev 测试市场操纵检测场景
     */
    function testMarketManipulationScenario() public {
        uint256 startTime = block.timestamp;
        uint256 normalPrice = 3 ether;
        
        // 正常交易期（建立基准）
        uint256 hourInterval = 3600;
        for (uint256 hour = 0; hour < 24; hour++) {
            vm.warp(block.timestamp + hourInterval);
            uint256 price = normalPrice + ((hour % 5) * 0.05 ether) - 0.1 ether; // 小幅正常波动
            twapContract.updatePrice(address(memeToken1), price);
        }
        
        // 记录正常期TWAP
        uint256 normalPeriodEnd = block.timestamp;
        uint256 normalTWAP = twapContract.getTWAP(address(memeToken1), startTime, normalPeriodEnd);
        
        // 疑似操纵期：异常的价格波动
        for (uint256 hour = 0; hour < 6; hour++) {
            vm.warp(block.timestamp + hourInterval);
            
            // 模拟pump and dump：先拉高后砸盘
            uint256 manipulationPrice;
            if (hour < 3) {
                // 拉高阶段：价格翻倍
                manipulationPrice = normalPrice * (2 + hour);
            } else {
                // 砸盘阶段：价格暴跌
                manipulationPrice = normalPrice / (hour - 1);
            }
            
            twapContract.updatePrice(address(memeToken1), manipulationPrice);
        }
        
        uint256 endTime = block.timestamp;
        
        // 验证操纵期间的TWAP
        uint256 manipulationTWAP = twapContract.getTWAP(address(memeToken1), normalPeriodEnd, endTime);
        uint256 overallTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        
        // TWAP应该能够平滑极端价格波动
        assertGt(manipulationTWAP, normalPrice / 2, "TWAP should smooth extreme price drops");
        assertLt(manipulationTWAP, normalPrice * 3, "TWAP should smooth extreme price pumps");
        
        console.log("Normal period TWAP:", normalTWAP);
         console.log("Manipulation period TWAP:", manipulationTWAP);
         console.log("Overall TWAP:", overallTWAP);
     }

    // ========== 高级TWAP计算验证测试 ==========

    /**
     * @dev 测试TWAP计算精度
     */
    function testTWAPCalculationPrecision() public {
        uint256 startTime = block.timestamp;
        
        // 使用精确的价格和时间间隔进行测试
        uint256[] memory precisePrices = new uint256[](4);
        precisePrices[0] = 1000000000000000000; // 1.000000000000000000 ETH
        precisePrices[1] = 1500000000000000000; // 1.500000000000000000 ETH
        precisePrices[2] = 2000000000000000000; // 2.000000000000000000 ETH
        precisePrices[3] = 1250000000000000000; // 1.250000000000000000 ETH
        
        uint256[] memory timeIntervals = new uint256[](4);
        timeIntervals[0] = 3600;  // 1小时
        timeIntervals[1] = 7200;  // 2小时
        timeIntervals[2] = 1800;  // 30分钟
        timeIntervals[3] = 5400;  // 1.5小时
        
        uint256 currentTime = startTime;
        
        // 更新价格
        for (uint256 i = 0; i < precisePrices.length; i++) {
            if (i > 0) {
                currentTime += timeIntervals[i-1];
                vm.warp(currentTime);
            }
            twapContract.updatePrice(address(memeToken1), precisePrices[i]);
        }
        
        // 手动计算期望的TWAP
        uint256 totalWeightedPrice = 0;
        uint256 totalTime = 0;
        
        for (uint256 i = 0; i < precisePrices.length - 1; i++) {
            totalWeightedPrice += precisePrices[i] * timeIntervals[i];
            totalTime += timeIntervals[i];
        }
        
        uint256 expectedTWAP = totalWeightedPrice / totalTime;
        uint256 actualTWAP = twapContract.getTWAP(address(memeToken1), startTime, currentTime);
        
        // 验证计算精度（允许小幅误差）
        uint256 tolerance = expectedTWAP / 1000; // 0.1%的容差
        assertApproxEqAbs(actualTWAP, expectedTWAP, tolerance, "TWAP calculation should be precise");
        
        console.log("Expected TWAP:", expectedTWAP);
        console.log("Actual TWAP:", actualTWAP);
    }

    /**
     * @dev 测试边界时间范围的TWAP计算
     */
    function testBoundaryTimeTWAP() public {
        uint256 startTime = block.timestamp;
        
        // 设置初始价格
        twapContract.updatePrice(address(memeToken1), 1 ether);
        
        // 1秒后更新价格
        vm.warp(block.timestamp + 1);
        twapContract.updatePrice(address(memeToken1), 2 ether);
        
        // 测试极短时间范围的TWAP
        uint256 shortTWAP = twapContract.getTWAP(address(memeToken1), startTime, startTime + 1);
        assertEq(shortTWAP, 1 ether, "Short time range TWAP should equal first price");
        
        // 测试单点时间的TWAP（应该失败）
        vm.expectRevert("Invalid time range");
        twapContract.getTWAP(address(memeToken1), startTime, startTime);
    }

    /**
     * @dev 测试大数值价格的TWAP计算
     */
    function testLargeValueTWAP() public {
        uint256 startTime = block.timestamp;
        
        // 使用大数值价格（接近uint256最大值的合理范围）
        uint256 largePrice1 = 1000000 ether;
        uint256 largePrice2 = 2000000 ether;
        uint256 largePrice3 = 1500000 ether;
        
        twapContract.updatePrice(address(memeToken1), largePrice1);
        
        vm.warp(block.timestamp + 3600);
        twapContract.updatePrice(address(memeToken1), largePrice2);
        
        vm.warp(block.timestamp + 3600);
        twapContract.updatePrice(address(memeToken1), largePrice3);
        
        uint256 endTime = block.timestamp;
        
        // 计算大数值的TWAP
        uint256 largeTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        
        // 验证TWAP在合理范围内
        assertGt(largeTWAP, largePrice1, "Large value TWAP should be greater than first price");
        assertLt(largeTWAP, largePrice2, "Large value TWAP should be less than peak price");
        
        console.log("Large value TWAP:", largeTWAP);
    }

    /**
     * @dev 测试多时间段TWAP比较
     */
    function testMultiPeriodTWAPComparison() public {
        uint256 startTime = block.timestamp;
        
        // 创建一个价格上升趋势
        uint256[] memory trendPrices = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            trendPrices[i] = 1 ether + (i * 0.1 ether); // 从1 ETH到1.9 ETH
        }
        
        // 每小时更新一次价格
        for (uint256 i = 0; i < trendPrices.length; i++) {
            if (i > 0) {
                vm.warp(block.timestamp + 3600);
            }
            twapContract.updatePrice(address(memeToken1), trendPrices[i]);
        }
        
        uint256 endTime = block.timestamp;
        
        // 计算不同时间段的TWAP
        uint256 firstHalfTWAP = twapContract.getTWAP(address(memeToken1), startTime, startTime + (5 * 3600));
        uint256 secondHalfTWAP = twapContract.getTWAP(address(memeToken1), startTime + (5 * 3600), endTime);
        uint256 fullPeriodTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        
        // 验证趋势关系
        assertLt(firstHalfTWAP, secondHalfTWAP, "Second half TWAP should be higher due to upward trend");
        assertGt(fullPeriodTWAP, firstHalfTWAP, "Full period TWAP should be higher than first half");
        assertLt(fullPeriodTWAP, secondHalfTWAP, "Full period TWAP should be lower than second half");
        
        console.log("First half TWAP:", firstHalfTWAP);
        console.log("Second half TWAP:", secondHalfTWAP);
        console.log("Full period TWAP:", fullPeriodTWAP);
    }

    /**
     * @dev 测试TWAP与简单平均价格的差异
     */
    function testTWAPvsSimpleAverage() public {
        uint256 startTime = block.timestamp;
        
        // 创建不等时间间隔的价格数据
        uint256[] memory prices = new uint256[](4);
        prices[0] = 1 ether;
        prices[1] = 4 ether;  // 高价格
        prices[2] = 2 ether;
        prices[3] = 1 ether;
        
        uint256[] memory intervals = new uint256[](3);
        intervals[0] = 7200;  // 2小时（长时间）
        intervals[1] = 600;   // 10分钟（短时间）
        intervals[2] = 3600;  // 1小时
        
        // 更新价格
        for (uint256 i = 0; i < prices.length; i++) {
            if (i > 0) {
                vm.warp(block.timestamp + intervals[i-1]);
            }
            twapContract.updatePrice(address(memeToken1), prices[i]);
        }
        
        uint256 endTime = block.timestamp;
        
        // 计算TWAP
        uint256 twapPrice = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        
        // 计算简单平均价格
        uint256 simpleAverage = (prices[0] + prices[1] + prices[2]) / 3; // 不包括最后一个价格
        
        // TWAP应该更接近长时间持续的价格
        // 由于第一个价格持续了2小时，TWAP应该更接近1 ether
        assertLt(twapPrice, simpleAverage, "TWAP should be lower than simple average due to time weighting");
        
        console.log("TWAP:", twapPrice);
        console.log("Simple Average:", simpleAverage);
        console.log("Difference:", simpleAverage > twapPrice ? simpleAverage - twapPrice : twapPrice - simpleAverage);
    }

    /**
     * @dev 测试连续相同价格的TWAP
     */
    function testConstantPriceTWAP() public {
        uint256 startTime = block.timestamp;
        uint256 constantPrice = 5 ether;
        
        // 连续24小时保持相同价格
        for (uint256 hour = 0; hour < 24; hour++) {
            vm.warp(block.timestamp + 3600);
            twapContract.updatePrice(address(memeToken1), constantPrice);
        }
        
        uint256 endTime = block.timestamp;
        
        // 计算TWAP
        uint256 constantTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        
        // TWAP应该等于常数价格
        assertEq(constantTWAP, constantPrice, "TWAP of constant price should equal the constant price");
        
        console.log("Constant price:", constantPrice);
        console.log("Constant TWAP:", constantTWAP);
    }

    /**
     * @dev 测试价格历史清理后的TWAP计算
     */
    function testTWAPAfterHistoryCleanup() public {
        uint256 startTime = block.timestamp;
        
        // 添加大量历史数据
        for (uint256 i = 0; i < 100; i++) {
            vm.warp(block.timestamp + 3600);
            uint256 price = 1 ether + ((i % 10) * 0.1 ether);
            twapContract.updatePrice(address(memeToken1), price);
        }
        
        uint256 midTime = block.timestamp;
        
        // 继续添加更多数据
        for (uint256 i = 0; i < 50; i++) {
            vm.warp(block.timestamp + 3600);
            uint256 price = 2 ether + ((i % 5) * 0.2 ether);
            twapContract.updatePrice(address(memeToken1), price);
        }
        
        uint256 endTime = block.timestamp;
        
        // 测试不同时间范围的TWAP
        uint256 earlyTWAP = twapContract.getTWAP(address(memeToken1), startTime, midTime);
        uint256 lateTWAP = twapContract.getTWAP(address(memeToken1), midTime, endTime);
        uint256 fullTWAP = twapContract.getTWAP(address(memeToken1), startTime, endTime);
        
        // 验证TWAP计算的一致性
        assertGt(lateTWAP, earlyTWAP, "Later period should have higher TWAP");
        assertGt(fullTWAP, earlyTWAP, "Full period TWAP should be higher than early period");
        
        console.log("Early period TWAP:", earlyTWAP);
        console.log("Late period TWAP:", lateTWAP);
        console.log("Full period TWAP:", fullTWAP);
        
        // 验证历史记录数量
        uint256 historyLength = twapContract.getPriceHistoryLength(address(memeToken1));
        assertEq(historyLength, 150, "Should have 150 price records");
    }
}