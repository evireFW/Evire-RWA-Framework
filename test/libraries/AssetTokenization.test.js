const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AssetTokenization", function () {
  let AssetTokenization;
  let owner, addr1, addr2;
  let assets;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const AssetTokenizationFactory = await ethers.getContractFactory("AssetTokenization");
    AssetTokenization = await AssetTokenizationFactory.deploy();
    await AssetTokenization.deployed();
    assets = {};
  });

  describe("tokenizeAsset", function () {
    it("should tokenize a new asset correctly", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      expect(assets[assetId].id).to.equal(assetId);
      expect(assets[assetId].assetType).to.equal(params.assetType);
      expect(assets[assetId].value).to.equal(params.initialValue);
      expect(assets[assetId].owner).to.equal(owner.address);
      expect(assets[assetId].isFragmented).to.be.true;
      expect(assets[assetId].totalFragments).to.equal(params.totalFragments);
      expect(assets[assetId].fragmentBalances[owner.address]).to.equal(params.totalFragments);
    });

    it("should emit AssetTokenized and AssetFragmented events", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      await expect(AssetTokenization.tokenizeAsset(assets, params, owner.address))
        .to.emit(AssetTokenization, "AssetTokenized")
        .withArgs(params.assetType, owner.address, params.initialValue)
        .and.to.emit(AssetTokenization, "AssetFragmented")
        .withArgs(params.assetType, params.totalFragments);
    });

    it("should revert if the owner is not verified", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      await expect(
        AssetTokenization.tokenizeAsset(assets, params, addr1.address)
      ).to.be.revertedWith("Owner must be verified");
    });

    it("should revert if the asset type is invalid", async function () {
      const params = {
        assetType: "InvalidType",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      await expect(
        AssetTokenization.tokenizeAsset(assets, params, owner.address)
      ).to.be.revertedWith("Invalid asset type");
    });
  });

  describe("fragmentAsset", function () {
    it("should fragment an existing non-fragmented asset", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: false,
        totalFragments: 0
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);
      await AssetTokenization.fragmentAsset(assets, assetId, 100);

      expect(assets[assetId].isFragmented).to.be.true;
      expect(assets[assetId].totalFragments).to.equal(100);
      expect(assets[assetId].fragmentBalances[owner.address]).to.equal(100);
    });

    it("should emit AssetFragmented event", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: false,
        totalFragments: 0
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      await expect(AssetTokenization.fragmentAsset(assets, assetId, 100))
        .to.emit(AssetTokenization, "AssetFragmented")
        .withArgs(assetId, 100);
    });

    it("should revert if the asset is already fragmented", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      await expect(AssetTokenization.fragmentAsset(assets, assetId, 100)).to.be.revertedWith("Asset is already fragmented");
    });

    it("should revert if total fragments is zero", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: false,
        totalFragments: 0
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      await expect(AssetTokenization.fragmentAsset(assets, assetId, 0)).to.be.revertedWith("Total fragments must be greater than zero");
    });
  });

  describe("transferFragments", function () {
    it("should transfer fragments from one address to another", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);
      await AssetTokenization.transferFragments(assets, assetId, owner.address, addr1.address, 50);

      expect(assets[assetId].fragmentBalances[owner.address]).to.equal(50);
      expect(assets[assetId].fragmentBalances[addr1.address]).to.equal(50);
    });

    it("should emit FragmentTransferred event", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      await expect(AssetTokenization.transferFragments(assets, assetId, owner.address, addr1.address, 50))
        .to.emit(AssetTokenization, "FragmentTransferred")
        .withArgs(assetId, owner.address, addr1.address, 50);
    });

    it("should revert if asset is not fragmented", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: false,
        totalFragments: 0
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      await expect(AssetTokenization.transferFragments(assets, assetId, owner.address, addr1.address, 50)).to.be.revertedWith("Asset is not fragmented");
    });

    it("should revert if sender has insufficient fragment balance", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      await expect(AssetTokenization.transferFragments(assets, assetId, owner.address, addr1.address, 150)).to.be.revertedWith("Insufficient fragment balance");
    });
  });

  describe("updateAssetValue", function () {
    it("should update the value of an asset", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);
      const newValue = ethers.utils.parseEther("2000");

      await AssetTokenization.updateAssetValue(assets, assetId, newValue);

      expect(assets[assetId].value).to.equal(newValue);
    });

    it("should emit AssetValueUpdated event", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);
      const newValue = ethers.utils.parseEther("2000");

      await expect(AssetTokenization.updateAssetValue(assets, assetId, newValue))
        .to.emit(AssetTokenization, "AssetValueUpdated")
        .withArgs(assetId, newValue);
    });

    it("should revert if asset does not exist", async function () {
      const assetId = 1;
      const newValue = ethers.utils.parseEther("2000");

      await expect(AssetTokenization.updateAssetValue(assets, assetId, newValue)).to.be.revertedWith("Asset does not exist");
    });
  });

  describe("getFragmentBalance", function () {
    it("should return the correct fragment balance", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      expect(await AssetTokenization.getFragmentBalance(assets, assetId, owner.address)).to.equal(100);
    });

    it("should revert if asset is not fragmented", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: false,
        totalFragments: 0
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      await expect(AssetTokenization.getFragmentBalance(assets, assetId, owner.address)).to.be.revertedWith("Asset is not fragmented");
    });
  });

  describe("calculateFragmentValue", function () {
    it("should calculate the correct fragment value", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);
      const fragmentCount = 50;
      const expectedValue = ethers.utils.parseEther("500");

      expect(await AssetTokenization.calculateFragmentValue(assets, assetId, fragmentCount)).to.equal(expectedValue);
    });

    it("should revert if asset is not fragmented", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: false,
        totalFragments: 0
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);
      const fragmentCount = 50;

      await expect(AssetTokenization.calculateFragmentValue(assets, assetId, fragmentCount)).to.be.revertedWith("Asset is not fragmented");
    });

    it("should revert if fragment count exceeds total fragments", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);
      const fragmentCount = 150;

      await expect(AssetTokenization.calculateFragmentValue(assets, assetId, fragmentCount)).to.be.revertedWith("Fragment count exceeds total fragments");
    });
  });

  describe("isAssetOwner", function () {
    it("should return true if the address is the owner of the asset", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      expect(await AssetTokenization.isAssetOwner(assets, assetId, owner.address)).to.be.true;
    });

    it("should return false if the address is not the owner of the asset", async function () {
      const params = {
        assetType: "Real Estate",
        initialValue: ethers.utils.parseEther("1000"),
        isFragmented: true,
        totalFragments: 100
      };

      const assetId = await AssetTokenization.tokenizeAsset(assets, params, owner.address);

      expect(await AssetTokenization.isAssetOwner(assets, assetId, addr1.address)).to.be.false;
    });
  });
});
