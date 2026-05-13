// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Auction is ERC721 {

    uint256 public constant DURATION = 5 minutes;
    uint256 public count;

    struct Item {
        address seller;
        string name;
        address token; // address(0) = ETH
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool ended;
    }

    mapping(uint256 => Item) public items;
    mapping(address => uint256) public ethRefunds;
    mapping(address => mapping(address => uint256)) public tokenRefunds;

    constructor() ERC721("AuctionItem", "AIT") {}

    function listItem(
        string memory name,
        address token
    ) external {

        require(bytes(name).length > 0, "Name required");

        uint256 id = count++;

        _mint(address(this), id);

        items[id] = Item(
            msg.sender,
            name,
            token,
            0,
            address(0),
            block.timestamp + DURATION,
            false
        );
    }

    function bidETH(uint256 id) external payable {

        Item storage item = items[id];

        require(block.timestamp < item.endTime, "Ended");
        require(item.token == address(0), "ETH only");
        require(msg.value > item.highestBid, "Low bid");

        if (item.highestBidder != address(0)) {
            ethRefunds[item.highestBidder] += item.highestBid;
        }

        item.highestBid = msg.value;
        item.highestBidder = msg.sender;
    }

    function bidToken(uint256 id, uint256 amount) external {

        Item storage item = items[id];

        require(block.timestamp < item.endTime, "Ended");
        require(item.token != address(0), "Token only");
        require(amount > item.highestBid, "Low bid");

        IERC20(item.token).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (item.highestBidder != address(0)) {
            tokenRefunds[item.token][item.highestBidder]
                += item.highestBid;
        }

        item.highestBid = amount;
        item.highestBidder = msg.sender;
    }

    function endAuction(uint256 id) external {

        Item storage item = items[id];

        require(block.timestamp >= item.endTime, "Still active");
        require(!item.ended, "Already ended");

        item.ended = true;

        if (item.highestBidder == address(0)) {
            _transfer(address(this), item.seller, id);
            return;
        }

        if (item.token == address(0)) {
            payable(item.seller).transfer(item.highestBid);
        } else {
            IERC20(item.token).transfer(
                item.seller,
                item.highestBid
            );
        }

        _transfer(address(this), item.highestBidder, id);
    }

    function withdrawETH() external {

        uint256 amount = ethRefunds[msg.sender];

        require(amount > 0, "No refund");

        ethRefunds[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

    function withdrawToken(address token) external {

        uint256 amount = tokenRefunds[token][msg.sender];

        require(amount > 0, "No refund");

        tokenRefunds[token][msg.sender] = 0;

        IERC20(token).transfer(msg.sender, amount);
    }

    function timeLeft(uint256 id)
        external
        view
        returns (uint256)
    {
        if (block.timestamp >= items[id].endTime) return 0;

        return items[id].endTime - block.timestamp;
    }
}