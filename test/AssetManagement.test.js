const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AssetManagement", function () {
  let AssetManagement, assetManagement;
  let Compliance, compliance;
  let owner, addr1, addr2;
  let tokenId;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the Compliance contract first
    Compliance = await ethers.getContractFactory("Compliance");
    compliance = await Compliance.deploy();
    await compliance.deployed();

    // Ensure addr1 and addr2 are compliant
    await compliance.addCompliantAddress(addr1.address);
    await compliance.addCompliantAddress(addr2.address);

    // Deploy the AssetManagement contract with the address of the Compliance contract
    AssetManagement = await ethers.getContractFactory("AssetManagement");
    assetManagement = await AssetManagement.deploy(compliance.address);
    await assetManagement.deployed();
  });

  describe("Asset creation", function () {
    it("should create a new asset", async function () {
      const assetType = "Real Estate";
      const initialValue = ethers.utils.parseEther("100");
      const metadata = "Location: New York, Size: 1000 sqft";

      const tx = await assetManagement.createAsset(addr1.address, assetType, initialValue, metadata);
      const receipt = await tx.wait();
      const event = receipt.events.find(event => event.event === "AssetCreated");
      tokenId = event.args.tokenId;

      expect(await assetManagement.ownerOf(tokenId)).to.equal(addr1.address);

      const asset = await assetManagement.getAssetDetails(tokenId);
      expect(asset.assetType).to.equal(assetType);
      expect(asset.value.toString()).to.equal(initialValue.toString());
      expect(asset.metadata).to.equal(metadata);
      expect(asset.isActive).to.be.true;
    });

    it("should not create an asset for a non-compliant address", async function () {
      const assetType = "Real Estate";
      const initialValue = ethers.utils.parseEther("100");
      const metadata = "Location: New York, Size: 1000 sqft";

      await expect(assetManagement.createAsset(addr2.address, assetType, initialValue, metadata))
        .to.be.revertedWith("Recipient is not compliant");
    });
  });

  describe("Asset management", function () {
    beforeEach(async function () {
      const assetType = "Real Estate";
      const initialValue = ethers.utils.parseEther("100");
      const metadata = "Location: New York, Size: 1000 sqft";

      const tx = await assetManagement.createAsset(addr1.address, assetType, initialValue, metadata);
      const receipt = await tx.wait();
      const event = receipt.events.find(event => event.event === "AssetCreated");
      tokenId = event.args.tokenId;
    });

    it("should update the value of an active asset", async function () {
      const newValue = ethers.utils.parseEther("120");

      await assetManagement.updateAssetValue(tokenId, newValue);

      const asset = await assetManagement.getAssetDetails(tokenId);
      expect(asset.value.toString()).to.equal(newValue.toString());
    });

    it("should not update the value of an inactive asset", async function () {
      await assetManagement.deactivateAsset(tokenId);
      const newValue = ethers.utils.parseEther("120");

      await expect(assetManagement.updateAssetValue(tokenId, newValue))
        .to.be.revertedWith("Asset is not active");
    });

    it("should deactivate an active asset", async function () {
      await assetManagement.deactivateAsset(tokenId);

      const asset = await assetManagement.getAssetDetails(tokenId);
      expect(asset.isActive).to.be.false;
    });

    it("should not deactivate an asset that is already inactive", async function () {
      await assetManagement.deactivateAsset(tokenId);

      await expect(assetManagement.deactivateAsset(tokenId))
        .to.be.revertedWith("Asset is already inactive");
    });

    it("should retrieve the correct asset details", async function () {
      const asset = await assetManagement.getAssetDetails(tokenId);
      expect(asset.assetType).to.equal("Real Estate");
      expect(asset.metadata).to.equal("Location: New York, Size: 1000 sqft");
    });

    it("should retrieve the correct asset value", async function () {
      const assetValue = await assetManagement.getAssetValue(tokenId);
      expect(assetValue.toString()).to.equal(ethers.utils.parseEther("100").toString());
    });
  });

  describe("Asset transfer", function () {
    beforeEach(async function () {
      const assetType = "Real Estate";
      const initialValue = ethers.utils.parseEther("100");
      const metadata = "Location: New York, Size: 1000 sqft";

      const tx = await assetManagement.createAsset(addr1.address, assetType, initialValue, metadata);
      const receipt = await tx.wait();
      const event = receipt.events.find(event => event.event === "AssetCreated");
      tokenId = event.args.tokenId;
    });

    it("should transfer an active asset to a compliant address", async function () {
      await assetManagement.connect(addr1).transferAsset(addr1.address, addr2.address, tokenId);

      expect(await assetManagement.ownerOf(tokenId)).to.equal(addr2.address);
    });

    it("should not transfer an active asset to a non-compliant address", async function () {
      await compliance.removeCompliantAddress(addr2.address);

      await expect(assetManagement.connect(addr1).transferAsset(addr1.address, addr2.address, tokenId))
        .to.be.revertedWith("Recipient is not compliant");
    });

    it("should not transfer an inactive asset", async function () {
      await assetManagement.deactivateAsset(tokenId);

      await expect(assetManagement.connect(addr1).transferAsset(addr1.address, addr2.address, tokenId))
        .to.be.revertedWith("Asset is not active");
    });
  });
});
