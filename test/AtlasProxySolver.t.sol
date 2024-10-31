// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { AtlasProxySolver } from "../src/AtlasProxySolver.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MockSearcherContract {
    bool public shouldRevert;

    function setShouldRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    fallback() external payable {
        if (shouldRevert) {
            revert("Searcher call unsuccessful");
        }
    }

    receive() external payable { }
}

contract AtlasProxySolverTest is Test {
    AtlasProxySolver public solver;
    MockSearcherContract public searcherContract;
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
        searcherContract = new MockSearcherContract();
        solver = new AtlasProxySolver(WETH, ATLAS, address(searcherContract));
        testToken = new MockERC20("Test Token", "TEST");
        vm.stopPrank();

        // Fund the solver with some ETH
        vm.deal(address(solver), 100 ether);
        // Fund the solver with some test tokens
        testToken.mint(address(solver), 1000e18);
    }

    function test_InitialState() public view {
        assertEq(solver.owner(), owner);
        assertEq(address(solver).balance, 100 ether);
        assertEq(testToken.balanceOf(address(solver)), 1000e18);
    }

    function test_SetSearcherContractAddress() public {
        // Create a new mock searcher contract
        MockSearcherContract newSearcherContract = new MockSearcherContract();
        
        // Set it to revert to verify it's actually being called
        newSearcherContract.setShouldRevert(true);

        // Set the new searcher contract
        vm.prank(owner);
        solver.setSearcherContractAddress(address(newSearcherContract));

        // Verify the change by checking if a call reverts with the correct error
        bytes memory testCalldata = hex"1234";
        vm.prank(address(solver));
        vm.expectRevert("Searcher call unsuccessful");
        solver.solve(testCalldata);
    }

    function test_RevertWhen_NonOwnerSetsSearcherContract() public {
        address newSearcherContract = makeAddr("newSearcher");

        vm.prank(user);
        bytes memory expectedError = abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user);
        vm.expectRevert(expectedError);
        solver.setSearcherContractAddress(newSearcherContract);
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
        bytes memory testCalldata = hex"1234";
        vm.expectRevert("Not called via atlasSolverCall");
        solver.solve(testCalldata);
    }

    function test_SolveWithSearcherSuccess() public {
        bytes memory testCalldata = hex"1234";
        searcherContract.setShouldRevert(false);

        vm.prank(address(solver));
        solver.solve(testCalldata);
    }

    function test_RevertWhen_SearcherContractReverts() public {
        bytes memory testCalldata = hex"1234";
        searcherContract.setShouldRevert(true);

        vm.prank(address(solver));
        vm.expectRevert("Searcher call unsuccessful");
        solver.solve(testCalldata);
    }

    function test_ReceiveETH() public {
        (bool success,) = address(solver).call{ value: 1 ether }("");
        assertTrue(success);
        assertEq(address(solver).balance, 101 ether);
    }
}