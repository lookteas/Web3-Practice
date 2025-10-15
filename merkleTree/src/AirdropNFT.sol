// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AirdropNFT
 * @dev ERC721 NFT contract for airdrop marketplace
 */
contract AirdropNFT is ERC721, ERC721URIStorage, Ownable {
    
    uint256 private _tokenIdCounter;
    
    // Base URI for metadata
    string private _baseTokenURI;
    
    // Mapping from token ID to price
    mapping(uint256 => uint256) public tokenPrices;
    
    // Mapping to track if token is listed for sale
    mapping(uint256 => bool) public isListed;
    
    event TokenListed(uint256 indexed tokenId, uint256 price);
    event TokenUnlisted(uint256 indexed tokenId);
    event TokenPriceUpdated(uint256 indexed tokenId, uint256 newPrice);
    
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address owner
    ) ERC721(name, symbol) Ownable(owner) {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * @dev Mint a new NFT to the specified address
     * @param to The address to mint the NFT to
     * @param tokenURI The metadata URI for the NFT
     * @return tokenId The ID of the newly minted token
     */
    function mint(address to, string memory tokenURI) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        return tokenId;
    }
    
    /**
     * @dev Batch mint NFTs to the specified address
     * @param to The address to mint the NFTs to
     * @param tokenURIs Array of metadata URIs for the NFTs
     * @return tokenIds Array of newly minted token IDs
     */
    function batchMint(address to, string[] memory tokenURIs) external onlyOwner returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](tokenURIs.length);
        
        for (uint256 i = 0; i < tokenURIs.length; i++) {
            uint256 tokenId = _tokenIdCounter;
            _tokenIdCounter++;
            
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, tokenURIs[i]);
            
            tokenIds[i] = tokenId;
        }
        
        return tokenIds;
    }
    
    /**
     * @dev List a token for sale at a specific price
     * @param tokenId The ID of the token to list
     * @param price The price in wei
     */
    function listToken(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(price > 0, "Price must be greater than 0");
        
        tokenPrices[tokenId] = price;
        isListed[tokenId] = true;
        
        emit TokenListed(tokenId, price);
    }
    
    /**
     * @dev Unlist a token from sale
     * @param tokenId The ID of the token to unlist
     */
    function unlistToken(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(isListed[tokenId], "Token not listed");
        
        isListed[tokenId] = false;
        tokenPrices[tokenId] = 0;
        
        emit TokenUnlisted(tokenId);
    }
    
    /**
     * @dev Update the price of a listed token
     * @param tokenId The ID of the token
     * @param newPrice The new price in wei
     */
    function updateTokenPrice(uint256 tokenId, uint256 newPrice) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(isListed[tokenId], "Token not listed");
        require(newPrice > 0, "Price must be greater than 0");
        
        tokenPrices[tokenId] = newPrice;
        
        emit TokenPriceUpdated(tokenId, newPrice);
    }
    
    /**
     * @dev Get the current token ID counter
     * @return The current token ID
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }
    
    /**
     * @dev Set the base URI for token metadata
     * @param baseTokenURI The new base URI
     */
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }
    
    /**
     * @dev Override _baseURI to return the custom base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @dev Override tokenURI to handle both base URI and individual token URIs
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    /**
     * @dev Override supportsInterface for multiple inheritance
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}