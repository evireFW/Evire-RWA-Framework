// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title DataVerification
 * @dev Library for verifying and validating various types of data related to Real World Assets (RWA)
 */
library DataVerification {
    // Custom errors
    error InvalidDataFormat();
    error DataOutOfRange();
    error InconsistentData();
    error UnauthorizedSource();

    // Struct to hold verification parameters
    struct VerificationParams {
        uint256 minValue;
        uint256 maxValue;
        uint8 decimalPlaces;
        bool allowNegative;
        address[] authorizedSources;
    }

    /**
     * @dev Verifies a numeric value against specified parameters
     * @param value The value to verify
     * @param params The verification parameters
     * @return bool True if the value is valid, false otherwise
     */
    function verifyNumericValue(int256 value, VerificationParams memory params) public pure returns (bool) {
        if (!params.allowNegative && value < 0) {
            return false;
        }

        uint256 absValue = value < 0 ? uint256(-value) : uint256(value);

        if (absValue < params.minValue || absValue > params.maxValue) {
            return false;
        }

        // Optionally implement decimalPlaces check if applicable

        return true;
    }

    /**
     * @dev Verifies a string value against a regular expression pattern
     * @param value The string to verify
     * @param pattern The regular expression pattern
     * @return bool True if the value matches the pattern, false otherwise
     */
    function verifyStringPattern(string memory value, string memory pattern) public pure returns (bool) {
        // Note: Solidity doesn't support regex directly. This is a placeholder for off-chain verification.
        // In a real implementation, this would be done off-chain or using a specialized oracle.
        return bytes(value).length > 0 && bytes(pattern).length > 0;
    }

    /**
     * @dev Verifies the integrity of a hash
     * @param data The original data
     * @param hash The hash to verify
     * @return bool True if the hash is valid, false otherwise
     */
    function verifyDataIntegrity(bytes memory data, bytes32 hash) public pure returns (bool) {
        return keccak256(data) == hash;
    }

    /**
     * @dev Verifies that a timestamp is within an acceptable range
     * @param timestamp The timestamp to verify
     * @param maxAge The maximum age of the timestamp in seconds
     * @return bool True if the timestamp is valid, false otherwise
     */
    function verifyTimestamp(uint256 timestamp, uint256 maxAge) public view returns (bool) {
        if (timestamp > block.timestamp) {
            return false;
        }
        if (block.timestamp - timestamp > maxAge) {
            return false;
        }
        return true;
    }

    /**
     * @dev Verifies that a data source is authorized
     * @param source The address of the data source
     * @param params The verification parameters containing authorized sources
     * @return bool True if the source is authorized, false otherwise
     */
    function verifyDataSource(address source, VerificationParams memory params) public pure returns (bool) {
        for (uint256 i = 0; i < params.authorizedSources.length; i++) {
            if (params.authorizedSources[i] == source) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Verifies a set of geographic coordinates
     * @param latitude The latitude value (-90 to 90)
     * @param longitude The longitude value (-180 to 180)
     * @return bool True if the coordinates are valid, false otherwise
     */
    function verifyGeographicCoordinates(int256 latitude, int256 longitude) public pure returns (bool) {
        if (latitude < -90 || latitude > 90) {
            return false;
        }
        if (longitude < -180 || longitude > 180) {
            return false;
        }
        return true;
    }

    /**
     * @dev Verifies a UUID (Universally Unique Identifier)
     * @param uuid The UUID to verify
     * @return bool True if the UUID is valid, false otherwise
     */
    function verifyUUID(bytes16 uuid) public pure returns (bool) {
        // Check if the UUID is not zero
        if (uuid == 0) {
            return false;
        }

        // Verify version (should be 4 for random UUID)
        uint8 version = uint8(uint8(uuid[6]) >> 4);
        if (version != 4) {
            return false;
        }

        // Verify variant (should be 1)
        uint8 variant = uint8(uint8(uuid[8]) >> 6);
        if (variant != 2) {
            return false;
        }

        return true;
    }

    /**
     * @dev Verifies the format of an ISO8601 date string and checks for valid ranges
     * @param dateString The date string to verify
     * @return bool True if the date string is valid, false otherwise
     */
    function verifyISO8601Date(string memory dateString) public pure returns (bool) {
        bytes memory dateBytes = bytes(dateString);
        
        // Basic length check
        if (dateBytes.length != 10) {
            return false;
        }

        // Check format (YYYY-MM-DD)
        for (uint i = 0; i < 10; i++) {
            if (i == 4 || i == 7) {
                if (dateBytes[i] != '-') {
                    return false;
                }
            } else {
                if (dateBytes[i] < '0' || dateBytes[i] > '9') {
                    return false;
                }
            }
        }

        // Parse year, month, and day
        uint16 year = uint16((uint8(dateBytes[0]) - 48) * 1000 + (uint8(dateBytes[1]) - 48) * 100 + (uint8(dateBytes[2]) - 48) * 10 + (uint8(dateBytes[3]) - 48));
        uint8 month = uint8((uint8(dateBytes[5]) - 48) * 10 + (uint8(dateBytes[6]) - 48));
        uint8 day = uint8((uint8(dateBytes[8]) - 48) * 10 + (uint8(dateBytes[9]) - 48));

        // Check valid month
        if (month == 0 || month > 12) {
            return false;
        }

        // Days in months
        uint8[12] memory daysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31];

        // Check for leap year in February
        if (month == 2 && ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))) {
            if (day == 0 || day > 29) {
                return false;
            }
        } else {
            if (day == 0 || day > daysInMonth[month - 1]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Verifies a digital signature
     * @param message The original message hash
     * @param signature The signature to verify
     * @param signer The address of the supposed signer
     * @return bool True if the signature is valid, false otherwise
     */
    function verifySignature(bytes32 message, bytes memory signature, address signer) public pure returns (bool) {
        address recoveredAddress = ECDSA.recover(message, signature);
        return recoveredAddress == signer;
    }

    /**
     * @dev Batch verification of multiple data points
     * @param values Array of values to verify
     * @param params Array of corresponding verification parameters
     * @return bool True if all values are valid, false otherwise
     */
    function batchVerifyNumericValues(int256[] memory values, VerificationParams[] memory params) public pure returns (bool) {
        if (values.length != params.length) {
            return false;
        }

        for (uint256 i = 0; i < values.length; i++) {
            if (!verifyNumericValue(values[i], params[i])) {
                return false;
            }
        }

        return true;
    }
}
