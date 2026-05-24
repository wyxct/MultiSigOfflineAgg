// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

library AddressUtils {

    function isZeroAddress(address addr) internal pure returns (bool) {
        return addr == address(0);
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success,) = to.call{value: amount}("");
        require(success, "AddressUtils: ETH transfer failed");
    }
}