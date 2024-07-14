const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("RWAAsset", function () {
  let RWAAsset, rwaAsset;
  let owner, addr1, addr2;
  let priceFeed, paymentToken;
  let priceFeedMock, paymentTokenMock;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy mock PriceFeed and PaymentToken contracts
    const PriceFeedMock = await ethers.getContractFactory("PriceFeedMock");
    priceFeedMock = await PriceFeedMock.deploy();
    await priceFeedMock.deployed();

    const PaymentTokenMock = await ethers.getContractFactory("PaymentTokenMock");
    paymentTokenMock = await PaymentTokenMock.deploy();
    await paymentTokenMock.deployed();

    // Deploy the RWAAsset contract
    RWAAsset = await ethers.getContractFactory("RWAAsset");
    rwaAsset = await upgrades.deployProxy(RWAAsset, ["RWA Asset", "RWAA", priceFeedMock.address, paymentTokenMock.address], { initializer: "initialize" });
    await rwaAsset.deployed();
  });

  describe("Initialization", function () {
    it("should initialize with the correct parameters", async function () {
      expect(await rwaAsset.name()).to.equal("RWA Asset");
      expect(await rwaAsset.symbol()).to.equal("RWAA");
    });

    it("should assign roles correctly", async function () {
      const ADMIN_ROLE = await rwaAsset.ADMIN_ROLE();
      const MINTER_ROLE = await rwaAsset.MINTER_ROLE();
      const PAUSER_ROLE = await rwaAsset.PAUSER_ROLE();
      const UPGRADER_ROLE = await rwaAsset.UPGRADER_ROLE();

      expect(await rwaAsset.hasRole(ADMIN_ROLE, owner.address)).to.be.true;
      expect(await rwaAsset.hasRole(MINTER_ROLE, owner.address)).to.be.true;
      expect(await rwaAsset.hasRole(PAUSER_ROLE, owner.address)).to.be.true;
      expect(await rwaAsset.hasRole(UPGRADER_ROLE, owner.address)).to.be.true;
    });
  });

  describe("Asset management", function () {
    let tokenId;

    beforeEach(async function () {
      await rwaAsset.whitelistAddress(addr1.address);
      tokenId = await rwaAsset.createAsset("Real Estate", ethers.utils.parseEther("1000"), "metadataURI", addr1.address);
    });

    it("should create a new asset", async function () {
      const asset = await rwaAsset.assets(tokenId);
      expect(asset.assetType).to.equal("Real Estate");
      expect(asset.originalValue.toString()).to.equal(ethers.utils.parseEther("1000").toString());
      expect(asset.currentValue.toString()).to.equal(ethers.utils.parseEther("1000").toString());
      expect(asset.metadataURI).to.equal("metadataURI");
      expect(asset.custodian).to.equal(addr1.address);
    });

    it("should emit AssetCreated event when a new asset is created", async function () {
      await expect(rwaAsset.createAsset("Vehicle", ethers.utils.parseEther("500"), "metadataURI2", addr1.address))
        .to.emit(rwaAsset, "AssetCreated")
        .withArgs(tokenId + 1, "Vehicle", ethers.utils.parseEther("500"));
    });

    it("should update the value of an existing asset", async function () {
      await rwaAsset.updateAssetValue(tokenId, ethers.utils.parseEther("2000"));
      const asset = await rwaAsset.assets(tokenId);
      expect(asset.currentValue.toString()).to.equal(ethers.utils.parseEther("2000").toString());
    });

    it("should emit AssetValueUpdated event when asset value is updated", async function () {
      await expect(rwaAsset.updateAssetValue(tokenId, ethers.utils.parseEther("2000")))
        .to.emit(rwaAsset, "AssetValueUpdated")
        .withArgs(tokenId, ethers.utils.parseEther("2000"));
    });

    it("should tokenize an asset", async function () {
      await rwaAsset.tokenizeAsset(tokenId, 50);
      const asset = await rwaAsset.assets(tokenId);
      expect(asset.tokenizationPercentage).to.equal(50);
      expect(asset.isTokenized).to.be.true;
    });

    it("should emit AssetTokenized event when an asset is tokenized", async function () {
      await expect(rwaAsset.tokenizeAsset(tokenId, 50))
        .to.emit(rwaAsset, "AssetTokenized")
        .withArgs(tokenId, 50);
    });

    it("should transfer shares of a tokenized asset", async function () {
      await rwaAsset.tokenizeAsset(tokenId, 50);
      await rwaAsset.transferShares(tokenId, addr2.address, 25);

      const shares = await rwaAsset.assetShares(tokenId, addr2.address);
      expect(shares.toString()).to.equal("25");
    });

    it("should emit ShareTransferred event when shares are transferred", async function () {
      await rwaAsset.tokenizeAsset(tokenId, 50);
      await expect(rwaAsset.transferShares(tokenId, addr2.address, 25))
        .to.emit(rwaAsset, "ShareTransferred")
        .withArgs(tokenId, owner.address, addr2.address, 25);
    });

    it("should update the risk level of an asset", async function () {
      await rwaAsset.updateRiskAssessment(tokenId);
      const asset = await rwaAsset.assets(tokenId);
      expect(asset.riskLevel).to.equal(2); // Assuming RiskLevel.Medium is 2
    });

    it("should emit RiskLevelUpdated event when risk level is updated", async function () {
      await expect(rwaAsset.updateRiskAssessment(tokenId))
        .to.emit(rwaAsset, "RiskLevelUpdated")
        .withArgs(tokenId, 2); // Assuming RiskLevel.Medium is 2
    });

    it("should whitelist and blacklist addresses", async function () {
      await rwaAsset.whitelistAddress(addr2.address);
      expect(await rwaAsset.whitelist(addr2.address)).to.be.true;

      await rwaAsset.blacklistAddress(addr2.address);
      expect(await rwaAsset.whitelist(addr2.address)).to.be.false;
    });
  });

  describe("Pausable functionality", function () {
    it("should allow pausing and unpausing by the pauser", async function () {
      await rwaAsset.pause();
      expect(await rwaAsset.paused()).to.be.true;

      await rwaAsset.unpause();
      expect(await rwaAsset.paused()).to.be.false;
    });

    it("should revert if non-pauser tries to pause or unpause", async function () {
      await expect(rwaAsset.connect(addr1).pause()).to.be.revertedWith("AccessControl: account ");
      await expect(rwaAsset.connect(addr1).unpause()).to.be.revertedWith("AccessControl: account ");
    });
  });

  describe("Upgradeable functionality", function () {
    it("should allow upgrading by the upgrader", async function () {
      const RWAAssetV2 = await ethers.getContractFactory("RWAAssetV2");
      await upgrades.upgradeProxy(rwaAsset.address, RWAAssetV2);
      const upgraded = await RWAAssetV2.attach(rwaAsset.address);
      expect(await upgraded.version()).to.equal("v2");
    });

    it("should revert if non-upgrader tries to upgrade", async function () {
      const RWAAssetV2 = await ethers.getContractFactory("RWAAssetV2");
      await expect(upgrades.upgradeProxy(rwaAsset.address, RWAAssetV2.connect(addr1))).to.be.revertedWith("AccessControl: account ");
    });
  });
});
