const RiskAssessment = artifacts.require("RiskAssessment");

contract("RiskAssessment", (accounts) => {
  let riskAssessmentInstance;

  before(async () => {
    riskAssessmentInstance = await RiskAssessment.deployed();
  });

  describe("Risk assessment functions", () => {
    it("should correctly evaluate low risk", async () => {
      const riskLevel = await riskAssessmentInstance.evaluateRisk(100, 5, 0, 0);
      assert.equal(riskLevel.toNumber(), 1, "Risk level should be low (1)");
    });

    it("should correctly evaluate medium risk", async () => {
      const riskLevel = await riskAssessmentInstance.evaluateRisk(500, 20, 1, 0);
      assert.equal(riskLevel.toNumber(), 2, "Risk level should be medium (2)");
    });

    it("should correctly evaluate high risk", async () => {
      const riskLevel = await riskAssessmentInstance.evaluateRisk(1000, 50, 2, 1);
      assert.equal(riskLevel.toNumber(), 3, "Risk level should be high (3)");
    });

    it("should handle edge cases for very low risk", async () => {
      const riskLevel = await riskAssessmentInstance.evaluateRisk(50, 1, 0, 0);
      assert.equal(riskLevel.toNumber(), 1, "Risk level should be low (1) even for very low values");
    });

    it("should handle edge cases for very high risk", async () => {
      const riskLevel = await riskAssessmentInstance.evaluateRisk(5000, 100, 5, 3);
      assert.equal(riskLevel.toNumber(), 3, "Risk level should be high (3) for very high values");
    });

    it("should correctly identify and categorize risk factors", async () => {
      const factors = await riskAssessmentInstance.identifyRiskFactors(1000, 10, 1, 1);
      assert.deepEqual(
        factors.map(f => f.toNumber()),
        [1, 1, 0, 0],
        "Risk factors should be correctly identified and categorized"
      );
    });

    it("should calculate risk score accurately", async () => {
      const riskScore = await riskAssessmentInstance.calculateRiskScore(1000, 50, 2, 1);
      assert.equal(riskScore.toNumber(), 76, "Risk score should be correctly calculated");
    });
  });

  describe("Boundary and validation tests", () => {
    it("should revert if negative values are provided", async () => {
      try {
        await riskAssessmentInstance.evaluateRisk(-100, 5, 0, 0);
        assert.fail("Expected revert not received");
      } catch (error) {
        assert(error.message.includes("revert"), `Expected "revert", got ${error.message} instead`);
      }
    });

    it("should revert if excessively high values are provided", async () => {
      try {
        await riskAssessmentInstance.evaluateRisk(1e10, 5, 0, 0);
        assert.fail("Expected revert not received");
      } catch (error) {
        assert(error.message.includes("revert"), `Expected "revert", got ${error.message} instead`);
      }
    });

    it("should revert if non-integer values are provided", async () => {
      try {
        await riskAssessmentInstance.evaluateRisk(100.5, 5, 0, 0);
        assert.fail("Expected revert not received");
      } catch (error) {
        assert(error.message.includes("revert"), `Expected "revert", got ${error.message} instead`);
      }
    });
  });
});
