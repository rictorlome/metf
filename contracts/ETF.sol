// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./erc/ERC3156FlashLender.sol";

import "./interfaces/IETF.sol";
import "./interfaces/IETFRebalanceValidator.sol";
import "./interfaces/IETFRebalancer.sol";
import "./interfaces/erc/IERC20.sol";

interface ITransferReceiver {
    function onTokenTransfer(
        address,
        uint256,
        bytes calldata
    ) external returns (bool);
}

interface IApprovalReceiver {
    function onTokenApproval(
        address,
        uint256,
        bytes calldata
    ) external returns (bool);
}

contract ETF is IETF, ERC3156FlashLender {
    IETFRebalanceValidator public immutable override validator;
    address public immutable override launcher;

    IERC20[] private _tokens;
    uint256[] private _amounts;

    constructor(
        string memory _name,
        string memory _symbol,
        IERC20[] memory initTokens,
        uint256[] memory initAmounts,
        IETFRebalanceValidator _validator
    ) ERC3156FlashLender(_name, _symbol) {
        require(
            _validator.validateLaunch(msg.sender, initTokens, initAmounts),
            "ETF launch failed."
        );
        _setAllocation(initTokens, initAmounts);
        validator = _validator;
        launcher = msg.sender;
    }

    function tokens() external view override returns (IERC20[] memory) {
        return _tokens;
    }

    function amounts() external view override returns (uint256[] memory) {
        return _amounts;
    }

    function create(uint256 value) external override returns (bool success) {
        _transferUnderlyingAllocationFrom(msg.sender, address(this), value);
        _mint(msg.sender, value);
        success = true;
    }

    function createTo(address to, uint256 value)
        external
        override
        returns (bool success)
    {
        _transferUnderlyingAllocationFrom(msg.sender, address(this), value);
        _mint(to, value);
        success = true;
    }

    function redeem(uint256 value) external override returns (bool success) {
        _burn(msg.sender, value);
        _transferUnderlyingAllocationFrom(address(this), msg.sender, value);
        success = true;
    }

    function redeemTo(address to, uint256 value)
        external
        override
        returns (bool success)
    {
        _burn(msg.sender, value);
        _transferUnderlyingAllocationFrom(address(this), to, value);
        success = true;
    }

    function redeemFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool success) {
        if (
            from != msg.sender &&
            allowance[from][msg.sender] != type(uint256).max
        ) {
            allowance[from][msg.sender] -= value;
        }
        _burn(from, value);
        _transferUnderlyingAllocationFrom(address(this), to, value);
        success = true;
    }

    function rebalance(
        IETFRebalancer rebalancer,
        IERC20[] calldata newTokens,
        uint256[] calldata newAmounts,
        bytes calldata data
    ) external override returns (bool success) {
        uint256 units = totalSupply;
        IERC20[] memory prevTokens = _tokens;
        uint256[] memory prevAmounts = _amounts;
        require(
            validator.validateRebalance(
                msg.sender,
                rebalancer,
                newTokens,
                newAmounts,
                data
            ),
            "Invalid rebalance."
        );
        _transferUnderlyingAllocationFrom(
            address(this),
            address(rebalancer),
            units
        );
        require(
            rebalancer.onRebalance(
                msg.sender,
                units,
                prevTokens,
                prevAmounts,
                newTokens,
                newAmounts,
                data
            ),
            "Rebalance failed."
        );
        _setAllocation(newTokens, newAmounts);
        _transferUnderlyingAllocationFrom(
            address(rebalancer),
            address(this),
            units
        );
        emit ETFRebalanced(
            msg.sender,
            rebalancer,
            prevTokens,
            prevAmounts,
            newTokens,
            newAmounts
        );
        success = true;
    }

    function createToAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external override returns (bool success) {
        _transferUnderlyingAllocationFrom(msg.sender, address(this), value);
        _mint(to, value);
        return ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
    }

    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external override returns (bool success) {
        _approve(msg.sender, spender, value);
        return
            IApprovalReceiver(spender).onTokenApproval(msg.sender, value, data);
    }

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external override returns (bool success) {
        _transfer(msg.sender, to, value);
        return ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
    }

    function _setAllocation(
        IERC20[] memory newTokens,
        uint256[] memory newAmounts
    ) private {
        _validateAllocation(newTokens, newAmounts);
        _tokens = newTokens;
        _amounts = newAmounts;
    }

    function _validateAllocation(
        IERC20[] memory newTokens,
        uint256[] memory newAmounts
    ) private view {
        require(
            newTokens.length == newAmounts.length,
            "Incomplete specification."
        );
        address prev;
        for (uint256 i = 0; i < newTokens.length; i++) {
            require(
                prev < address(newTokens[i]),
                "Tokens must be sorted, no duplicates."
            );
            require(
                address(this) != address(newTokens[i]),
                "No recursive ETFs."
            );
            prev = address(newTokens[i]);
        }
    }

    function _transferUnderlyingAllocationFrom(
        address from,
        address to,
        uint256 units
    ) private {
        require(0 < units, "Value must be larger than 0.");
        for (uint256 i = 0; i < _tokens.length; i++) {
            _safeTransferFrom(_tokens[i], from, to, _amounts[i] * units);
        }
    }

    function _safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) =
            address(token).call(
                abi.encodeWithSelector(
                    token.transferFrom.selector,
                    from,
                    to,
                    value
                )
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Transfer failed"
        );
    }
}
