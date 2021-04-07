// SPDX-License-Identifier: MIT
// heavily inspired by WETH10: https://github.com/WETH10/WETH10/blob/main/contracts/interfaces/IWETH10.sol

pragma solidity ^0.8.0;

import "./erc/IERC20.sol";
import "./erc/IERC2612.sol";
import "./erc/IERC3156FlashLender.sol";

import "./IETFRebalancer.sol";
import "./IETFRebalanceValidator.sol";

/// @title IETF
/// @author _
/// @notice IETF (Interface for an ERC-20 Tokenized Fund) is a non-custodial, rebalancing fund of ERC-20 tokens.
/// It is itself an ERC-20 compatible token with `IERC3156FlashLender` flashMinting capabilities.
/// Anyone can mint new ETF tokens by depositing some multiple of the underlying allocation.
/// Anyone can redeem their ETF tokens for equivalent units of the underlying allocation.
/// Anyone can rebalance the ETF, via a batchFlashLoan-like operation, provided certain conditions are met.
/// Primarily, for the rebalance to succeed, the new allocation must be approved by the IETFRebalanceValidator,
/// which is permanently set at the time of ETF creation.
interface IETF is IERC20, IERC2612, IERC3156FlashLender {
    /// @notice Emitted when the ETF is successfully rebalanced
    /// @param initiator The address which initiated the rebalance call
    /// @param rebalancer The address which handled the swapping of the underlying tokens
    /// @param prevTokens The token component of the allocation prior to the rebalance
    /// @param prevAmounts The amount component of the allocation prior to the rebalance
    /// @param newTokens The token component of the allocation after the rebalance
    /// @param newAmounts The amount component of the allocation after the rebalance
    event ETFRebalanced(
        address indexed initiator,
        IETFRebalancer indexed rebalancer,
        IERC20[] prevTokens,
        uint256[] prevAmounts,
        IERC20[] newTokens,
        uint256[] newAmounts
    );

    /// @notice Returns the address which created this ETF.
    /// @dev This value is immutable, assigned at ETF creation.
    /// @return The address which created this ETF.
    function launcher() external view returns (address);

    /// @notice Returns the address of the IETFRebalanceValidator assigned to this ETF.
    /// @dev This value is immutable, assigned at ETF creation.
    /// @return The address of the IETFRebalanceValidator assigned to this ETF.
    function validator() external view returns (IETFRebalanceValidator);

    /// @notice Returns the current set of tokens in the allocation.
    /// @dev This value may change when the ETF is rebalanced.
    /// The length of `tokens()` must match the length of `amounts()`
    /// The returned values are sorted.
    /// @return The current set of tokens in the allocation.
    function tokens() external view returns (IERC20[] memory);

    /// @notice Returns the current amounts in the allocation.
    /// `amounts()` and `tokens()` together specify the ETF allocation at any given time.
    /// @dev These are specified in terms of the underlying token's native scale.
    /// This value may change when the ETF is rebalanced.
    /// @return The current amounts of each token in the allocation.
    function amounts() external view returns (uint256[] memory);

    /// @notice Depositing `value` units of the underlying allocation, grants caller `value` ETF tokens.
    /// @dev Emits {Transfer} event to reflect mint of `value` from `address(0)` to caller account.
    /// Requirements:
    ///     - caller must have allowed this ETF to transfer at least `value` units of the underlying allocation.
    ///     - `0 < value`
    /// @param value The number of tokens to create.
    /// @return success Flag indicating whether the operation succeeded.
    function create(uint256 value) external returns (bool success);

    /// @notice Depositing `value` units of the underlying allocation, grants `to` address `value` ETF tokens.
    /// @dev Emits {Transfer} event to reflect ETF mint of `value` from `address(0)` to `to` account.
    /// Requirements:
    ///     - same as `create`
    /// @param to The recipient of the created tokens.
    /// @param value The number of tokens to create.
    /// @return success Flag indicating whether the operation succeeded.
    function createTo(address to, uint256 value)
        external
        returns (bool success);

    /// @notice Redeem `value` ETF from caller account for `value` units of underlying allocation to the same.
    /// @dev Emits {Transfer} event to reflect ETF burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of ETF.
    ///   - `0 < value`
    /// @param value is the number of tokens to redeem.
    /// @return success Flag indicating whether the operation succeeded.
    function redeem(uint256 value) external returns (bool success);

    /// @notice Redeem `value` ETF from caller account for `value` units of underlying allocation to account (`to`).
    /// @dev Emits {Transfer} event to reflect ETF burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - same as `redeem`
    /// @param to is the recipient of the redeemed underlying tokens.
    /// @param value is the number of tokens to redeem.
    /// @return success Flag indicating whether the operation succeeded.
    function redeemTo(address to, uint256 value)
        external
        returns (bool success);

    /// @notice Redeem `value` ETF from account (`from`) for `value` units of underlying allocation to account (`to`).
    /// @dev Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect ETF token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of ETF.
    ///   - `from` account must have approved caller to spend at least `value` of ETF, unless `from` and caller are the same account.
    ///   - caller account must have at least `value` balance of ETF.
    ///   - `0 < value`
    /// @param from The account from which the ETF will be redeemed.
    /// @param to The recipient of the redeemed underlying tokens.
    /// @param value The number of tokens to redeem.
    /// @return success Flag indicating whether the operation succeeded.
    function redeemFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice Trigger a rebalance of the ETF such that `newTokens` and `newAmounts` are the new allocation.
    /// This will trigger a batchFlashLoan-like operation to the `rebalancer` for `supply()` units of the current underlying allocation.
    /// Repayment of the loan will be `supply()` units of the new underlying allocation.
    /// @dev Emits {Rebalance} event to reflect change from previous allocation to new allocation.
    /// Requirements:
    ///     - The ETF `validator()` must return `true` for `IETFRebalanceValidator.validateRebalance(rebalancer, newTokens, newAmounts, bytes)`
    ///     - `newTokens` and `newAmounts` must be a statically valid allocation (equal lengths, tokens sorted, no repeats, no recursive ETFs, etc.)
    ///     - The `rebalancer` must return true from `IETFRebalancer.onRebalance(msg.sender, newTokens, newAmounts, data)`
    ///     - The `rebalancer` must allow the ETF to transfer `supply()` units of the new underlying allocation.
    /// @param rebalancer The recipient of the batchFlashLoan-like operation and provider of `supply()` units of the new allocation.
    /// @param newTokens The new tokens component of the the underlying allocation.
    /// @param newAmounts The new amounts component of the underlying allocation.
    /// @param data Any data to be passed through to the callback
    /// @return success Flag indicating whether the operation succeeded.
    function rebalance(
        IETFRebalancer rebalancer,
        IERC20[] calldata newTokens,
        uint256[] calldata newAmounts,
        bytes calldata data
    ) external returns (bool success);

    /// @notice Depositing `value` units of the underlying allocation, grants `to` address `value` ETF tokens and triggers a callback.
    /// @dev `value` of ETH sent to this contract grants `to` account a matching increase in ETF token balance,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    /// Requirements:
    ///     - same as `createTo`
    ///     - `to` must be an ERC677Receiver-compliant contract
    /// @param to The recipient of the created tokens.
    /// @param value The number of tokens to create.
    /// @param data Any data to be passed through to the callback
    /// @return success Flag indicating whether the operation succeeded.
    function createToAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    /// @notice Depositing `value` units of the underlying allocation, grants `to` address `value` ETF tokens and triggers a callback.
    /// @dev Sets `value` as allowance of `spender` account over caller account's ETF token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns bool successean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    /// @param spender The recipient of the approved tokens.
    /// @param value The number of tokens to approve.
    /// @param data Any data to be passed through to the callback
    /// @return success Flag indicating whether the operation succeeded.
    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    /// @notice Depositing `value` units of the underlying allocation, grants `to` address `value` ETF tokens and triggers a callback.
    /// @dev Moves `value` ETF token from caller's account to account (`to`),
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers a redemption matching the sent ETF token in favor of caller.
    /// Emits {Transfer} event.
    /// Requirements:
    ///   - caller account must have at least `value` ETF token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    /// @param to The recipient of the created tokens.
    /// @param value The number of tokens to create.
    /// @param data Any data to be passed through to the callback
    /// @return success Flag indicating whether the operation succeeded.
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);
}
