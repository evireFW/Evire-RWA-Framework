const AssetTokenization = artifacts.require("AssetTokenization");

contract("AssetTokenization", (accounts) => {
  let assetTokenization;
  const owner = accounts[0];
  const user1 = accounts[1];
  const user2 = accounts[2];

  beforeEach(async () => {
    assetTokenization = await AssetTokenization.new({ from: owner });
  });

  describe("Token Issuance", () => {
    it("should issue tokens correctly", async () => {
      const assetId = 1;
      const tokenAmount = 100;

      await assetTokenization.issueToken(assetId, user1, tokenAmount, { from: owner });
      const balance = await assetTokenization.balanceOf(user1, assetId);

      assert.equal(balance.toNumber(), tokenAmount, "Token amount should be correctly issued to user1");
    });

    it("should fail if not issued by owner", async () => {
      const assetId = 1;
      const tokenAmount = 100;

      try {
        await assetTokenization.issueToken(assetId, user1, tokenAmount, { from: user1 });
        assert.fail("Issue token should only be allowed by the owner");
      } catch (error) {
        assert(error.toString().includes("revert"), "Expected revert error");
      }
    });
  });

  describe("Token Transfer", () => {
    it("should transfer tokens correctly", async () => {
      const assetId = 1;
      const tokenAmount = 100;

      await assetTokenization.issueToken(assetId, user1, tokenAmount, { from: owner });
      await assetTokenization.transferToken(assetId, user1, user2, 50, { from: user1 });
      const balance1 = await assetTokenization.balanceOf(user1, assetId);
      const balance2 = await assetTokenization.balanceOf(user2, assetId);

      assert.equal(balance1.toNumber(), 50, "User1 should have 50 tokens left");
      assert.equal(balance2.toNumber(), 50, "User2 should have 50 tokens received");
    });

    it("should fail transfer if sender doesn't have enough tokens", async () => {
      const assetId = 1;
      const tokenAmount = 100;

      await assetTokenization.issueToken(assetId, user1, tokenAmount, { from: owner });
      
      try {
        await assetTokenization.transferToken(assetId, user1, user2, 200, { from: user1 });
        assert.fail("Should not allow transfer more tokens than balance");
      } catch (error) {
        assert(error.toString().includes("revert"), "Expected revert error");
      }
    });
  });

  describe("Token Burning", () => {
    it("should burn tokens correctly", async () => {
      const assetId = 1;
      const tokenAmount = 100;

      await assetTokenization.issueToken(assetId, user1, tokenAmount, { from: owner });
      await assetTokenization.burnToken(assetId, user1, 50, { from: user1 });
      const balance = await assetTokenization.balanceOf(user1, assetId);

      assert.equal(balance.toNumber(), 50, "User1 should have 50 tokens left after burning");
    });

    it("should fail burn if user doesn't have enough tokens", async () => {
      const assetId = 1;
      const tokenAmount = 100;

      await assetTokenization.issueToken(assetId, user1, tokenAmount, { from: owner });
      
      try {
        await assetTokenization.burnToken(assetId, user1, 200, { from: user1 });
        assert.fail("Should not allow burning more tokens than balance");
      } catch (error) {
        assert(error.toString().includes("revert"), "Expected revert error");
      }
    });
  });

  describe("Token Attributes", () => {
    it("should correctly set and get token attributes", async () => {
      const assetId = 1;
      const tokenAmount = 100;
      const attributeName = "location";
      const attributeValue = "New York";

      await assetTokenization.issueToken(assetId, user1, tokenAmount, { from: owner });
      await assetTokenization.setTokenAttribute(assetId, attributeName, attributeValue, { from: owner });
      const storedValue = await assetTokenization.getTokenAttribute(assetId, attributeName);

      assert.equal(storedValue, attributeValue, "Token attribute should be correctly set and retrieved");
    });

    it("should fail setting attributes by non-owner", async () => {
      const assetId = 1;
      const tokenAmount = 100;
      const attributeName = "location";
      const attributeValue = "New York";

      await assetTokenization.issueToken(assetId, user1, tokenAmount, { from: owner });

      try {
        await assetTokenization.setTokenAttribute(assetId, attributeName, attributeValue, { from: user1 });
        assert.fail("Non-owner should not be able to set token attributes");
      } catch (error) {
        assert(error.toString().includes("revert"), "Expected revert error");
      }
    });
  });
});
