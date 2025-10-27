// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IRebaseToken
 * @dev Interface for rebase token with deflation mechanism
 */
interface IRebaseToken is IERC20 {
    /**
     * @dev Emitted when rebase occurs
     * @param newTotalSupply The new total supply after rebase
     * @param supplyDelta The amount of supply change (positive for inflation, negative for deflation)
     */
    event Rebase(uint256 newTotalSupply, uint256 supplyDelta);

    /**
     * @dev Emitted when shares are transferred
     * @param from The address shares are transferred from
     * @param to The address shares are transferred to
     * @param shares The amount of shares transferred
     */
    event SharesTransfer(address indexed from, address indexed to, uint256 shares);

    /**
     * @dev Returns the amount of shares owned by account
     * @param account The address to query shares for
     * @return The amount of shares owned by account
     */
    function sharesOf(address account) external view returns (uint256);

    /**
     * @dev Returns the total amount of shares
     * @return The total amount of shares
     */
    function totalShares() external view returns (uint256);

    /**
     * @dev Converts amount to shares
     * @param amount The amount to convert
     * @return The equivalent amount of shares
     */
    function getSharesByAmount(uint256 amount) external view returns (uint256);

    /**
     * @dev Converts shares to amount
     * @param shares The shares to convert
     * @return The equivalent amount
     */
    function getAmountByShares(uint256 shares) external view returns (uint256);

    /**
     * @dev Performs rebase operation (deflation)
     * @return The new total supply after rebase
     */
    function rebase() external returns (uint256);

    /**
     * @dev Checks if rebase can be performed
     * @return True if rebase can be performed, false otherwise
     */
    function canRebase() external view returns (bool);

    /**
     * @dev Returns the last rebase timestamp
     * @return The timestamp of the last rebase
     */
    function lastRebaseTime() external view returns (uint256);

    /**
     * @dev Returns the rebase interval in seconds
     * @return The rebase interval
     */
    function rebaseInterval() external view returns (uint256);

    /**
     * @dev Returns the deflation rate (numerator and denominator)
     * @return numerator The deflation rate numerator
     * @return denominator The deflation rate denominator
     */
    function deflationRate() external view returns (uint256 numerator, uint256 denominator);
}