// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarket {
    struct Listing {
        address seller;
        address paymentToken;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    error NotOwner();
    error NotApproved();
    error InvalidPrice();
    error InvalidPaymentToken();
    error NoListing();
    error SelfPurchase();
    error AmountMismatch();

    event Listed(address indexed nft, uint256 indexed tokenId, address indexed seller, address paymentToken, uint256 price);
    event Purchased(address indexed nft, uint256 indexed tokenId, address indexed seller, address buyer, address paymentToken, uint256 price);

    function list(address nft, uint256 tokenId, address paymentToken, uint256 price) external {
        if (price == 0) revert InvalidPrice();
        if (paymentToken == address(0)) revert InvalidPaymentToken();
        if (IERC721(nft).ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (!(IERC721(nft).getApproved(tokenId) == address(this) || IERC721(nft).isApprovedForAll(msg.sender, address(this)))) revert NotApproved();

        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);

        listings[nft][tokenId] = Listing({
            seller: msg.sender,
            paymentToken: paymentToken,
            price: price
        });

        emit Listed(nft, tokenId, msg.sender, paymentToken, price);
    }

    function buy(address nft, uint256 tokenId, uint256 amount) external {
        Listing memory l = listings[nft][tokenId];
        if (l.seller == address(0)) revert NoListing();
        if (msg.sender == l.seller) revert SelfPurchase();
        if (amount != l.price) revert AmountMismatch();

        IERC20(l.paymentToken).transferFrom(msg.sender, l.seller, l.price);
        IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        delete listings[nft][tokenId];

        emit Purchased(nft, tokenId, l.seller, msg.sender, l.paymentToken, l.price);
    }

    function getListing(address nft, uint256 tokenId) external view returns (Listing memory) {
        return listings[nft][tokenId];
    }
}