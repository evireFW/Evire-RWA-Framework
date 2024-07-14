const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RWAToken", function () {
  let RWAToken, rwaToken;
  let owner, addr1, addr2;
  
  const initialSupply = ethers.utils.parseEther("1000");
  const maxSupply = ethers.utils.parseEther("1000000");
  const assetIdentifier = "RealEstate123";

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the RWAToken contract
    RWAToken = await ethers.getContractFactory("RWAToken");
    rwaToken = await RWAToken.deploy("RWA Token", "RWAT", assetIdentifier);
    await rwaToken.deployed();
  });

  describe("Initialization", function () {
    it("should initialize with the correct parameters", async function () {
      expect(await rwaToken.name()).to.equal("RWA Token");
      expect(await rwaToken.symbol()).to.equal("RWAT");
      expect(await rwaToken.assetIdentifier()).to.equal(assetIdentifier);
    });

    it("should assign roles correctly", async function () {
      const DEFAULT_ADMIN_ROLE = await rwaToken.DEFAULT_ADMIN_ROLE();
      const MINTER_ROLE = await rwaToken.MINTER_ROLE();
      const PAUSER_ROLE = await rwaToken.PAUSER_ROLE();
      const COMPLIANCE_ROLE = await rwaToken.COMPLIANCE_ROLE();

      expect(await rwaToken.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.be.true;
      expect(await rwaToken.hasRole(MINTER_ROLE, owner.address)).to.be.true;
      expect(await rwaToken.hasRole(PAUSER_ROLE, owner.address)).to.be.true;
      expect(await rwaToken.hasRole(COMPLIANCE_ROLE, owner.address)).to.be.true;
    });
  });

  describe("Minting and burning tokens", function () {
    beforeEach(async function () {
      await rwaToken.addToWhitelist(addr1.address);
    });

    it("should allow minters to mint tokens", async function () {
      const mintAmount = ethers.utils.parseEther("100");
      await rwaToken.mint(addr1.address, mintAmount);

      expect(await rwaToken.totalSupply()).to.equal(mintAmount);
      expect(await rwaToken.balanceOf(addr1.address)).to.equal(mintAmount);
    });

    it("should not allow minting more than the max supply", async function () {
      const mintAmount = maxSupply.add(ethers.utils.parseEther("1"));
      await expect(rwaToken.mint(addr1.address, mintAmount)).to.be.revertedWith("Exceeds max supply");
    });

    it("should allow token holders to burn tokens", async function () {
      const mintAmount = ethers.utils.parseEther("100");
      await rwaToken.mint(addr1.address, mintAmount);

      await rwaToken.connect(addr1).burn(mintAmount.sub(ethers.utils.parseEther("50")));

      expect(await rwaToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("50"));
      expect(await rwaToken.totalSupply()).to.equal(ethers.utils.parseEther("50"));
    });
  });

  describe("Pausing and unpausing", function () {
    it("should allow pausers to pause and unpause the contract", async function () {
      await rwaToken.pause();
      expect(await rwaToken.paused()).to.be.true;

      await rwaToken.unpause();
      expect(await rwaToken.paused()).to.be.false;
    });

    it("should not allow non-pausers to pause or unpause the contract", async function () {
      await expect(rwaToken.connect(addr1).pause()).to.be.revertedWith("AccessControl: account " + addr1.address.toLowerCase() + " is missing role " + (await rwaToken.PAUSER_ROLE()));
      await expect(rwaToken.connect(addr1).unpause()).to.be.revertedWith("AccessControl: account " + addr1.address.toLowerCase() + " is missing role " + (await rwaToken.PAUSER_ROLE()));
    });
  });

  describe("Whitelist management", function () {
    it("should allow compliance role to add and remove addresses from whitelist", async function () {
      await rwaToken.addToWhitelist(addr1.address);
      expect(await rwaToken.whitelist(addr1.address)).to.be.true;

      await rwaToken.removeFromWhitelist(addr1.address);
      expect(await rwaToken.whitelist(addr1.address)).to.be.false;
    });

    it("should emit events when addresses are added or removed from whitelist", async function () {
      await expect(rwaToken.addToWhitelist(addr1.address))
        .to.emit(rwaToken, "AddressWhitelisted")
        .withArgs(addr1.address);

      await expect(rwaToken.removeFromWhitelist(addr1.address))
        .to.emit(rwaToken, "AddressRemovedFromWhitelist")
        .withArgs(addr1.address);
    });

    it("should not allow non-compliance roles to add or remove addresses from whitelist", async function () {
      await expect(rwaToken.connect(addr1).addToWhitelist(addr2.address)).to.be.revertedWith("AccessControl: account " + addr1.address.toLowerCase() + " is missing role " + (await rwaToken.COMPLIANCE_ROLE()));
      await expect(rwaToken.connect(addr1).removeFromWhitelist(addr2.address)).to.be.revertedWith("AccessControl: account " + addr1.address.toLowerCase() + " is missing role " + (await rwaToken.COMPLIANCE_ROLE()));
    });
  });

  describe("Transfers with whitelist checks", function () {
    beforeEach(async function () {
      await rwaToken.addToWhitelist(addr1.address);
      await rwaToken.addToWhitelist(addr2.address);
      await rwaToken.mint(addr1.address, ethers.utils.parseEther("100"));
    });

    it("should allow transfers between whitelisted addresses", async function () {
      await rwaToken.connect(addr1).transfer(addr2.address, ethers.utils.parseEther("50"));
      expect(await rwaToken.balanceOf(addr2.address)).to.equal(ethers.utils.parseEther("50"));
    });

    it("should not allow transfers to non-whitelisted addresses", async function () {
      await rwaToken.removeFromWhitelist(addr2.address);
      await expect(rwaToken.connect(addr1).transfer(addr2.address, ethers.utils.parseEther("50"))).to.be.revertedWith("Recipient not whitelisted");
    });

    it("should not allow transfers from non-whitelisted addresses", async function () {
      await rwaToken.removeFromWhitelist(addr1.address);
      await expect(rwaToken.connect(addr1).transfer(addr2.address, ethers.utils.parseEther("50"))).to.be.revertedWith("Recipient not whitelisted");
    });

    it("should allow transfers from whitelisted addresses to non-whitelisted addresses when unpaused", async function () {
      await rwaToken.removeFromWhitelist(addr2.address);
      await rwaToken.pause();
      await expect(rwaToken.connect(addr1).transfer(addr2.address, ethers.utils.parseEther("50"))).to.be.revertedWith("Pausable: paused");
      await rwaToken.unpause();
      await expect(rwaToken.connect(addr1).transfer(addr2.address, ethers.utils.parseEther("50"))).to.be.revertedWith("Recipient not whitelisted");
    });
  });

  describe("Asset value management", function () {
    it("should allow admin to update asset value", async function () {
      const newValue = ethers.utils.parseEther("5000");
      await rwaToken.updateAssetValue(newValue);
      expect(await rwaToken.assetValue()).to.equal(newValue);
    });

    it("should emit AssetValueUpdated event when asset value is updated", async function () {
      const newValue = ethers.utils.parseEther("5000");
      await expect(rwaToken.updateAssetValue(newValue))
        .to.emit(rwaToken, "AssetValueUpdated")
        .withArgs(newValue);
    });

    it("should not allow non-admins to update asset value", async function () {
      const newValue = ethers.utils.parseEther("5000");
      await expect(rwaToken.connect(addr1).updateAssetValue(newValue)).to.be.revertedWith("AccessControl: account " + addr1.address.toLowerCase() + " is missing role " + (await rwaToken.DEFAULT_ADMIN_ROLE()));
    });
  });
});
