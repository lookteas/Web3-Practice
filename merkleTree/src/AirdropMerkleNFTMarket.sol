// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./AirdropToken.sol";
import "./AirdropNFT.sol";

/**
 * @title AirdropMerkleNFTMarket
 * @dev NFT marketplace with Merkle tree whitelist and permit-based payments
 */
contract AirdropMerkleNFTMarket is ReentrancyGuard, Ownable {
    
    // State variables
    AirdropToken public immutable token;
    AirdropNFT public immutable nft;
    bytes32 public merkleRoot;
    
    // Discount rate for whitelisted users (50% = 5000 basis points)
    uint256 public constant DISCOUNT_RATE = 5000; // 50%
    uint256 public constant BASIS_POINTS = 10000;
    
    // Mapping to track claimed addresses
    mapping(address => bool) public hasClaimed;
    
    // Mapping to store permit data temporarily during multicall
    mapping(address => PermitData) private permitStorage;
    
    struct PermitData {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool isSet;
    }
    
    // Events
    event MerkleRootUpdated(bytes32 newRoot);
    event NFTClaimed(address indexed user, uint256 indexed tokenId, uint256 price, uint256 discountedPrice);
    event PermitExecuted(address indexed user, uint256 value);
    
    // Custom errors
    error InvalidProof();
    error AlreadyClaimed();
    error TokenNotListed();
    error InsufficientPayment();
    error PermitNotSet();
    error InvalidPermitData();
    error TransferFailed();
    
    constructor(
        address _token,
        address _nft,
        bytes32 _merkleRoot,
        address _owner
    ) Ownable(_owner) {
        token = AirdropToken(_token);
        nft = AirdropNFT(_nft);
        merkleRoot = _merkleRoot;
    }
    
    /**
     * @dev Update the Merkle root for whitelist verification
     * @param _merkleRoot New Merkle root
     */
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }
    
    /**
     * @dev Verify if an address is whitelisted using Merkle proof
     * @param user Address to verify
     * @param proof Merkle proof
     * @return bool True if address is whitelisted
     */
    function verifyWhitelist(address user, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
    
    /**
     * @dev Execute permit authorization for token spending
     * @param value Amount to approve
     * @param deadline Permit deadline
     * @param v Signature parameter
     * @param r Signature parameter
     * @param s Signature parameter
     */
    function permitPrePay(
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Store permit data for potential multicall usage
        permitStorage[msg.sender] = PermitData({
            value: value,
            deadline: deadline,
            v: v,
            r: r,
            s: s,
            isSet: true
        });
        
        // Execute permit
        IERC20Permit(address(token)).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        
        emit PermitExecuted(msg.sender, value);
    }
    
    /**
     * @dev Claim NFT with whitelist verification and discounted price
     * @param tokenId NFT token ID to claim
     * @param proof Merkle proof for whitelist verification
     */
    function claimNFT(uint256 tokenId, bytes32[] calldata proof) external nonReentrant {
        // Verify whitelist
        if (!verifyWhitelist(msg.sender, proof)) {
            revert InvalidProof();
        }
        
        // Check if already claimed
        if (hasClaimed[msg.sender]) {
            revert AlreadyClaimed();
        }
        
        // Check if NFT is listed for sale
        if (!nft.isListed(tokenId)) {
            revert TokenNotListed();
        }
        
        // Get original price and calculate discounted price
        uint256 originalPrice = nft.tokenPrices(tokenId);
        uint256 discountedPrice = (originalPrice * (BASIS_POINTS - DISCOUNT_RATE)) / BASIS_POINTS;
        
        // Check if user has sufficient token balance and allowance
        if (token.balanceOf(msg.sender) < discountedPrice) {
            revert InsufficientPayment();
        }
        
        if (token.allowance(msg.sender, address(this)) < discountedPrice) {
            revert InsufficientPayment();
        }
        
        // Mark as claimed
        hasClaimed[msg.sender] = true;
        
        // Get NFT owner
        address nftOwner = nft.ownerOf(tokenId);
        
        // Transfer tokens from buyer to NFT owner
        bool success = token.transferFrom(msg.sender, nftOwner, discountedPrice);
        if (!success) {
            revert TransferFailed();
        }
        
        // Transfer NFT from owner to buyer
        nft.transferFrom(nftOwner, msg.sender, tokenId);
        
        emit NFTClaimed(msg.sender, tokenId, originalPrice, discountedPrice);
    }
    
    /**
     * @dev Multicall function to execute multiple calls in a single transaction
     * @param data Array of encoded function calls
     * @return results Array of return data from each call
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            
            if (!success) {
                // If there's a revert reason, bubble it up
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert("Multicall: call failed");
                }
            }
            
            results[i] = result;
        }
        
        return results;
    }
    
    /**
     * @dev Helper function to encode permitPrePay call data
     * @param value Amount to approve
     * @param deadline Permit deadline
     * @param v Signature parameter
     * @param r Signature parameter
     * @param s Signature parameter
     * @return Encoded call data
     */
    function encodePermitPrePay(
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "permitPrePay(uint256,uint256,uint8,bytes32,bytes32)",
            value,
            deadline,
            v,
            r,
            s
        );
    }
    
    /**
     * @dev Helper function to encode claimNFT call data
     * @param tokenId NFT token ID to claim
     * @param proof Merkle proof for whitelist verification
     * @return Encoded call data
     */
    function encodeClaimNFT(
        uint256 tokenId,
        bytes32[] calldata proof
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "claimNFT(uint256,bytes32[])",
            tokenId,
            proof
        );
    }
    
    /**
     * @dev Get discounted price for a token
     * @param tokenId NFT token ID
     * @return Discounted price
     */
    function getDiscountedPrice(uint256 tokenId) external view returns (uint256) {
        uint256 originalPrice = nft.tokenPrices(tokenId);
        return (originalPrice * (BASIS_POINTS - DISCOUNT_RATE)) / BASIS_POINTS;
    }
    
    /**
     * @dev Check if an address has already claimed
     * @param user Address to check
     * @return bool True if already claimed
     */
    function hasUserClaimed(address user) external view returns (bool) {
        return hasClaimed[user];
    }
    
    /**
     * @dev Emergency function to withdraw tokens (only owner)
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        bool success = token.transfer(owner(), amount);
        if (!success) {
            revert TransferFailed();
        }
    }
    
    /**
     * @dev Emergency function to withdraw NFTs (only owner)
     * @param tokenId NFT token ID to withdraw
     */
    function emergencyWithdrawNFT(uint256 tokenId) external onlyOwner {
        nft.transferFrom(address(this), owner(), tokenId);
    }
}