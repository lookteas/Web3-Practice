// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./console.sol";

abstract contract Test {
    // Test utilities
    function assertTrue(bool condition) internal pure {
        require(condition, "Assertion failed");
    }
    
    function assertFalse(bool condition) internal pure {
        require(!condition, "Assertion failed");
    }
    
    function assertEq(uint256 a, uint256 b) internal pure {
        require(a == b, "Values not equal");
    }
    
    function assertEq(address a, address b) internal pure {
        require(a == b, "Addresses not equal");
    }
    
    function assertEq(string memory a, string memory b) internal pure {
        require(keccak256(bytes(a)) == keccak256(bytes(b)), "Strings not equal");
    }
    
    // VM utilities (simplified)
    function makeAddr(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(bytes(name)))));
    }
}

// VM interface for testing
interface Vm {
    function prank(address) external;
    function startPrank(address) external;
    function stopPrank() external;
    function deal(address, uint256) external;
    function expectRevert(bytes memory) external;
    function assume(bool) external;
    function addr(uint256) external returns (address);
    function envUint(string memory) external returns (uint256);
    function envString(string memory) external returns (string memory);
    function roll(uint256) external;
    function warp(uint256) external;
    function startBroadcast(uint256) external;
    function startBroadcast(address) external;
    function stopBroadcast() external;
}

// Global vm instance
Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));