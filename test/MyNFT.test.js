const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyNFT", function () {

    let nft;
    let owner;
    let user1;

    beforeEach(async function () {

        [owner, user1] = await ethers.getSigners();

        const NFT = await ethers.getContractFactory("MyNFT");

        nft = await NFT.deploy();

        await nft.waitForDeployment();
    });

    it("should deploy correctly", async function () {

        expect(await nft.name()).to.equal("Promise NFT");

        expect(await nft.symbol()).to.equal("PNFT");
    });

    it("should mint NFT", async function () {

        await nft.mint(
            user1.address,
            "https://example.com/1.json"
        );

        const ownerOfNFT = await nft.ownerOf(0);

        expect(ownerOfNFT).to.equal(user1.address);
    });

    it("should store token URI", async function () {

        await nft.mint(
            user1.address,
            "https://example.com/1.json"
        );

        const tokenURI = await nft.tokenURI(0);

        expect(tokenURI).to.equal(
            "https://example.com/1.json"
        );
    });

    it("should increment token IDs", async function () {

        await nft.mint(
            user1.address,
            "https://example.com/1.json"
        );

        await nft.mint(
            user1.address,
            "https://example.com/2.json"
        );

        expect(await nft.ownerOf(1))
            .to.equal(user1.address);
    });
});