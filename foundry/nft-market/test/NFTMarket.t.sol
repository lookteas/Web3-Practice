// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import {NFTMarket} from "src/NFTMarket.sol";
import {TestERC20} from "src/TestERC20.sol";
import {TestERC721} from "src/TestERC721.sol";

contract NFTMarketTest is Test {
    NFTMarket market;
    TestERC20 token;
    TestERC721 nft;
    address seller = address(0xA11CE);
    address buyer = address(0xB0B);
    address other = address(0xC0DE);

    function setUp() public {
        market = new NFTMarket();
        token = new TestERC20("Token", "TKN");
        nft = new TestERC721("NFT", "NFT");

        token.mint(buyer, 1_000_000 ether);
        token.mint(other, 1_000_000 ether);
    }

    function testListSuccess() public {
        vm.startPrank(seller);
        uint256 id = nft.mint(seller);
        nft.approve(address(market), id);
        vm.expectEmit(true, true, true, true);
        emit Listed(address(nft), id, seller, address(token), 1 ether);
        market.list(address(nft), id, address(token), 1 ether);
        vm.stopPrank();
        NFTMarket.Listing memory l = market.getListing(address(nft), id);
        assertEq(l.seller, seller);
        assertEq(l.paymentToken, address(token));
        assertEq(l.price, 1 ether);
        assertEq(nft.ownerOf(id), address(market));
    }

    event Listed(address indexed nft, uint256 indexed tokenId, address indexed seller, address paymentToken, uint256 price);
    event Purchased(address indexed nft, uint256 indexed tokenId, address indexed seller, address buyer, address paymentToken, uint256 price);

    function testListFail_NotOwner() public {
        uint256 id = nft.mint(seller);
        vm.expectRevert(NFTMarket.NotOwner.selector);
        vm.prank(buyer);
        market.list(address(nft), id, address(token), 1 ether);
    }

    function testListFail_NotApproved() public {
        vm.prank(seller);
        uint256 id = nft.mint(seller);
        vm.expectRevert(NFTMarket.NotApproved.selector);
        vm.prank(seller);
        market.list(address(nft), id, address(token), 1 ether);
    }

    function testListFail_InvalidPrice() public {
        vm.startPrank(seller);
        uint256 id = nft.mint(seller);
        nft.approve(address(market), id);
        vm.expectRevert(NFTMarket.InvalidPrice.selector);
        market.list(address(nft), id, address(token), 0);
        vm.stopPrank();
    }

    function testListFail_InvalidPaymentToken() public {
        vm.startPrank(seller);
        uint256 id = nft.mint(seller);
        nft.approve(address(market), id);
        vm.expectRevert(NFTMarket.InvalidPaymentToken.selector);
        market.list(address(nft), id, address(0), 1 ether);
        vm.stopPrank();
    }

    function testBuySuccess() public {
        vm.startPrank(seller);
        uint256 id = nft.mint(seller);
        nft.approve(address(market), id);
        market.list(address(nft), id, address(token), 5 ether);
        vm.stopPrank();

        vm.startPrank(buyer);
        token.approve(address(market), type(uint256).max);
        vm.expectEmit(true, true, true, true);
        emit Purchased(address(nft), id, seller, buyer, address(token), 5 ether);
        market.buy(address(nft), id, 5 ether);
        vm.stopPrank();

        assertEq(nft.ownerOf(id), buyer);
        assertEq(token.balanceOf(seller), 5 ether);
        assertEq(token.balanceOf(address(market)), 0);
    }

    function testBuyFail_SelfPurchase() public {
        vm.startPrank(seller);
        uint256 id = nft.mint(seller);
        nft.approve(address(market), id);
        market.list(address(nft), id, address(token), 3 ether);
        token.mint(seller, 10 ether);
        token.approve(address(market), type(uint256).max);
        vm.expectRevert(NFTMarket.SelfPurchase.selector);
        market.buy(address(nft), id, 3 ether);
        vm.stopPrank();
    }

    function testBuyFail_RepeatPurchase() public {
        vm.startPrank(seller);
        uint256 id = nft.mint(seller);
        nft.approve(address(market), id);
        market.list(address(nft), id, address(token), 2 ether);
        vm.stopPrank();

        vm.prank(buyer);
        token.approve(address(market), type(uint256).max);
        vm.prank(buyer);
        market.buy(address(nft), id, 2 ether);

        vm.expectRevert(NFTMarket.NoListing.selector);
        vm.prank(other);
        market.buy(address(nft), id, 2 ether);
    }

    function testBuyFail_PayTooLittle() public {
        vm.startPrank(seller);
        uint256 id = nft.mint(seller);
        nft.approve(address(market), id);
        market.list(address(nft), id, address(token), 7 ether);
        vm.stopPrank();

        vm.startPrank(buyer);
        token.approve(address(market), type(uint256).max);
        vm.expectRevert(NFTMarket.AmountMismatch.selector);
        market.buy(address(nft), id, 6 ether);
        vm.stopPrank();
    }

    function testBuyFail_PayTooMuch() public {
        vm.startPrank(seller);
        uint256 id = nft.mint(seller);
        nft.approve(address(market), id);
        market.list(address(nft), id, address(token), 4 ether);
        vm.stopPrank();

        vm.startPrank(buyer);
        token.approve(address(market), type(uint256).max);
        vm.expectRevert(NFTMarket.AmountMismatch.selector);
        market.buy(address(nft), id, 5 ether);
        vm.stopPrank();
    }

    function testFuzz_ListAndBuy(uint256 priceRaw, address randBuyer) public {
        vm.assume(randBuyer != address(0));
        vm.assume(randBuyer != address(market));
        vm.assume(randBuyer.code.length == 0);
        uint256 price = bound(priceRaw, 1e16, 10_000 ether);

        vm.startPrank(seller);
        uint256 id = nft.mint(seller);
        nft.approve(address(market), id);
        market.list(address(nft), id, address(token), price);
        vm.stopPrank();

        token.mint(randBuyer, price);
        vm.startPrank(randBuyer);
        token.approve(address(market), type(uint256).max);
        market.buy(address(nft), id, price);
        vm.stopPrank();

        assertEq(token.balanceOf(address(market)), 0);
        assertEq(nft.ownerOf(id), randBuyer);
    }
}

import "forge-std/StdInvariant.sol";

contract Buyer {
    function buy(address market, address nft, uint256 tokenId, address paymentToken, uint256 price) external {
        TestERC20(paymentToken).approve(market, type(uint256).max);
        NFTMarket(market).buy(nft, tokenId, price);
    }
}

contract Handler {
    NFTMarket market;
    TestERC20 token;
    TestERC721 nft;
    Buyer buyer;

    constructor(NFTMarket m, TestERC20 t, TestERC721 n) {
        market = m;
        token = t;
        nft = n;
        buyer = new Buyer();
    }

    function _bound(uint256 x, uint256 min, uint256 max) internal pure returns (uint256) {
        if (min > max) return x;
        if (x < min) return min;
        if (x > max) return min + (x - min) % (max - min + 1);
        return x;
    }

    function list(uint256 priceRaw) external {
        uint256 price = _bound(priceRaw, 1e16, 10_000 ether);
        uint256 id = nft.mint(address(this));
        nft.approve(address(market), id);
        market.list(address(nft), id, address(token), price);
    }

    function buy(uint256 tokenId) external {
        NFTMarket.Listing memory l = market.getListing(address(nft), tokenId);
        if (l.seller == address(0)) return;
        if (address(buyer) == l.seller) return;
        token.mint(address(buyer), l.price);
        buyer.buy(address(market), address(nft), tokenId, l.paymentToken, l.price);
    }
}

contract InvariantTest is StdInvariant, Test {
    NFTMarket market;
    TestERC20 token;
    TestERC721 nft;
    Handler handler;

    function setUp() public {
        market = new NFTMarket();
        token = new TestERC20("Token", "TKN");
        nft = new TestERC721("NFT", "NFT");
        handler = new Handler(market, token, nft);
        targetContract(address(handler));
    }

    function invariant_NoTokenBalance() public {
        assertEq(token.balanceOf(address(market)), 0);
    }
}