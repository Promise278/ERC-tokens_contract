const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyToken", function () {

    let token;
    let owner;
    let user1;

    beforeEach(async function () {

        [owner, user1] = await ethers.getSigners();

        const Token = await ethers.getContractFactory("MyToken");

        token = await Token.deploy();

        await token.waitForDeployment();
    });

    it("should deploy correctly", async function () {

        expect(await token.name()).to.equal("Promise Token");

        expect(await token.symbol()).to.equal("PMT");
    });

    it("should mint initial supply to owner", async function () {

        const balance = await token.balanceOf(owner.address);

        expect(balance).to.equal(
            ethers.parseEther("1000000")
        );
    });

    it("should transfer tokens", async function () {

        await token.transfer(
            user1.address,
            ethers.parseEther("100")
        );

        const balance = await token.balanceOf(user1.address);

        expect(balance).to.equal(
            ethers.parseEther("100")
        );
    });

    it("should allow owner to mint", async function () {

        await token.mint(
            user1.address,
            ethers.parseEther("500")
        );

        const balance = await token.balanceOf(user1.address);

        expect(balance).to.equal(
            ethers.parseEther("500")
        );
    });

    it("should burn tokens", async function () {

        await token.burn(
            ethers.parseEther("100")
        );

        const balance = await token.balanceOf(owner.address);

        expect(balance).to.equal(
            ethers.parseEther("999900")
        );
    });
});