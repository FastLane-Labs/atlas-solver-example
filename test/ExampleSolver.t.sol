// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { ExampleSolver } from "../src/ExampleSolver.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract ExampleSolverTest is Test {
    ExampleSolver public solver;
    address public constant WETH = address(0x1);
    address public constant ATLAS = address(0x2);
    address public owner;
    address public user;
    MockERC20 public testToken;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");

        vm.startPrank(owner);
        solver = new ExampleSolver(WETH, ATLAS);
        testToken = new MockERC20("Test Token", "TEST");
        vm.stopPrank();

        // Fund the solver with some ETH
        vm.deal(address(solver), 100 ether);
        // Fund the solver with some test tokens
        testToken.mint(address(solver), 1000e18);
    }

    function test_InitialState() public view {
        assertEq(solver.owner(), owner);
        assertTrue(solver.shouldSucceed());
        assertEq(address(solver).balance, 100 ether);
        assertEq(testToken.balanceOf(address(solver)), 1000e18);
    }

    function test_SetShouldSucceed() public {
        vm.prank(owner);
        solver.setShouldSucceed(false);
        assertFalse(solver.shouldSucceed());
    }

    function test_RevertWhen_NonOwnerSetsShouldSucceed() public {
        vm.prank(user);
        bytes memory expectedError = abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user);
        vm.expectRevert(expectedError);
        solver.setShouldSucceed(false);
    }

    function test_WithdrawETH() public {
        uint256 initialBalance = owner.balance;

        vm.prank(owner);
        solver.withdrawETH(owner);

        assertEq(address(solver).balance, 0);
        assertEq(owner.balance, initialBalance + 100 ether);
    }

    function test_RevertWhen_NonOwnerWithdrawsETH() public {
        vm.prank(user);
        bytes memory expectedError = abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user);
        vm.expectRevert(expectedError);
        solver.withdrawETH(user);
    }

    function test_WithdrawERC20() public {
        vm.prank(owner);
        solver.withdrawERC20(address(testToken), owner);

        assertEq(testToken.balanceOf(address(solver)), 0);
        assertEq(testToken.balanceOf(owner), 1000e18);
    }

    function test_RevertWhen_NonOwnerWithdrawsERC20() public {
        vm.prank(user);
        bytes memory expectedError = abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user);
        vm.expectRevert(expectedError);
        solver.withdrawERC20(address(testToken), user);
    }

    function test_RevertWhen_DirectSolveCall() public {
        vm.expectRevert("Not called via atlasSolverCall");
        solver.solve();
    }

    function test_ReceiveETH() public {
        (bool success,) = address(solver).call{ value: 1 ether }("");
        assertTrue(success);
        assertEq(address(solver).balance, 101 ether);
    }
}
