const OwnershipTransfer = artifacts.require("OwnershipTransfer");
const { expect } = require("chai");
const { BN, expectEvent, expectRevert } = require("@openzeppelin/test-helpers");

contract("OwnershipTransfer", (accounts) => {
  const [owner, newOwner, unauthorized] = accounts;

  let ownershipTransferInstance;

  beforeEach(async () => {
    ownershipTransferInstance = await OwnershipTransfer.new({ from: owner });
  });

  describe("Initial State", () => {
    it("should set the initial owner correctly", async () => {
      const currentOwner = await ownershipTransferInstance.owner();
      expect(currentOwner).to.equal(owner);
    });
  });

  describe("Transfer Ownership", () => {
    it("should transfer ownership to the new owner", async () => {
      const receipt = await ownershipTransferInstance.transferOwnership(newOwner, { from: owner });
      expectEvent(receipt, "OwnershipTransferred", {
        previousOwner: owner,
        newOwner: newOwner,
      });

      const currentOwner = await ownershipTransferInstance.owner();
      expect(currentOwner).to.equal(newOwner);
    });

    it("should not allow unauthorized accounts to transfer ownership", async () => {
      await expectRevert(
        ownershipTransferInstance.transferOwnership(newOwner, { from: unauthorized }),
        "Ownable: caller is not the owner"
      );
    });

    it("should revert if new owner is the zero address", async () => {
      await expectRevert(
        ownershipTransferInstance.transferOwnership("0x0000000000000000000000000000000000000000", { from: owner }),
        "Ownable: new owner is the zero address"
      );
    });
  });

  describe("Ownership Restrictions", () => {
    it("should allow only the current owner to call restricted functions", async () => {
      // Example of a restricted function call, replace `restrictedFunction` with an actual restricted function in OwnershipTransfer
      await expectRevert(
        ownershipTransferInstance.restrictedFunction({ from: unauthorized }),
        "Ownable: caller is not the owner"
      );

      const result = await ownershipTransferInstance.restrictedFunction({ from: owner });
      expect(result).to.be.true;
    });
  });

  describe("Ownership Transfer Events", () => {
    it("should emit an event on ownership transfer", async () => {
      const receipt = await ownershipTransferInstance.transferOwnership(newOwner, { from: owner });
      expectEvent(receipt, "OwnershipTransferred", {
        previousOwner: owner,
        newOwner: newOwner,
      });
    });
  });

  describe("Edge Cases", () => {
    it("should revert if transferring ownership to the same owner", async () => {
      await expectRevert(
        ownershipTransferInstance.transferOwnership(owner, { from: owner }),
        "Ownable: new owner is the current owner"
      );
    });

    it("should handle multiple ownership transfers correctly", async () => {
      await ownershipTransferInstance.transferOwnership(newOwner, { from: owner });
      const secondNewOwner = accounts[2];
      await ownershipTransferInstance.transferOwnership(secondNewOwner, { from: newOwner });

      const currentOwner = await ownershipTransferInstance.owner();
      expect(currentOwner).to.equal(secondNewOwner);
    });
  });
});
