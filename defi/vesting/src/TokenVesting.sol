// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TokenVesting
 * @dev 代币归属合约，实现 12 个月 cliff 期和 24 个月线性释放
 * 
 * 释放规则：
 * - Cliff 期：12 个月，期间不释放任何代币
 * - 线性释放期：从第 13 个月开始，24 个月内每月释放 1/24 的代币
 * - 总归属期：36 个月（12 个月 cliff + 24 个月线性释放）
 */
contract TokenVesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // 事件
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingRevoked(address indexed beneficiary, uint256 unreleased, uint256 refund);

    // 状态变量
    IERC20 public immutable token;
    address public immutable beneficiary;
    uint256 public immutable start;
    uint256 public immutable cliff;
    uint256 public immutable duration;
    uint256 public immutable totalAmount;
    
    uint256 public released;
    bool public revoked;

    // 常量
    uint256 public constant CLIFF_DURATION = 365 days; // 12 个月 cliff
    uint256 public constant VESTING_DURATION = 730 days; // 24 个月线性释放
    uint256 public constant TOTAL_DURATION = CLIFF_DURATION + VESTING_DURATION; // 总共 36 个月

    /**
     * @dev 构造函数
     * @param _token 要归属的 ERC20 代币地址
     * @param _beneficiary 受益人地址
     * @param _totalAmount 总归属代币数量
     */
    constructor(
        IERC20 _token,
        address _beneficiary,
        uint256 _totalAmount
    ) Ownable(msg.sender) {
        require(address(_token) != address(0), "TokenVesting: token is zero address");
        require(_beneficiary != address(0), "TokenVesting: beneficiary is zero address");
        require(_totalAmount > 0, "TokenVesting: total amount is zero");

        token = _token;
        beneficiary = _beneficiary;
        totalAmount = _totalAmount;
        start = block.timestamp;
        cliff = start + CLIFF_DURATION;
        duration = TOTAL_DURATION;
    }

    /**
     * @dev 释放当前可释放的代币给受益人
     */
    function release() external nonReentrant {
        require(!revoked, "TokenVesting: vesting revoked");
        
        uint256 unreleased = _releasableAmount();
        require(unreleased > 0, "TokenVesting: no tokens are due");

        released += unreleased;
        token.safeTransfer(beneficiary, unreleased);

        emit TokensReleased(beneficiary, unreleased);
    }

    /**
     * @dev 撤销归属（仅限所有者）
     * 将未释放的代币退还给所有者
     */
    function revoke() external onlyOwner {
        require(!revoked, "TokenVesting: already revoked");

        uint256 unreleased = _releasableAmount();
        uint256 refund = totalAmount - released - unreleased;

        revoked = true;

        if (unreleased > 0) {
            released += unreleased;
            token.safeTransfer(beneficiary, unreleased);
        }

        if (refund > 0) {
            token.safeTransfer(owner(), refund);
        }

        emit VestingRevoked(beneficiary, unreleased, refund);
    }

    /**
     * @dev 获取当前可释放的代币数量
     */
    function releasableAmount() external view returns (uint256) {
        return _releasableAmount();
    }

    /**
     * @dev 获取已释放的代币数量
     */
    function releasedAmount() external view returns (uint256) {
        return released;
    }

    /**
     * @dev 获取已归属的代币数量（包括已释放和可释放）
     */
    function vestedAmount() external view returns (uint256) {
        return _vestedAmount(block.timestamp);
    }

    /**
     * @dev 获取剩余未归属的代币数量
     */
    function remainingAmount() external view returns (uint256) {
        return totalAmount - _vestedAmount(block.timestamp);
    }

    /**
     * @dev 检查是否在 cliff 期内
     */
    function isCliffPeriod() external view returns (bool) {
        return block.timestamp < cliff;
    }

    /**
     * @dev 检查归属是否完成
     */
    function isVestingComplete() external view returns (bool) {
        return block.timestamp >= start + duration;
    }

    /**
     * @dev 获取归属进度（百分比，基数为 10000）
     */
    function getVestingProgress() external view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        }
        if (block.timestamp >= start + duration) {
            return 10000; // 100%
        }
        
        uint256 vestingTime = block.timestamp - cliff;
        return (vestingTime * 10000) / VESTING_DURATION;
    }

    /**
     * @dev 内部函数：计算当前可释放的代币数量
     */
    function _releasableAmount() internal view returns (uint256) {
        return _vestedAmount(block.timestamp) - released;
    }

    /**
     * @dev 内部函数：计算指定时间点的已归属代币数量
     */
    function _vestedAmount(uint256 timestamp) internal view returns (uint256) {
        if (timestamp < cliff || revoked) {
            return 0;
        } else if (timestamp >= start + duration) {
            return totalAmount;
        } else {
            // 线性释放：从 cliff 结束后开始，在 VESTING_DURATION 期间内线性释放
            uint256 vestingTime = timestamp - cliff;
            return (totalAmount * vestingTime) / VESTING_DURATION;
        }
    }
}