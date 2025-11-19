// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract TokenBank {
    
    address[] public userList;
    mapping(address => bool) private _isInList;

    mapping(address => uint256) public balances;
    
    uint256 public totalDeposits;
    
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdraw(address indexed user, uint256 amount, uint256 newBalance);
    
    error InsufficientBalance();
    error ZeroAmount();
    error WithdrawFailed();
    
    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();
        
        // —— 首次存款时记录用户 ——
        if (balances[msg.sender] == 0 && !_isInList[msg.sender]) {
            userList.push(msg.sender);
            _isInList[msg.sender] = true;
        }
        
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }
    
    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();
        
        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            balances[msg.sender] += amount;
            totalDeposits += amount;
            revert WithdrawFailed();
        }
        
        emit Withdraw(msg.sender, amount, balances[msg.sender]);
    }

    function getUserCount() external view returns (uint256) {
        return userList.length;
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function batchDeposit(address[] calldata users, uint256[] calldata amounts) external payable {
        require(users.length == amounts.length, "Array length mismatch");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(msg.value == totalAmount, "Insufficient ETH sent");
        
        for (uint256 i = 0; i < users.length; i++) {
            if (amounts[i] > 0) {
                // —— 新增：记录新用户 ——
                if (balances[users[i]] == 0 && !_isInList[users[i]]) {
                    userList.push(users[i]);
                    _isInList[users[i]] = true;
                }
                balances[users[i]] += amounts[i];
                totalDeposits += amounts[i];
                emit Deposit(users[i], amounts[i], balances[users[i]]);
            }
        }
    }
    
    function emergencyWithdraw() external {
        require(msg.sender == address(this), "Only contract can call");
        payable(msg.sender).transfer(address(this).balance);
    }
    
    receive() external payable {
        if (msg.value > 0) {
            // —— 新增：记录新用户 ——
            if (balances[msg.sender] == 0 && !_isInList[msg.sender]) {
                userList.push(msg.sender);
                _isInList[msg.sender] = true;
            }
            balances[msg.sender] += msg.value;
            totalDeposits += msg.value;
            emit Deposit(msg.sender, msg.value, balances[msg.sender]);
        }
    }
}