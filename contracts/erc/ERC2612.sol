// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC20.sol';
import '../interfaces/erc/IERC2612.sol';

abstract contract ERC2612 is ERC20, IERC2612 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
    mapping(address => uint256) public override nonces;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(block.timestamp <= deadline, 'Expired');
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Invalid signature');
        _approve(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                    keccak256(bytes(name)),
                    keccak256(bytes('1')),
                    // block.chainid,
                    1,
                    address(this)
                )
            );
    }
}
