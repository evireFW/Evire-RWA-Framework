// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Utilities
 * @dev A library of utility functions for the Evire-RWA-Framework
 */
library Utilities {
    using SafeMath for uint256;

    /**
     * @dev Calculates the percentage of a value
     * @param value The total value
     * @param percentage The percentage to calculate
     * @return The calculated percentage of the value
     */
    function calculatePercentage(uint256 value, uint256 percentage) internal pure returns (uint256) {
        require(percentage <= 100, "Percentage must be between 0 and 100");
        return value.mul(percentage).div(100);
    }

    /**
     * @dev Converts a uint256 to a string
     * @param value The uint256 value to convert
     * @return The string representation of the value
     */
    function uintToString(uint256 value) internal pure returns (string memory) {
        return Strings.toString(value);
    }

    /**
     * @dev Checks if two strings are equal
     * @param a The first string
     * @param b The second string
     * @return True if the strings are equal, false otherwise
     */
    function stringEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /**
     * @dev Calculates the average of an array of uint256 values
     * @param values The array of values
     * @return The average of the values
     */
    function calculateAverage(uint256[] memory values) internal pure returns (uint256) {
        require(values.length > 0, "Array must not be empty");
        uint256 sum = 0;
        for (uint256 i = 0; i < values.length; i++) {
            sum = sum.add(values[i]);
        }
        return sum.div(values.length);
    }

    /**
     * @dev Finds the maximum value in an array of uint256 values
     * @param values The array of values
     * @return The maximum value in the array
     */
    function findMaxValue(uint256[] memory values) internal pure returns (uint256) {
        require(values.length > 0, "Array must not be empty");
        uint256 maxValue = values[0];
        for (uint256 i = 1; i < values.length; i++) {
            if (values[i] > maxValue) {
                maxValue = values[i];
            }
        }
        return maxValue;
    }

    /**
     * @dev Checks if an address is a contract
     * @param addr The address to check
     * @return True if the address is a contract, false if it's an externally owned account
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @dev Converts a bytes32 to a string
     * @param data The bytes32 data to convert
     * @return The string representation of the bytes32 data
     */
    function bytes32ToString(bytes32 data) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytes1 char = bytes1(bytes32(uint256(data) * 2 ** (8 * i)));
            if (char != 0) {
                bytesString[i] = char;
            }
        }
        return string(bytesString);
    }
}