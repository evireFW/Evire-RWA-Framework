const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Utilities", function () {
  let utilities;

  before(async function () {
    const Utilities = await ethers.getContractFactory("Utilities");
    utilities = await Utilities.deploy();
    await utilities.deployed();
  });

  describe("calculatePercentage", function () {
    it("should calculate the correct percentage", async function () {
      const value = ethers.utils.parseEther("100");
      const percentage = 25;
      const expected = ethers.utils.parseEther("25");
      expect(await utilities.calculatePercentage(value, percentage)).to.equal(expected);
    });

    it("should revert if percentage is greater than 100", async function () {
      const value = ethers.utils.parseEther("100");
      const percentage = 101;
      await expect(utilities.calculatePercentage(value, percentage)).to.be.revertedWith("Percentage must be between 0 and 100");
    });
  });

  describe("uintToString", function () {
    it("should convert uint256 to string correctly", async function () {
      const value = 12345;
      expect(await utilities.uintToString(value)).to.equal("12345");
    });
  });

  describe("stringEqual", function () {
    it("should return true for equal strings", async function () {
      const str1 = "Hello, world!";
      const str2 = "Hello, world!";
      expect(await utilities.stringEqual(str1, str2)).to.be.true;
    });

    it("should return false for different strings", async function () {
      const str1 = "Hello, world!";
      const str2 = "Goodbye, world!";
      expect(await utilities.stringEqual(str1, str2)).to.be.false;
    });
  });

  describe("calculateAverage", function () {
    it("should calculate the correct average", async function () {
      const values = [1, 2, 3, 4, 5];
      expect(await utilities.calculateAverage(values)).to.equal(3);
    });

    it("should revert if the array is empty", async function () {
      const values = [];
      await expect(utilities.calculateAverage(values)).to.be.revertedWith("Array must not be empty");
    });
  });

  describe("findMaxValue", function () {
    it("should find the maximum value in the array", async function () {
      const values = [1, 2, 3, 4, 5];
      expect(await utilities.findMaxValue(values)).to.equal(5);
    });

    it("should revert if the array is empty", async function () {
      const values = [];
      await expect(utilities.findMaxValue(values)).to.be.revertedWith("Array must not be empty");
    });
  });

  describe("isContract", function () {
    it("should return true for a contract address", async function () {
      const contractAddress = utilities.address;
      expect(await utilities.isContract(contractAddress)).to.be.true;
    });

    it("should return false for an externally owned account", async function () {
      expect(await utilities.isContract(addr1.address)).to.be.false;
    });
  });

  describe("bytes32ToString", function () {
    it("should convert bytes32 to string correctly", async function () {
      const bytes32Data = ethers.utils.formatBytes32String("Hello, world!");
      expect(await utilities.bytes32ToString(bytes32Data)).to.equal("Hello, world!");
    });
  });
});
