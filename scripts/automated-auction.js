const { ethers, network } = require("hardhat");

async function main() {

  const [owner, seller, bidder1, bidder2] =
    await ethers.getSigners();

  // DEPLOY TOKEN
  const Token =
    await ethers.getContractFactory("MyToken");

  const token = await Token.deploy();

  await token.waitForDeployment();

  console.log("Token:", token.target);

  // DEPLOY AUCTION
  const Auction =
    await ethers.getContractFactory("Auction");

  const auction = await Auction.deploy();

  await auction.waitForDeployment();

  console.log("Auction:", auction.target);

  // SEND TOKENS
  await token.transfer(
    bidder1.address,
    ethers.parseEther("100")
  );

  await token.transfer(
    bidder2.address,
    ethers.parseEther("100")
  );

  console.log("Tokens sent");

  // LIST ITEM
  await auction.connect(seller)
    .listItem("Gaming Laptop", token.target);

  console.log("Item listed");

  // APPROVE TOKEN
  await token.connect(bidder1)
    .approve(
      auction.target,
      ethers.parseEther("10")
    );

  // PLACE BID
  await auction.connect(bidder1)
    .bidToken(
      0,
      ethers.parseEther("10")
    );

  console.log("Bid placed");

  // WAIT 5 MINUTES
  console.log("Waiting for auction to end...");

  await network.provider.send(
    "evm_increaseTime",
    [300]
  );

  await network.provider.send("evm_mine");

  // END AUCTION
  await auction.endAuction(0);

  console.log("Auction ended");

  // CHECK NFT OWNER
  const ownerOfNFT = await auction.ownerOf(0);

  console.log("NFT Owner:", ownerOfNFT);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});