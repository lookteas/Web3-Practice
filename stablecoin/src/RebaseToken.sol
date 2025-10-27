// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IRebaseToken.sol";

/**
 * @title RebaseToken
 * @dev A deflationary rebase token that reduces supply by 1% annually
 * @author Web3 Practice
 */
contract RebaseToken is ERC20, Ownable, ReentrancyGuard, IRebaseToken {
    // ============ State Variables ============
    
    /// @dev Mapping from account to the amount of shares owned by account
    mapping(address => uint256) private _shares;
    
    /// @dev Total amount of shares
    uint256 private _totalShares;
    
    /// @dev Current total supply (changes with rebase)
    uint256 private _currentTotalSupply;
    
    /// @dev Timestamp of the last rebase
    uint256 public lastRebaseTime;
    
    /// @dev Rebase interval (1 year = 365 days)
    uint256 public constant REBASE_INTERVAL = 365 days;
    
    /// @dev Deflation rate: 99/100 = 0.99 (1% deflation)
    uint256 public constant DEFLATION_NUMERATOR = 99;
    uint256 public constant DEFLATION_DENOMINATOR = 100;
    
    // ============ Events ============
    
    // Events are inherited from IRebaseToken interface
    
    // ============ Constructor ============
    
    /**
     * @dev Constructor
     * @param name_ Token name
     * @param symbol_ Token symbol
     * @param initialSupply_ Initial supply (with 18 decimals)
     * @param initialOwner_ Initial owner address
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        address initialOwner_
    ) ERC20(name_, symbol_) Ownable(initialOwner_) {
        require(initialSupply_ > 0, "Initial supply must be greater than 0");
        require(initialOwner_ != address(0), "Initial owner cannot be zero address");
        
        _currentTotalSupply = initialSupply_;
        _totalShares = initialSupply_;
        _shares[initialOwner_] = initialSupply_;
        lastRebaseTime = block.timestamp;
        
        emit Transfer(address(0), initialOwner_, initialSupply_);
    }
    
    // ============ View Functions ============
    
    /**
     * @dev Returns the total supply
     */
    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        return _currentTotalSupply;
    }
    
    /**
     * @dev Returns the balance of account
     */
    function balanceOf(address account) public view override(ERC20, IERC20) returns (uint256) {
        if (_totalShares == 0) {
            return 0;
        }
        return (_shares[account] * _currentTotalSupply) / _totalShares;
    }
    
    /**
     * @dev Returns the amount of shares owned by account
     */
    function sharesOf(address account) public view override returns (uint256) {
        return _shares[account];
    }
    
    /**
     * @dev Returns the total amount of shares
     */
    function totalShares() public view override returns (uint256) {
        return _totalShares;
    }
    
    /**
     * @dev Converts amount to shares
     */
    function getSharesByAmount(uint256 amount) public view override returns (uint256) {
        if (_currentTotalSupply == 0) {
            return amount;
        }
        return (amount * _totalShares) / _currentTotalSupply;
    }
    
    /**
     * @dev Converts shares to amount
     */
    function getAmountByShares(uint256 shares) public view override returns (uint256) {
        if (_totalShares == 0) {
            return 0;
        }
        return (shares * _currentTotalSupply) / _totalShares;
    }
    
    /**
     * @dev Checks if rebase can be performed
     */
    function canRebase() public view override returns (bool) {
        return block.timestamp >= lastRebaseTime + REBASE_INTERVAL;
    }
    
    /**
     * @dev Returns the rebase interval in seconds
     */
    function rebaseInterval() public pure override returns (uint256) {
        return REBASE_INTERVAL;
    }
    
    /**
     * @dev Returns the deflation rate (numerator and denominator)
     */
    function deflationRate() public pure override returns (uint256 numerator, uint256 denominator) {
        return (DEFLATION_NUMERATOR, DEFLATION_DENOMINATOR);
    }
    
    // ============ Rebase Functions ============
    
    /**
     * @dev Performs rebase operation (deflation)
     * @return The new total supply after rebase
     */
    function rebase() public override nonReentrant returns (uint256) {
        require(canRebase(), "RebaseToken: Rebase not available yet");
        
        uint256 oldTotalSupply = _currentTotalSupply;
        uint256 newTotalSupply = (oldTotalSupply * DEFLATION_NUMERATOR) / DEFLATION_DENOMINATOR;
        uint256 supplyDelta = oldTotalSupply - newTotalSupply;
        
        _currentTotalSupply = newTotalSupply;
        lastRebaseTime = block.timestamp;
        
        emit Rebase(newTotalSupply, supplyDelta);
        
        return newTotalSupply;
    }
    
    // ============ Transfer Functions ============
    
    /**
     * @dev Transfers tokens from sender to recipient
     */
    function transfer(address to, uint256 amount) public override(ERC20, IERC20) returns (bool) {
        address owner = _msgSender();
        _transferAmount(owner, to, amount);
        return true;
    }
    
    /**
     * @dev Transfers tokens from sender to recipient using allowance
     */
    function transferFrom(address from, address to, uint256 amount) public override(ERC20, IERC20) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transferAmount(from, to, amount);
        return true;
    }
    
    /**
     * @dev Internal function to transfer amount (converts to shares)
     */
    function _transferAmount(address from, address to, uint256 amount) internal {
        uint256 shares = getSharesByAmount(amount);
        _transferShares(from, to, shares);
    }
    
    /**
     * @dev Internal function to transfer shares
     */
    function _transferShares(address from, address to, uint256 shares) internal {
        require(from != address(0), "RebaseToken: Transfer from zero address");
        require(to != address(0), "RebaseToken: Transfer to zero address");
        require(_shares[from] >= shares, "RebaseToken: Transfer amount exceeds balance");
        
        _shares[from] -= shares;
        _shares[to] += shares;
        
        uint256 amount = getAmountByShares(shares);
        
        emit Transfer(from, to, amount);
        emit SharesTransfer(from, to, shares);
    }
    
    // ============ Mint and Burn Functions ============
    
    /**
     * @dev Mints tokens to account (only owner)
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "RebaseToken: Mint to zero address");
        require(amount > 0, "RebaseToken: Mint amount must be greater than 0");
        
        uint256 shares = getSharesByAmount(amount);
        
        _totalShares += shares;
        _shares[to] += shares;
        _currentTotalSupply += amount;
        
        emit Transfer(address(0), to, amount);
        emit SharesTransfer(address(0), to, shares);
    }
    
    /**
     * @dev Burns tokens from account (only owner)
     */
    function burn(address from, uint256 amount) public onlyOwner {
        require(from != address(0), "RebaseToken: Burn from zero address");
        require(amount > 0, "RebaseToken: Burn amount must be greater than 0");
        
        uint256 shares = getSharesByAmount(amount);
        require(_shares[from] >= shares, "RebaseToken: Burn amount exceeds balance");
        
        _totalShares -= shares;
        _shares[from] -= shares;
        _currentTotalSupply -= amount;
        
        emit Transfer(from, address(0), amount);
        emit SharesTransfer(from, address(0), shares);
    }
    
    /**
     * @dev Burns tokens from sender
     */
    function burnSelf(uint256 amount) public {
        require(amount > 0, "RebaseToken: Burn amount must be greater than 0");
        
        uint256 shares = getSharesByAmount(amount);
        require(_shares[_msgSender()] >= shares, "RebaseToken: Burn amount exceeds balance");
        
        _totalShares -= shares;
        _shares[_msgSender()] -= shares;
        _currentTotalSupply -= amount;
        
        emit Transfer(_msgSender(), address(0), amount);
        emit SharesTransfer(_msgSender(), address(0), shares);
    }
    
    // ============ Utility Functions ============
    
    /**
     * @dev Returns the number of years since deployment
     */
    function getYearsSinceDeployment() public view returns (uint256) {
        return (block.timestamp - lastRebaseTime) / REBASE_INTERVAL;
    }
    
    /**
     * @dev Returns the time until next rebase
     */
    function getTimeUntilNextRebase() public view returns (uint256) {
        if (canRebase()) {
            return 0;
        }
        return (lastRebaseTime + REBASE_INTERVAL) - block.timestamp;
    }
    
    /**
     * @dev Calculates the projected supply after n rebases
     */
    function getProjectedSupplyAfterRebases(uint256 numRebases) public view returns (uint256) {
        uint256 supply = _currentTotalSupply;
        for (uint256 i = 0; i < numRebases; i++) {
            supply = (supply * DEFLATION_NUMERATOR) / DEFLATION_DENOMINATOR;
        }
        return supply;
    }
}