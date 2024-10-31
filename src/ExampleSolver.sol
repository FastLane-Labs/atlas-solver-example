// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SolverBase } from "../lib/atlas/src/contracts/solver/SolverBase.sol";

/**
 * @title ExampleSolver
 * @notice A simple example solver contract that inherits from SolverBase
 * @dev SolverBase is a helper contract that:
 * 1. Implements ISolverContract interface required for all solvers
 * 2. Handles bid payments to Atlas through the payBids modifier
 * 3. Provides security checks via safetyFirst modifier to ensure:
 *    - Only Atlas can call atlasSolverCall
 *    - Only the owner can initiate solver operations
 *    - Proper reconciliation of funds with Atlas escrow
 * 4. Manages WETH/ETH conversions as needed for bid payments
 */
contract ExampleSolver is SolverBase, Ownable {
    bool internal s_shouldSucceed;

    constructor(address weth, address atlas) SolverBase(weth, atlas, msg.sender) Ownable(msg.sender) {
        s_shouldSucceed = true; // should succeed by default, can be set to false
    }

    fallback() external payable { }
    receive() external payable { }

    // Called during the SolverOperation phase
    // This function is called by atlasSolverCall() which forwards the solverOpData calldata
    // by doing: address(this).call{value: msg.value}(solverOpData)
    // where solverOpData contains the ABI-encoded call to solve()
    function solve() public view onlySelf {
        // This is a test-related function and should be removed in any real solver contracts
        require(s_shouldSucceed, "Solver failed intentionally");
        // SolverBase automatically handles paying the bid amount to the Execution Environment through
        // the payBids modifier, as long as this contract has sufficient balance (ETH or WETH)
    }

    // ---------------------------------------------------- //
    //                      ONLY OWNER                      //
    // ---------------------------------------------------- //

    /// @notice This is a purely test-related function and should be removed in any real solver contracts
    function setShouldSucceed(bool succeed) public onlyOwner {
        s_shouldSucceed = succeed;
    }

    function withdrawETH(address recipient) public onlyOwner {
        SafeTransferLib.safeTransferETH(recipient, address(this).balance);
    }

    function withdrawERC20(address token, address recipient) public onlyOwner {
        SafeTransferLib.safeTransfer(token, recipient, IERC20(token).balanceOf(address(this)));
    }

    // ---------------------------------------------------- //
    //                   VIEW FUNCTIONS                     //
    // ---------------------------------------------------- //

    function shouldSucceed() public view returns (bool) {
        return s_shouldSucceed;
    }

    // ---------------------------------------------------- //
    //                      MODIFIERS                       //
    // ---------------------------------------------------- //

    // This ensures a function can only be called through atlasSolverCall
    // which includes security checks to work safely with Atlas
    modifier onlySelf() {
        require(msg.sender == address(this), "Not called via atlasSolverCall");
        _;
    }
}
