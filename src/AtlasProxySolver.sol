// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "solady/utils/ReentrancyGuard.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SolverBase } from "../lib/atlas/src/contracts/solver/SolverBase.sol";

/**
 * @title ProxySolver
 * @notice An example solver contract that proxies calls to an external contract.
 * @dev This contract inherits from SolverBase and includes reentrancy guards.
 * It allows the owner to set an external contract to which MEV solution calls are proxied.
 * It includes helper functions to manage the external contract and approved EOAs.
 */
contract AtlasProxySolver is SolverBase, Ownable, ReentrancyGuard {
    address payable private searcherContract;
    mapping(address => bool) internal approvedEOAs;

    constructor(
        address weth,
        address atlas,
        address _searcherContract
    )
        SolverBase(weth, atlas, msg.sender)
        Ownable(msg.sender)
    {
        searcherContract = payable(_searcherContract);
    }

    fallback() external payable { }
    receive() external payable { }

    /**
     * @notice Called during the SolverOperation phase.
     * This function is called via atlasSolverCall(), which forwards the solverOpData calldata.
     * @param _searcherCallData The calldata to be forwarded to the external searcher contract.
     */
    function solve(bytes calldata _searcherCallData) public onlySelf nonReentrant {
        // Call the external searcher contract with the provided calldata.
        (bool success, bytes memory returnedData) = searcherContract.call(_searcherCallData);

        // Revert if the call was unsuccessful.
        require(success, "Searcher call unsuccessful");

        // SolverBase automatically handles paying the bid amount to the Execution Environment.
    }

    // ---------------------------------------------------- //
    //                      ONLY OWNER                      //
    // ---------------------------------------------------- //

    /**
     * @notice Sets the address of the external searcher contract.
     * @param _searcherContract The address of the new searcher contract.
     */
    function setSearcherContractAddress(address _searcherContract) public onlyOwner {
        searcherContract = payable(_searcherContract);
    }

    /**
     * @notice Withdraws all ETH from the contract to a recipient address.
     * @param recipient The address to receive the withdrawn ETH.
     */
    function withdrawETH(address recipient) public onlyOwner {
        SafeTransferLib.safeTransferETH(recipient, address(this).balance);
    }

    /**
     * @notice Withdraws all ERC20 tokens of a specific type from the contract to a recipient address.
     * @param token The address of the ERC20 token contract.
     * @param recipient The address to receive the withdrawn tokens.
     */
    function withdrawERC20(address token, address recipient) public onlyOwner {
        SafeTransferLib.safeTransfer(token, recipient, IERC20(token).balanceOf(address(this)));
    }

    // ---------------------------------------------------- //
    //                      MODIFIERS                       //
    // ---------------------------------------------------- //

    /**
     * @notice Ensures a function can only be called through atlasSolverCall,
     * which includes security checks to work safely with Atlas.
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "Not called via atlasSolverCall");
        _;
    }
}
