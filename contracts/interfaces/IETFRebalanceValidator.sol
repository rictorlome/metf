// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./erc/IERC20.sol";

import "./IETF.sol";
import "./IETFRebalancer.sol";

/// @title IETFRebalanceValidator
/// @author _
/// @notice Each IETF is constructed with an immutable reference to an IETFRebalanceValidator.
/// The IETFRebalanceValidator has hooks to validate the IETF at launch and at rebalance.
interface IETFRebalanceValidator {
    /// @notice IETF will call this method in its constructor, providing the IETFRebalanceValidator an
    /// opportunity to prevent ETF creation altogether.
    /// @dev `validateRebalance` can revert or return False on failure, but it MUST return True on success.
    /// @param launcher The `msg.sender` of the constructor of the corresponding ETF.
    /// @param initTokens The tokens component of the initial ETF allocation.
    /// @param initAmounts The amounts component of the initial ETF allocation.
    /// @return success Flag indicating whether the operation succeeded.
    function validateLaunch(
        address launcher,
        IERC20[] calldata initTokens,
        uint256[] calldata initAmounts
    ) external returns (bool success);

    /// @notice IETF will call this method on every rebalance prior to releasing funds to the `rebalancer`.
    /// @dev `validateRebalance` can revert or return False on failure, but it MUST return True on success.
    /// @param initiator The address which invoked `rebalance` on the ETF.
    /// @param rebalancer The address designated as the `rebalancer` on the call to `rebalance` on the ETF.
    /// @param newTokens The tokens component of the proposed new allocation.
    /// @param newAmounts The amounts component of the proposed new allocation.
    /// @param data The `data` passed in as `data` on the call to `rebalance` on the ETF.
    /// @return success Flag indicating whether the operation succeeded.
    function validateRebalance(
        address initiator,
        IETFRebalancer rebalancer,
        IERC20[] calldata newTokens,
        uint256[] calldata newAmounts,
        bytes calldata data
    ) external returns (bool success);
}
