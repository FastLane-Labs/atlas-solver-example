// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { ExampleSolver } from "../src/ExampleSolver.sol";

contract DeployScript is Script {
    // Default addresses - should be overridden with actual addresses for different networks
    address public constant WMATIC = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); // Polygon WMATIC
    address public constant ATLAS = address(0); // Replace with actual Atlas address

    function setUp() public { }

    function run() public {
        // Get deployer address for logging
        address deployer = msg.sender;
        console.log("Deploying from:", deployer);

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy ExampleSolver
        ExampleSolver solver = new ExampleSolver(
            WMATIC, // Using WMATIC instead of WETH for Polygon
            ATLAS
        );

        console.log("ExampleSolver deployed at:", address(solver));

        vm.stopBroadcast();
    }
}
