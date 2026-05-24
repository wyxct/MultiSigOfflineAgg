// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

library MathUtils {

    function isNonZero(uint amount) internal pure returns (bool) {
        return amount > 0;
    }
}