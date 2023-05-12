const { expect, assert } = require("chai");
const { BigNumber, utils } = require("ethers");
const { ethers } = require("hardhat");

describe("bnbWorkshop", function () {
  let nftContract;

  this.beforeAll(async function () {
    const NFTcontract = await ethers.getContractFactory("NftContract");
    nftContract = await NFTcontract.deploy();
  });

  it("should set sale status active", async function () {
    await nftContract.setSaleStatus(true);
    expect(await nftContract.saleIsActive()).to.equal(true);
  });

  it("mint", async function () {
    await nftContract.mint();
  });

  it("get metadata", async function () {
    console.log(await nftContract.tokenURI(1));
  });
});
