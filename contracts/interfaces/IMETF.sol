// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './erc/IERC20.sol';

import './IETF.sol';
import './IETFRebalanceValidator.sol';

/// @title IMETF
/// @author _
/// @notice The IMETF is responsible for launching and tracking ETFs.
interface IMETF {
    /// @notice Emitted when the owner of the factory is changed
    /// @param etf The address of the newly launched ETF
    /// @param name The name of the newly launched ETF
    /// @param symbol The symbol of the newly launched ETF
    /// @param validator The validator assigned to the newly launched ETF
    /// @param tokens The tokens component of the initial underlying allocation
    /// @param amounts The amounts component of the initial underlying allocation
    event ETFLaunched(
        IETF indexed etf,
        string name,
        string symbol,
        IERC20[] tokens,
        uint256[] amounts,
        IETFRebalanceValidator indexed validator
    );
    /// @notice Emitted when the owner of the IMETF is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Launches a new ETF
    /// @param name The name of the new ETF
    /// @param symbol The symbol of the new ETF
    /// @param initTokens The tokens component of the initial underlying allocation
    /// @param initAmounts The amounts component of the initial underlying allocation
    /// @param validator The permanent validator assigned to the new ETF
    /// @return etf The address of the newly launched ETF
    function launchETF(
        string calldata name,
        string calldata symbol,
        IERC20[] calldata initTokens,
        uint256[] calldata initAmounts,
        IETFRebalanceValidator validator
    ) external returns (IETF etf);

    /// @notice Returns a list of the ETFs launched by this IMETF
    /// @return etfs A list of the ETFs launched by this IMETF
    function getETFs() external view returns (IETF[] calldata etfs);
}
