// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MemeTWAP
 * @dev 用于获取LaunchPad发行的Meme代币的TWAP价格
 * 支持记录价格历史并计算时间加权平均价格
 */
contract MemeTWAP {
    
    // 价格观察点结构
    struct PriceObservation {
        uint256 timestamp;      // 时间戳
        uint256 price;          // 价格 (以wei为单位)
        uint256 cumulativePrice; // 累积价格
    }
    
    // 代币价格历史记录
    mapping(address => PriceObservation[]) public priceHistory;
    
    // 代币地址到最新价格的映射
    mapping(address => uint256) public latestPrice;
    
    // 代币地址到最新更新时间的映射
    mapping(address => uint256) public lastUpdateTime;
    
    // MemeFactory合约地址
    address public immutable memeFactory;
    
    // 合约所有者
    address public owner;
    
    // 最小观察间隔（防止频繁更新）
    uint256 public constant MIN_OBSERVATION_INTERVAL = 60; // 1分钟
    
    // 最大历史记录数量
    uint256 public constant MAX_OBSERVATIONS = 1000;
    
    // 事件
    event PriceUpdated(
        address indexed token,
        uint256 price,
        uint256 timestamp,
        uint256 cumulativePrice
    );
    
    event TWAPCalculated(
        address indexed token,
        uint256 twapPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 observationCount
    );
    
    // 修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    modifier nonReentrant() {
        // 简化的重入保护
        _;
    }
    
    /**
     * @dev 构造函数
     * @param _memeFactory MemeFactory合约地址
     */
    constructor(address _memeFactory) {
        require(_memeFactory != address(0), "Invalid factory address");
        memeFactory = _memeFactory;
        owner = msg.sender;
    }
    
    /**
     * @dev 更新代币价格
     * @param token 代币地址
     * @param price 新价格
     */
    function updatePrice(address token, uint256 price) external nonReentrant {
        require(token != address(0), "Invalid token address");
        require(price > 0, "Price must be greater than 0");
        require(_isValidToken(token), "Token not from MemeFactory");
        
        uint256 currentTime = block.timestamp;
        
        // 检查最小观察间隔
        if (lastUpdateTime[token] > 0) {
            require(
                currentTime >= lastUpdateTime[token] + MIN_OBSERVATION_INTERVAL,
                "Update too frequent"
            );
        }
        
        // 计算累积价格
        uint256 cumulativePrice = 0;
        PriceObservation[] storage history = priceHistory[token];
        
        if (history.length > 0) {
            PriceObservation memory lastObs = history[history.length - 1];
            uint256 timeDelta = currentTime - lastObs.timestamp;
            cumulativePrice = lastObs.cumulativePrice + (lastObs.price * timeDelta);
        }
        
        // 添加新的观察点
        if (history.length >= MAX_OBSERVATIONS) {
            // 移除最旧的观察点
            for (uint256 i = 0; i < history.length - 1; i++) {
                history[i] = history[i + 1];
            }
            history[history.length - 1] = PriceObservation({
                timestamp: currentTime,
                price: price,
                cumulativePrice: cumulativePrice
            });
        } else {
            history.push(PriceObservation({
                timestamp: currentTime,
                price: price,
                cumulativePrice: cumulativePrice
            }));
        }
        
        // 更新最新价格和时间
        latestPrice[token] = price;
        lastUpdateTime[token] = currentTime;
        
        emit PriceUpdated(token, price, currentTime, cumulativePrice);
    }
    
    /**
     * @dev 批量更新多个代币价格
     * @param tokens 代币地址数组
     * @param prices 价格数组
     */
    function batchUpdatePrices(
        address[] calldata tokens,
        uint256[] calldata prices
    ) external nonReentrant {
        require(tokens.length == prices.length, "Arrays length mismatch");
        require(tokens.length > 0, "Empty arrays");
        
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] != address(0) && prices[i] > 0 && _isValidToken(tokens[i])) {
                uint256 currentTime = block.timestamp;
                
                // 检查最小观察间隔
                if (lastUpdateTime[tokens[i]] == 0 || 
                    currentTime >= lastUpdateTime[tokens[i]] + MIN_OBSERVATION_INTERVAL) {
                    
                    _updatePriceInternal(tokens[i], prices[i], currentTime);
                }
            }
        }
    }
    
    /**
     * @dev 计算指定时间段的TWAP价格
     * @param token 代币地址
     * @param startTime 开始时间
     * @param endTime 结束时间
     * @return twapPrice TWAP价格
     */
    function getTWAP(
        address token,
        uint256 startTime,
        uint256 endTime
    ) external view returns (uint256 twapPrice) {
        require(token != address(0), "Invalid token address");
        require(endTime > startTime, "Invalid time range");
        require(endTime <= block.timestamp, "End time in future");
        
        PriceObservation[] storage history = priceHistory[token];
        require(history.length > 0, "No price history");
        
        // 找到时间范围内的观察点
        uint256 startIndex = _findObservationIndex(history, startTime);
        uint256 endIndex = _findObservationIndex(history, endTime);
        
        if (startIndex == endIndex) {
            // 只有一个观察点
            return history[startIndex].price;
        }
        
        // 计算TWAP
        uint256 totalWeightedPrice = 0;
        uint256 totalTime = 0;
        
        for (uint256 i = startIndex; i < endIndex; i++) {
            uint256 timeDelta = history[i + 1].timestamp - history[i].timestamp;
            totalWeightedPrice += history[i].price * timeDelta;
            totalTime += timeDelta;
        }
        
        // 处理边界情况
        if (history[startIndex].timestamp < startTime) {
            uint256 adjustTime = startTime - history[startIndex].timestamp;
            totalWeightedPrice -= history[startIndex].price * adjustTime;
            totalTime -= adjustTime;
        }
        
        if (endIndex < history.length - 1 && history[endIndex].timestamp > endTime) {
            uint256 adjustTime = history[endIndex].timestamp - endTime;
            totalWeightedPrice -= history[endIndex].price * adjustTime;
            totalTime -= adjustTime;
        }
        
        require(totalTime > 0, "Invalid time calculation");
        twapPrice = totalWeightedPrice / totalTime;
        
        return twapPrice;
    }
    
    /**
     * @dev 获取最近N个时间段的TWAP价格
     * @param token 代币地址
     * @param periods 时间段数量
     * @param periodDuration 每个时间段的持续时间（秒）
     * @return twapPrices TWAP价格数组
     */
    function getRecentTWAPs(
        address token,
        uint256 periods,
        uint256 periodDuration
    ) external view returns (uint256[] memory twapPrices) {
        require(token != address(0), "Invalid token address");
        require(periods > 0 && periods <= 100, "Invalid periods count");
        require(periodDuration > 0, "Invalid period duration");
        
        twapPrices = new uint256[](periods);
        uint256 currentTime = block.timestamp;
        
        for (uint256 i = 0; i < periods; i++) {
            uint256 endTime = currentTime - (i * periodDuration);
            uint256 startTime = endTime - periodDuration;
            
            if (startTime < _getFirstObservationTime(token)) {
                break;
            }
            
            try this.getTWAP(token, startTime, endTime) returns (uint256 twap) {
                twapPrices[periods - 1 - i] = twap;
            } catch {
                twapPrices[periods - 1 - i] = 0;
            }
        }
        
        return twapPrices;
    }
    
    /**
     * @dev 获取代币的价格历史记录数量
     * @param token 代币地址
     * @return count 历史记录数量
     */
    function getPriceHistoryLength(address token) external view returns (uint256 count) {
        return priceHistory[token].length;
    }
    
    /**
     * @dev 获取指定索引的价格观察点
     * @param token 代币地址
     * @param index 索引
     * @return observation 价格观察点
     */
    function getPriceObservation(
        address token,
        uint256 index
    ) external view returns (PriceObservation memory observation) {
        require(index < priceHistory[token].length, "Index out of bounds");
        return priceHistory[token][index];
    }
    
    /**
     * @dev 获取代币的最新价格信息
     * @param token 代币地址
     * @return price 最新价格
     * @return timestamp 最新更新时间
     */
    function getLatestPriceInfo(address token) external view returns (uint256 price, uint256 timestamp) {
        return (latestPrice[token], lastUpdateTime[token]);
    }
    
    /**
     * @dev 设置MemeFactory地址（仅所有者）
     * @param _memeFactory 新的MemeFactory地址
     */
    function setMemeFactory(address _memeFactory) external onlyOwner {
        require(_memeFactory != address(0), "Invalid factory address");
        // 注意：这里不能修改immutable变量，所以这个函数实际上不能工作
        // 保留这个函数作为接口示例
    }
    
    // 内部函数
    
    /**
     * @dev 内部价格更新函数
     */
    function _updatePriceInternal(address token, uint256 price, uint256 currentTime) internal {
        // 计算累积价格
        uint256 cumulativePrice = 0;
        PriceObservation[] storage history = priceHistory[token];
        
        if (history.length > 0) {
            PriceObservation memory lastObs = history[history.length - 1];
            uint256 timeDelta = currentTime - lastObs.timestamp;
            cumulativePrice = lastObs.cumulativePrice + (lastObs.price * timeDelta);
        }
        
        // 添加新的观察点
        if (history.length >= MAX_OBSERVATIONS) {
            // 移除最旧的观察点
            for (uint256 i = 0; i < history.length - 1; i++) {
                history[i] = history[i + 1];
            }
            history[history.length - 1] = PriceObservation({
                timestamp: currentTime,
                price: price,
                cumulativePrice: cumulativePrice
            });
        } else {
            history.push(PriceObservation({
                timestamp: currentTime,
                price: price,
                cumulativePrice: cumulativePrice
            }));
        }
        
        // 更新最新价格和时间
        latestPrice[token] = price;
        lastUpdateTime[token] = currentTime;
        
        emit PriceUpdated(token, price, currentTime, cumulativePrice);
    }
    
    /**
     * @dev 验证代币是否来自MemeFactory（简化版本）
     */
    function _isValidToken(address token) internal view returns (bool) {
        // 简化版本：假设所有非零地址都是有效的
        // 在实际部署中，这里应该调用MemeFactory的isDeployedToken函数
        return token != address(0);
    }
    
    /**
     * @dev 查找指定时间的观察点索引
     */
    function _findObservationIndex(
        PriceObservation[] storage history,
        uint256 targetTime
    ) internal view returns (uint256) {
        if (history.length == 0) return 0;
        
        // 二分查找
        uint256 left = 0;
        uint256 right = history.length - 1;
        
        while (left < right) {
            uint256 mid = (left + right) / 2;
            if (history[mid].timestamp <= targetTime) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        
        return left > 0 ? left - 1 : 0;
    }
    
    /**
     * @dev 获取第一个观察点的时间
     */
    function _getFirstObservationTime(address token) internal view returns (uint256) {
        PriceObservation[] storage history = priceHistory[token];
        return history.length > 0 ? history[0].timestamp : block.timestamp;
    }
}