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

    function testCanReachFunction1() public {
        // first function is at jumptable offset 2 of 32 bytes
        // so we need to shift right by 32 - 2 = 30 bytes = 240 bits = 0xF0
        bytes memory data = abi.encodePacked(
            uint256(
                0xf000000000000000000000000000000000000000000000000000000000000000
            )
        );

        (bool success, bytes memory testResult) = customDispatcher.call(data);

        assertEq(success, true);
        assertEq(testResult, abi.encode("hello from function 1"));
    }

    function testCanReachFunction2() public {
        // second function is at jumptable offset 4 of 32 bytes
        // so we need to shift right by 32 - 4 = 28 bytes = 224 bits = 0xE0
        bytes memory data = abi.encodePacked(
            uint256(
                0xe000000000000000000000000000000000000000000000000000000000000000
            )
        );

        (bool success, bytes memory testResult) = customDispatcher.call(data);

        assertEq(success, true);
        assertEq(testResult, abi.encode("hello from function 2"));
    }
}
