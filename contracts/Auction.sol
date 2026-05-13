// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Auction is ERC721 {
    uint256 public constant AUCTION_DURATION = 5 minutes;
    uint256 public auctionCount;

    struct AuctionItem {
        address seller;
        string  itemName;
        address paymentToken;  // address(0) = ETH
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool    ended;
    }

    mapping(uint256 => AuctionItem) public auctions;
    mapping(address => uint256) public ethRefunds;
    mapping(address => mapping(address => uint256)) public tokenRefunds;

    constructor() ERC721("Auction Item", "AUC") {}

    function listItem(string memory itemName, address paymentToken) external returns (uint256 id) {
        require(bytes(itemName).length > 0, "Item name required");
        id = auctionCount++;
        _mint(address(this), id);
        auctions[id] = AuctionItem({
            seller:        msg.sender,
            itemName:      itemName,
            paymentToken:  paymentToken,
            highestBid:    0,
            highestBidder: address(0),
            endTime:       block.timestamp + AUCTION_DURATION,
            ended:         false
        });
    }

    function bidETH(uint256 id) external payable {
        AuctionItem storage a = auctions[id];
        require(block.timestamp < a.endTime, "Auction ended");
        require(!a.ended, "Already ended");
        require(a.paymentToken == address(0), "Not ETH auction");
        require(msg.value > a.highestBid, "Bid too low");
        if (a.highestBidder != address(0)) {
            ethRefunds[a.highestBidder] += a.highestBid;
        }
        a.highestBid    = msg.value;
        a.highestBidder = msg.sender;
    }

    function bidToken(uint256 id, uint256 amount) external {
        AuctionItem storage a = auctions[id];
        require(block.timestamp < a.endTime, "Auction ended");
        require(!a.ended, "Already ended");
        require(a.paymentToken != address(0), "Not token auction");
        require(amount > a.highestBid, "Bid too low");
        IERC20(a.paymentToken).transferFrom(msg.sender, address(this), amount);
        if (a.highestBidder != address(0)) {
            tokenRefunds[a.paymentToken][a.highestBidder] += a.highestBid;
        }
        a.highestBid    = amount;
        a.highestBidder = msg.sender;
    }

    function endAuction(uint256 id) external {
        AuctionItem storage a = auctions[id];
        require(block.timestamp >= a.endTime, "Not ended yet");
        require(!a.ended, "Already closed");
        a.ended = true;
        if (a.highestBidder == address(0)) {
            _transfer(address(this), a.seller, id);
            return;
        }
        if (a.paymentToken == address(0)) {
            payable(a.seller).transfer(a.highestBid);
        } else {
            IERC20(a.paymentToken).transfer(a.seller, a.highestBid);
        }
        _transfer(address(this), a.highestBidder, id);
    }

    function withdrawETH() external {
        uint256 amount = ethRefunds[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        ethRefunds[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function withdrawToken(address token) external {
        uint256 amount = tokenRefunds[token][msg.sender];
        require(amount > 0, "Nothing to withdraw");
        tokenRefunds[token][msg.sender] = 0;
        IERC20(token).transfer(msg.sender, amount);
    }

    function getHighestBidder(uint256 id) external view returns (address, uint256) {
        AuctionItem storage a = auctions[id];
        return (a.highestBidder, a.highestBid);
    }

    function getAllItems() external view returns (AuctionItem[] memory) {
        AuctionItem[] memory all = new AuctionItem[](auctionCount);
        for (uint256 i = 0; i < auctionCount; i++) {
            all[i] = auctions[i];
        }
        return all;
    }

    function getItem(uint256 id) external view returns (AuctionItem memory) {
        return auctions[id];
    }

    function timeLeft(uint256 id) external view returns (uint256) {
        AuctionItem storage a = auctions[id];
        if (block.timestamp >= a.endTime) return 0;
        return a.endTime - block.timestamp;
    }
}