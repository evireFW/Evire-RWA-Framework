const AssetValuation = artifacts.require("AssetValuation");

contract("AssetValuation", (accounts) => {
  let assetValuation;

  before(async () => {
    assetValuation = await AssetValuation.deployed();
  });

  describe("Asset Valuation", () => {
    it("should correctly initialize the contract", async () => {
      assert(assetValuation.address !== "");
    });

    it("should return correct valuation for a given asset type and parameters", async () => {
      // Example values for the test
      const assetType = web3.utils.keccak256("RealEstate");
      const assetParameters = web3.utils.keccak256("Location,Size,Condition");

      // Call the valuation function
      const valuation = await assetValuation.calculateValuation(assetType, assetParameters, { from: accounts[0] });
      
      // Assuming the valuation should be 100000 for this example
      assert.equal(valuation.toNumber(), 100000, "Valuation does not match expected value");
    });

    it("should handle multiple asset types and return correct valuations", async () => {
      const assetTypes = [
        web3.utils.keccak256("RealEstate"),
        web3.utils.keccak256("Artwork"),
        web3.utils.keccak256("Vehicle")
      ];
      const assetParameters = [
        web3.utils.keccak256("Location,Size,Condition"),
        web3.utils.keccak256("Artist,Year,Condition"),
        web3.utils.keccak256("Make,Model,Year,Condition")
      ];

      const expectedValuations = [100000, 50000, 20000];

      for (let i = 0; i < assetTypes.length; i++) {
        const valuation = await assetValuation.calculateValuation(assetTypes[i], assetParameters[i], { from: accounts[0] });
        assert.equal(valuation.toNumber(), expectedValuations[i], `Valuation for ${assetTypes[i]} does not match expected value`);
      }
    });

    it("should revert if the asset type is invalid", async () => {
      const invalidAssetType = web3.utils.keccak256("InvalidType");
      const assetParameters = web3.utils.keccak256("Parameter1,Parameter2");

      try {
        await assetValuation.calculateValuation(invalidAssetType, assetParameters, { from: accounts[0] });
        assert.fail("Expected revert not received");
      } catch (error) {
        assert(error.message.includes("revert"), "Expected revert, got " + error.message);
      }
    });

    it("should revert if the asset parameters are invalid", async () => {
      const assetType = web3.utils.keccak256("RealEstate");
      const invalidParameters = web3.utils.keccak256("InvalidParameter");

      try {
        await assetValuation.calculateValuation(assetType, invalidParameters, { from: accounts[0] });
        assert.fail("Expected revert not received");
      } catch (error) {
        assert(error.message.includes("revert"), "Expected revert, got " + error.message);
      }
    });
  });

  describe("Event Emissions", () => {
    it("should emit ValuationCalculated event", async () => {
      const assetType = web3.utils.keccak256("RealEstate");
      const assetParameters = web3.utils.keccak256("Location,Size,Condition");

      const result = await assetValuation.calculateValuation(assetType, assetParameters, { from: accounts[0] });

      const log = result.logs[0];
      assert.equal(log.event, "ValuationCalculated", "ValuationCalculated event not emitted");
      assert.equal(log.args.assetType, assetType, "Asset type in event log does not match");
      assert.equal(log.args.valuation.toNumber(), 100000, "Valuation in event log does not match expected value");
    });
  });

  describe("Edge Cases", () => {
    it("should handle large input values correctly", async () => {
      const assetType = web3.utils.keccak256("RealEstate");
      const largeParameters = web3.utils.keccak256("VeryLargeParameterValues");

      const valuation = await assetValuation.calculateValuation(assetType, largeParameters, { from: accounts[0] });

      // Assuming the valuation should be 1000000 for this example
      assert.equal(valuation.toNumber(), 1000000, "Valuation for large inputs does not match expected value");
    });
  });
});
