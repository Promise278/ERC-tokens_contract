const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Auction", function () {

  let auction;
  let token;

  let owner;
  let seller;
  let bidder1;
  let bidder2;

  beforeEach(async function () {

    [owner, seller, bidder1, bidder2] =
      await ethers.getSigners();

    // Deploy ERC20
    const Token = await ethers.getContractFactory("MyToken");
    token = await Token.deploy();

    // Deploy Auction
    const Auction = await ethers.getContractFactory("Auction");
    auction = await Auction.deploy();

    // Send tokens to bidders
    await token.transfer(
      bidder1.address,
      ethers.parseEther("100")
    );

    await token.transfer(
      bidder2.address,
      ethers.parseEther("100")
    );
  });

  it("Should list item", async function () {

    await auction.connect(seller)
      .listItem("iPhone", ethers.ZeroAddress);

    const item = await auction.items(0);

    expect(item.name).to.equal("iPhone");
  });

  it("Should allow ETH bidding", async function () {

    await auction.connect(seller)
      .listItem("Laptop", ethers.ZeroAddress);

    await auction.connect(bidder1)
      .bidETH(0, {
        value: ethers.parseEther("1")
      });

    const item = await auction.items(0);

    expect(item.highestBidder)
      .to.equal(bidder1.address);
  });

  it("Should allow token bidding", async function () {

    await auction.connect(seller)
      .listItem("PS5", token.target);

    await token.connect(bidder1)
      .approve(
        auction.target,
        ethers.parseEther("20")
      );

    await auction.connect(bidder1)
      .bidToken(
        0,
        ethers.parseEther("20")
      );

    const item = await auction.items(0);

    expect(item.highestBidder)
      .to.equal(bidder1.address);
  });

});