// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract CustomDispatcherTest is Test {
    address public customDispatcher;

    function setUp() public {
        customDispatcher = HuffDeployer.deploy("CustomDispatcher");
    }

    function testCanReachTheFirstFunction() public {
        // first function is at offset 2 of 32 bytes
        // so we need to shift right by 32 -2 = 30 bytes = 240 bits = 0xF0
        bytes memory data = abi.encodePacked(
            uint256(0xf0000000000000000000000000000000000000000000000000000000)
        );

        (bool success, bytes memory testResult) = customDispatcher.call(data);

        assertEq(success, true);
        assertEq(testResult, "Hello, world");
    }
}
