// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC/IERC20.sol";

/// @title IMETF
/// @author _
/// @notice Calls to IETF.rebalance must specify an IETFRebalancer capable of handling the rebalance.
/// The IETF does not need to trust the rebalancer, but the Rebalancer needs to trust the IETF.
interface IMETF {
    /// @notice The IETF will transfer its entire holdings to the IETFRebalancer before calling `onRebalance`.
    /// This is a batchFlashLoan for `lendAmounts` of `lendTokens`, which must be repayed with `repayAmounts` of `repayTokens`.
    /// @dev `lendAmounts` and `repayAmounts` are calculated in the `rebalance` method as `totalSupply()` units
    /// of the old and new underlying allocation, respectively.
    /// `validateRebalance` can revert or return False on failure, but it MUST return True on success.
    /// The expectation is that after onRebalance returns `TRUE`, the IETF will be able to transfer
    /// `repayAmounts` of `repayTokens` out of IETFRebalancer.
    /// @param initiator The address which invoked `rebalance` on the IETF.
    /// @param lendTokens The tokens being lent to the IETFRebalancer.
    /// @param lendAmounts The amounts of each of the `lendTokens` being lent to the IETFRebalancer.
    /// NOTE: This is distinct from the amounts component of the previous underlying allocation.
    /// @param repayTokens The tokens which must be repayed to the IETF.
    /// @param repayAmounts The amounts of each of the `repayTokens` which must be repayed to the IETF.
    /// NOTE: This is distinct from the amounts component of the new underlying allocation.
    /// @param data The `data` passed in as `data` on the call to `rebalance` on the IETF.
    /// @return success Flag indicating whether the operation succeeded.
    function onRebalance(
        address initiator,
        IERC20[] calldata lendTokens,
        uint256[] calldata lendAmounts,
        IERC20[] calldata repayTokens,
        uint256[] calldata repayAmounts,
        bytes calldata data
    ) external returns (bool success);
}
