// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DataVerification.sol";
import "./AssetValuation.sol";

/**
 * @title RiskAssessment
 * @dev Library for assessing risks associated with Real World Assets (RWA) on blockchain
 */
library RiskAssessment {
    // Risk categories
    enum RiskCategory { 
        MARKET,
        CREDIT,
        LIQUIDITY,
        OPERATIONAL,
        LEGAL,
        ENVIRONMENTAL
    }

    // Risk levels
    enum RiskLevel { 
        LOW,
        MEDIUM,
        HIGH,
        CRITICAL
    }

    // Struct to hold risk assessment results
    struct RiskAssessmentResult {
        RiskCategory category;
        RiskLevel level;
        uint256 score;
        string description;
    }

    // Struct to hold risk parameters
    struct RiskParameters {
        uint256 volatility; // 0 to 100
        uint256 correlationFactor; // 0 to 100
        uint256 defaultProbability; // 0 to 100
        uint256 recoveryRate; // 0 to 100
        uint256 liquidityRatio; // 0 to 100
        uint256 operationalErrorRate; // 0 to 100
        uint256 legalComplianceScore; // 0 to 100
        uint256 environmentalImpactScore; // 0 to 100
    }

    // Events
    event RiskAssessed(address indexed asset, RiskCategory category, RiskLevel level, uint256 score);

    // Constants
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MAX_PERCENTAGE = 100;
    uint256 private constant RISK_THRESHOLD_LOW = PRECISION * 30 / 100; // 30% of PRECISION
    uint256 private constant RISK_THRESHOLD_MEDIUM = PRECISION * 60 / 100; // 60% of PRECISION
    uint256 private constant RISK_THRESHOLD_HIGH = PRECISION * 90 / 100; // 90% of PRECISION

    /**
     * @dev Assess overall risk for an asset
     * @param assetAddress Address of the asset contract
     * @param params Risk parameters for the asset
     * @return Array of RiskAssessmentResult structs
     */
    function assessOverallRisk(address assetAddress, RiskParameters memory params) 
        public 
        returns (RiskAssessmentResult[] memory) 
    {
        RiskAssessmentResult;

        results[0] = assessMarketRisk(assetAddress, params.volatility, params.correlationFactor);
        results[1] = assessCreditRisk(assetAddress, params.defaultProbability, params.recoveryRate);
        results[2] = assessLiquidityRisk(assetAddress, params.liquidityRatio);
        results[3] = assessOperationalRisk(assetAddress, params.operationalErrorRate);
        results[4] = assessLegalRisk(assetAddress, params.legalComplianceScore);
        results[5] = assessEnvironmentalRisk(assetAddress, params.environmentalImpactScore);

        return results;
    }

    /**
     * @dev Assess market risk for an asset
     * @param assetAddress Address of the asset contract
     * @param volatility Asset price volatility (0 to 100)
     * @param correlationFactor Correlation with market benchmark (0 to 100)
     * @return RiskAssessmentResult struct for market risk
     */
    function assessMarketRisk(address assetAddress, uint256 volatility, uint256 correlationFactor) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 marketRiskScore = calculateMarketRiskScore(volatility, correlationFactor);
        RiskLevel riskLevel = determineRiskLevel(marketRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.MARKET,
            level: riskLevel,
            score: marketRiskScore,
            description: "Market risk based on volatility and correlation"
        });

        emit RiskAssessed(assetAddress, RiskCategory.MARKET, riskLevel, marketRiskScore);
        return result;
    }

    /**
     * @dev Assess credit risk for an asset
     * @param assetAddress Address of the asset contract
     * @param defaultProbability Probability of default (0 to 100)
     * @param recoveryRate Expected recovery rate in case of default (0 to 100)
     * @return RiskAssessmentResult struct for credit risk
     */
    function assessCreditRisk(address assetAddress, uint256 defaultProbability, uint256 recoveryRate) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 creditRiskScore = calculateCreditRiskScore(defaultProbability, recoveryRate);
        RiskLevel riskLevel = determineRiskLevel(creditRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.CREDIT,
            level: riskLevel,
            score: creditRiskScore,
            description: "Credit risk based on default probability and recovery rate"
        });

        emit RiskAssessed(assetAddress, RiskCategory.CREDIT, riskLevel, creditRiskScore);
        return result;
    }

    /**
     * @dev Assess liquidity risk for an asset
     * @param assetAddress Address of the asset contract
     * @param liquidityRatio Liquidity ratio of the asset (0 to 100)
     * @return RiskAssessmentResult struct for liquidity risk
     */
    function assessLiquidityRisk(address assetAddress, uint256 liquidityRatio) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 liquidityRiskScore = calculateLiquidityRiskScore(liquidityRatio);
        RiskLevel riskLevel = determineRiskLevel(liquidityRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.LIQUIDITY,
            level: riskLevel,
            score: liquidityRiskScore,
            description: "Liquidity risk based on liquidity ratio"
        });

        emit RiskAssessed(assetAddress, RiskCategory.LIQUIDITY, riskLevel, liquidityRiskScore);
        return result;
    }

    /**
     * @dev Assess operational risk for an asset
     * @param assetAddress Address of the asset contract
     * @param operationalErrorRate Rate of operational errors (0 to 100)
     * @return RiskAssessmentResult struct for operational risk
     */
    function assessOperationalRisk(address assetAddress, uint256 operationalErrorRate) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 operationalRiskScore = calculateOperationalRiskScore(operationalErrorRate);
        RiskLevel riskLevel = determineRiskLevel(operationalRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.OPERATIONAL,
            level: riskLevel,
            score: operationalRiskScore,
            description: "Operational risk based on error rate"
        });

        emit RiskAssessed(assetAddress, RiskCategory.OPERATIONAL, riskLevel, operationalRiskScore);
        return result;
    }

    /**
     * @dev Assess legal risk for an asset
     * @param assetAddress Address of the asset contract
     * @param legalComplianceScore Legal compliance score (0 to 100)
     * @return RiskAssessmentResult struct for legal risk
     */
    function assessLegalRisk(address assetAddress, uint256 legalComplianceScore) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 legalRiskScore = calculateLegalRiskScore(legalComplianceScore);
        RiskLevel riskLevel = determineRiskLevel(legalRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.LEGAL,
            level: riskLevel,
            score: legalRiskScore,
            description: "Legal risk based on compliance score"
        });

        emit RiskAssessed(assetAddress, RiskCategory.LEGAL, riskLevel, legalRiskScore);
        return result;
    }

    /**
     * @dev Assess environmental risk for an asset
     * @param assetAddress Address of the asset contract
     * @param environmentalImpactScore Environmental impact score (0 to 100)
     * @return RiskAssessmentResult struct for environmental risk
     */
    function assessEnvironmentalRisk(address assetAddress, uint256 environmentalImpactScore) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 environmentalRiskScore = calculateEnvironmentalRiskScore(environmentalImpactScore);
        RiskLevel riskLevel = determineRiskLevel(environmentalRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.ENVIRONMENTAL,
            level: riskLevel,
            score: environmentalRiskScore,
            description: "Environmental risk based on impact score"
        });

        emit RiskAssessed(assetAddress, RiskCategory.ENVIRONMENTAL, riskLevel, environmentalRiskScore);
        return result;
    }

    /**
     * @dev Calculate market risk score
     * @param volatility Asset price volatility (0 to 100)
     * @param correlationFactor Correlation with market benchmark (0 to 100)
     * @return Market risk score
     */
    function calculateMarketRiskScore(uint256 volatility, uint256 correlationFactor) 
        private 
        pure 
        returns (uint256) 
    {
        require(volatility <= MAX_PERCENTAGE, "Invalid volatility");
        require(correlationFactor <= MAX_PERCENTAGE, "Invalid correlation factor");
        uint256 volatilityFraction = (volatility * PRECISION) / MAX_PERCENTAGE;
        uint256 correlationFraction = (correlationFactor * PRECISION) / MAX_PERCENTAGE;
        return (volatilityFraction * correlationFraction) / PRECISION;
    }

    /**
     * @dev Calculate credit risk score
     * @param defaultProbability Probability of default (0 to 100)
     * @param recoveryRate Expected recovery rate in case of default (0 to 100)
     * @return Credit risk score
     */
    function calculateCreditRiskScore(uint256 defaultProbability, uint256 recoveryRate) 
        private 
        pure 
        returns (uint256) 
    {
        require(defaultProbability <= MAX_PERCENTAGE, "Invalid default probability");
        require(recoveryRate <= MAX_PERCENTAGE, "Invalid recovery rate");
        uint256 defaultProbabilityFraction = (defaultProbability * PRECISION) / MAX_PERCENTAGE;
        uint256 recoveryRateFraction = (recoveryRate * PRECISION) / MAX_PERCENTAGE;
        return (defaultProbabilityFraction * (PRECISION - recoveryRateFraction)) / PRECISION;
    }

    /**
     * @dev Calculate liquidity risk score
     * @param liquidityRatio Liquidity ratio of the asset (0 to 100)
     * @return Liquidity risk score
     */
    function calculateLiquidityRiskScore(uint256 liquidityRatio) 
        private 
        pure 
        returns (uint256) 
    {
        require(liquidityRatio <= MAX_PERCENTAGE, "Invalid liquidity ratio");
        uint256 liquidityFraction = (liquidityRatio * PRECISION) / MAX_PERCENTAGE;
        return PRECISION - liquidityFraction;
    }

    /**
     * @dev Calculate operational risk score
     * @param operationalErrorRate Rate of operational errors (0 to 100)
     * @return Operational risk score
     */
    function calculateOperationalRiskScore(uint256 operationalErrorRate) 
        private 
        pure 
        returns (uint256) 
    {
        require(operationalErrorRate <= MAX_PERCENTAGE, "Invalid operational error rate");
        uint256 errorRateFraction = (operationalErrorRate * PRECISION) / MAX_PERCENTAGE;
        return errorRateFraction * 2;
    }

    /**
     * @dev Calculate legal risk score
     * @param legalComplianceScore Legal compliance score (0 to 100)
     * @return Legal risk score
     */
    function calculateLegalRiskScore(uint256 legalComplianceScore) 
        private 
        pure 
        returns (uint256) 
    {
        require(legalComplianceScore <= MAX_PERCENTAGE, "Invalid legal compliance score");
        uint256 complianceFraction = (legalComplianceScore * PRECISION) / MAX_PERCENTAGE;
        return PRECISION - complianceFraction;
    }

    /**
     * @dev Calculate environmental risk score
     * @param environmentalImpactScore Environmental impact score (0 to 100)
     * @return Environmental risk score
     */
    function calculateEnvironmentalRiskScore(uint256 environmentalImpactScore) 
        private 
        pure 
        returns (uint256) 
    {
        require(environmentalImpactScore <= MAX_PERCENTAGE, "Invalid environmental impact score");
        uint256 impactFraction = (environmentalImpactScore * PRECISION) / MAX_PERCENTAGE;
        return (impactFraction * 3) / 2;
    }

    /**
     * @dev Determine risk level based on risk score
     * @param riskScore Calculated risk score
     * @return RiskLevel enum value
     */
    function determineRiskLevel(uint256 riskScore) 
        private 
        pure 
        returns (RiskLevel) 
    {
        if (riskScore < RISK_THRESHOLD_LOW) {
            return RiskLevel.LOW;
        } else if (riskScore < RISK_THRESHOLD_MEDIUM) {
            return RiskLevel.MEDIUM;
        } else if (riskScore < RISK_THRESHOLD_HIGH) {
            return RiskLevel.HIGH;
        } else {
            return RiskLevel.CRITICAL;
        }
    }
}
