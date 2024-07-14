const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AssetValuation", function () {
  let AssetValuation, assetValuation;
  let owner, addr1;
  let mockOracle;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    const MockOracle = await ethers.getContractFactory("MockOracle");
    mockOracle = await MockOracle.deploy();
    await mockOracle.deployed();

    const AssetValuationFactory = await ethers.getContractFactory("AssetValuation");
    assetValuation = await AssetValuationFactory.deploy();
    await assetValuation.deployed();
  });

  describe("calculateAssetValue", function () {
    it("should calculate the value of a real estate asset", async function () {
      const assetData = {
        purchasePrice: ethers.utils.parseEther("1000"),
        lastValuation: ethers.utils.parseEther("1000"),
        lastValuationTimestamp: (await ethers.provider.getBlock('latest')).timestamp,
        assetType: "real_estate",
        depreciationRate: 0,
        oracleAddress: mockOracle.address
      };

      await mockOracle.setLatestAnswer(ethers.utils.parseEther("1050"));
      const value = await assetValuation.calculateAssetValue(assetData);
      expect(value).to.be.closeTo(ethers.utils.parseEther("1102.5"), ethers.utils.parseEther("0.01"));
    });

    it("should calculate the value of a vehicle asset", async function () {
      const assetData = {
        purchasePrice: ethers.utils.parseEther("1000"),
        lastValuation: ethers.utils.parseEther("1000"),
        lastValuationTimestamp: (await ethers.provider.getBlock('latest')).timestamp - 365 * 24 * 60 * 60,
        assetType: "vehicle",
        depreciationRate: 10,
        oracleAddress: mockOracle.address
      };

      await mockOracle.setLatestAnswer(ethers.utils.parseEther("950"));
      const value = await assetValuation.calculateAssetValue(assetData);
      expect(value).to.be.closeTo(ethers.utils.parseEther("855"), ethers.utils.parseEther("0.01"));
    });

    it("should calculate the value of an artwork asset", async function () {
      const assetData = {
        purchasePrice: ethers.utils.parseEther("1000"),
        lastValuation: ethers.utils.parseEther("1000"),
        lastValuationTimestamp: (await ethers.provider.getBlock('latest')).timestamp - 365 * 24 * 60 * 60,
        assetType: "artwork",
        depreciationRate: 0,
        oracleAddress: mockOracle.address
      };

      await mockOracle.setLatestAnswer(ethers.utils.parseEther("1100"));
      const value = await assetValuation.calculateAssetValue(assetData);
      expect(value).to.be.closeTo(ethers.utils.parseEther("1210"), ethers.utils.parseEther("0.01"));
    });

    it("should revert for an invalid asset type", async function () {
      const assetData = {
        purchasePrice: ethers.utils.parseEther("1000"),
        lastValuation: ethers.utils.parseEther("1000"),
        lastValuationTimestamp: (await ethers.provider.getBlock('latest')).timestamp,
        assetType: "invalid_type",
        depreciationRate: 0,
        oracleAddress: mockOracle.address
      };

      await expect(assetValuation.calculateAssetValue(assetData)).to.be.revertedWith("InvalidAssetType");
    });
  });

  describe("updateDepreciationRate", function () {
    it("should update the depreciation rate for an asset", async function () {
      const assetData = {
        purchasePrice: ethers.utils.parseEther("1000"),
        lastValuation: ethers.utils.parseEther("1000"),
        lastValuationTimestamp: (await ethers.provider.getBlock('latest')).timestamp,
        assetType: "vehicle",
        depreciationRate: 10,
        oracleAddress: mockOracle.address
      };

      await assetValuation.updateDepreciationRate(assetData, 15);
      expect(assetData.depreciationRate).to.equal(15);
    });

    it("should emit DepreciationRateUpdated event", async function () {
      const assetData = {
        purchasePrice: ethers.utils.parseEther("1000"),
        lastValuation: ethers.utils.parseEther("1000"),
        lastValuationTimestamp: (await ethers.provider.getBlock('latest')).timestamp,
        assetType: "vehicle",
        depreciationRate: 10,
        oracleAddress: mockOracle.address
      };

      await expect(assetValuation.updateDepreciationRate(assetData, 15))
        .to.emit(assetValuation, "DepreciationRateUpdated")
        .withArgs(ethers.utils.id(JSON.stringify(assetData)), 15);
    });

    it("should revert if the new depreciation rate is greater than 100", async function () {
      const assetData = {
        purchasePrice: ethers.utils.parseEther("1000"),
        lastValuation: ethers.utils.parseEther("1000"),
        lastValuationTimestamp: (await ethers.provider.getBlock('latest')).timestamp,
        assetType: "vehicle",
        depreciationRate: 10,
        oracleAddress: mockOracle.address
      };

      await expect(assetValuation.updateDepreciationRate(assetData, 110)).to.be.revertedWith("Depreciation rate must be between 0 and 100");
    });
  });

  describe("updateOracleAddress", function () {
    it("should update the oracle address for an asset", async function () {
      const assetData = {
        purchasePrice: ethers.utils.parseEther("1000"),
        lastValuation: ethers.utils.parseEther("1000"),
        lastValuationTimestamp: (await ethers.provider.getBlock('latest')).timestamp,
        assetType: "real_estate",
        depreciationRate: 0,
        oracleAddress: mockOracle.address
      };

      const newOracleAddress = ethers.Wallet.createRandom().address;
      await assetValuation.updateOracleAddress(assetData, newOracleAddress);
      expect(assetData.oracleAddress).to.equal(newOracleAddress);
    });

    it("should emit OracleAddressUpdated event", async function () {
      const assetData = {
        purchasePrice: ethers.utils.parseEther("1000"),
        lastValuation: ethers.utils.parseEther("1000"),
        lastValuationTimestamp: (await ethers.provider.getBlock('latest')).timestamp,
        assetType: "real_estate",
        depreciationRate: 0,
        oracleAddress: mockOracle.address
      };

      const newOracleAddress = ethers.Wallet.createRandom().address;
      await expect(assetValuation.updateOracleAddress(assetData, newOracleAddress))
        .to.emit(assetValuation, "OracleAddressUpdated")
        .withArgs(ethers.utils.id(JSON.stringify(assetData)), newOracleAddress);
    });

    it("should revert if the new oracle address is the zero address", async function () {
      const assetData = {
        purchasePrice: ethers.utils.parseEther("1000"),
        lastValuation: ethers.utils.parseEther("1000"),
        lastValuationTimestamp: (await ethers.provider.getBlock('latest')).timestamp,
        assetType: "real_estate",
        depreciationRate: 0,
        oracleAddress: mockOracle.address
      };

      await expect(assetValuation.updateOracleAddress(assetData, ethers.constants.AddressZero)).to.be.revertedWith("InvalidOracleAddress");
    });
  });
});
