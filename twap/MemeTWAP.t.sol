// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// 简化的测试框架，不依赖forge-std
contract MemeTWAPTest {
    MemeTWAP public twapContract;
    MockMemeToken public memeToken1;
    MockMemeToken public memeToken2;
    
    address public owner;
    address public user1;
    address public user2;
    
    // 测试用的价格数据
    uint256[] public testPrices = [
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
    
    // 事件
    event TestResult(string testName, bool passed, string message);
    
    constructor() {
        owner = msg.sender;
        user1 = address(0x1);
        user2 = address(0x2);
        
        // 部署合约
        twapContract = new MemeTWAP(address(0x123)); // Mock factory address
        memeToken1 = new MockMemeToken("TEST1", "T1");
        memeToken2 = new MockMemeToken("TEST2", "T2");
    }
    
    /**
     * @dev 运行所有测试
     */
    function runAllTests() external {
        testBasicPriceUpdate();
        testBatchPriceUpdate();
        testMultipleTimePointsAndTWAP();
        testLongTermTWAP();
        testRecentTWAPs();
        testUpdateFrequencyLimit();
        testInvalidInputs();
        testEdgeCaseTWAP();
        testLargeScalePriceUpdates();
        testMultipleTokensTWAP();
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
        
        bool passed = (latestPrice == initialPrice && timestamp == block.timestamp);
        emit TestResult("testBasicPriceUpdate", passed, passed ? "Success" : "Price or timestamp mismatch");
        
        // 验证历史记录
        uint256 historyLength = twapContract.getPriceHistoryLength(address(memeToken1));
        bool historyPassed = (historyLength == 1);
        emit TestResult("testBasicPriceUpdate_History", historyPassed, historyPassed ? "Success" : "History length incorrect");
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
        
        bool passed = (latestPrice1 == 1.5 ether && latestPrice2 == 2.0 ether);
        emit TestResult("testBatchPriceUpdate", passed, passed ? "Success" : "Batch update failed");
    }
    
    /**
     * @dev 测试多个时间点的价格更新和TWAP计算
     */
    function testMultipleTimePointsAndTWAP() public {
        uint256 startTime = block.timestamp;
        
        // 模拟多个时间点的价格更新
        for (uint256 i = 0; i < 4; i++) { // 只测试前4个价格点
            // 跳过时间间隔
            if (i > 0) {
                // 模拟时间推进
                _advanceTime(TIME_INTERVAL);
            }
            
            // 更新价格
            twapContract.updatePrice(address(memeToken1), testPrices[i]);
        }
        
        // 验证历史记录数量
        uint256 historyLength = twapContract.getPriceHistoryLength(address(memeToken1));
        bool historyPassed = (historyLength == 4);
        emit TestResult("testMultipleTimePoints_History", historyPassed, historyPassed ? "Success" : "History count incorrect");
        
        // 计算前3个时间段的TWAP
        uint256 twapStartTime = startTime;
        uint256 twapEndTime = startTime + (3 * TIME_INTERVAL);
        
        uint256 twapPrice = twapContract.getTWAP(address(memeToken1), twapStartTime, twapEndTime);
        
        // 手动计算预期的TWAP: (1 + 1.5 + 2) / 3 = 1.5 ETH
        uint256 expectedTWAP = 1.5 ether;
        
        bool twapPassed = _isApproxEqual(twapPrice, expectedTWAP, 0.1 ether); // 10% 误差容忍
        emit TestResult("testMultipleTimePoints_TWAP", twapPassed, twapPassed ? "Success" : "TWAP calculation incorrect");
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
            _advanceTime(hourlyInterval);
            uint256 price = 1 ether + (i * 0.1 ether); // 递增价格
            twapContract.updatePrice(address(memeToken1), price);
        }
        
        // 计算12小时的TWAP
        uint256 twap12h = twapContract.getTWAP(
            address(memeToken1),
            startTime,
            startTime + (11 * hourlyInterval)
        );
        
        bool passed = (twap12h > 0.5 ether && twap12h < 3 ether);
        emit TestResult("testLongTermTWAP", passed, passed ? "Success" : "Long term TWAP out of range");
    }
    
    /**
     * @dev 测试获取最近N个时间段的TWAP
     */
    function testRecentTWAPs() public {
        uint256 startTime = block.timestamp;
        
        // 模拟5个时间点的价格更新
        for (uint256 i = 0; i < 5; i++) {
            _advanceTime(TIME_INTERVAL);
            uint256 price = 1 ether + (i * 0.1 ether); // 递增价格
            twapContract.updatePrice(address(memeToken1), price);
        }
        
        // 获取最近3个时间段的TWAP
        uint256[] memory recentTWAPs = twapContract.getRecentTWAPs(
            address(memeToken1),
            3,
            TIME_INTERVAL
        );
        
        bool passed = (recentTWAPs.length == 3);
        emit TestResult("testRecentTWAPs", passed, passed ? "Success" : "Recent TWAPs array length incorrect");
    }
    
    /**
     * @dev 测试价格更新频率限制
     */
    function testUpdateFrequencyLimit() public {
        uint256 initialPrice = 1 ether;
        
        // 第一次更新应该成功
        twapContract.updatePrice(address(memeToken1), initialPrice);
        
        // 立即再次更新应该失败（频率限制）
        bool failed = false;
        try twapContract.updatePrice(address(memeToken1), initialPrice + 0.1 ether) {
            failed = false;
        } catch {
            failed = true;
        }
        
        emit TestResult("testUpdateFrequencyLimit_Immediate", failed, failed ? "Success" : "Should have failed due to frequency limit");
        
        // 等待足够时间后应该成功
        _advanceTime(61); // 等待61秒
        
        bool success = true;
        try twapContract.updatePrice(address(memeToken1), initialPrice + 0.1 ether) {
            success = true;
        } catch {
            success = false;
        }
        
        emit TestResult("testUpdateFrequencyLimit_Delayed", success, success ? "Success" : "Should have succeeded after delay");
    }
    
    /**
     * @dev 测试无效输入的处理
     */
    function testInvalidInputs() public {
        // 测试无效代币地址
        bool failed1 = false;
        try twapContract.updatePrice(address(0), 1 ether) {
            failed1 = false;
        } catch {
            failed1 = true;
        }
        emit TestResult("testInvalidInputs_ZeroAddress", failed1, failed1 ? "Success" : "Should have failed for zero address");
        
        // 测试零价格
        bool failed2 = false;
        try twapContract.updatePrice(address(memeToken1), 0) {
            failed2 = false;
        } catch {
            failed2 = true;
        }
        emit TestResult("testInvalidInputs_ZeroPrice", failed2, failed2 ? "Success" : "Should have failed for zero price");
    }
    
    /**
     * @dev 测试边界情况的TWAP计算
     */
    function testEdgeCaseTWAP() public {
        uint256 startTime = block.timestamp;
        
        // 只有一个价格点
        twapContract.updatePrice(address(memeToken1), 1 ether);
        
        // 尝试计算TWAP（应该返回该价格）
        uint256 twap = twapContract.getTWAP(address(memeToken1), startTime, startTime + 1);
        
        bool passed = (twap == 1 ether);
        emit TestResult("testEdgeCaseTWAP_SinglePoint", passed, passed ? "Success" : "Single point TWAP incorrect");
    }
    
    /**
     * @dev 测试大量价格更新的性能
     */
    function testLargeScalePriceUpdates() public {
        uint256 startTime = block.timestamp;
        uint256 updateCount = 50; // 减少数量以避免gas限制
        
        // 大量价格更新
        for (uint256 i = 0; i < updateCount; i++) {
            _advanceTime(61); // 每61秒更新一次
            uint256 price = 1 ether + ((i % 10) * 0.1 ether); // 循环价格
            twapContract.updatePrice(address(memeToken1), price);
        }
        
        // 验证历史记录数量
        uint256 historyLength = twapContract.getPriceHistoryLength(address(memeToken1));
        bool passed = (historyLength == updateCount);
        
        emit TestResult("testLargeScalePriceUpdates", passed, passed ? "Success" : "Large scale updates failed");
    }
    
    /**
     * @dev 测试多个代币的TWAP计算
     */
    function testMultipleTokensTWAP() public {
        uint256 startTime = block.timestamp;
        
        // 为两个代币更新价格
        for (uint256 i = 0; i < 3; i++) {
            _advanceTime(TIME_INTERVAL);
            
            // 代币1价格递增
            twapContract.updatePrice(address(memeToken1), (i + 1) * 1 ether);
            
            // 代币2价格递减
            twapContract.updatePrice(address(memeToken2), (3 - i) * 1 ether);
        }
        
        // 计算两个代币的TWAP
        uint256 twap1 = twapContract.getTWAP(
            address(memeToken1),
            startTime,
            startTime + (2 * TIME_INTERVAL)
        );
        
        uint256 twap2 = twapContract.getTWAP(
            address(memeToken2),
            startTime,
            startTime + (2 * TIME_INTERVAL)
        );
        
        // 验证两个代币的TWAP不同
        bool passed = (twap1 != twap2 && twap1 > 0 && twap2 > 0);
        emit TestResult("testMultipleTokensTWAP", passed, passed ? "Success" : "Multiple tokens TWAP failed");
    }
    
    // 辅助函数
    
    /**
     * @dev 模拟时间推进（在实际测试中需要使用测试框架的时间控制）
     */
    function _advanceTime(uint256 seconds_) internal {
        // 在实际测试环境中，这里应该使用测试框架的时间控制功能
        // 这里只是一个占位符
    }
    
    /**
     * @dev 检查两个数值是否近似相等
     */
    function _isApproxEqual(uint256 a, uint256 b, uint256 tolerance) internal pure returns (bool) {
        if (a > b) {
            return (a - b) <= tolerance;
        } else {
            return (b - a) <= tolerance;
        }
    }
}

/**
 * @dev Mock代币合约用于测试
 */
contract MockMemeToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        totalSupply = 1000000 * 10**18;
    }
}

// 导入TWAP合约
import "./MemeTWAP.sol";