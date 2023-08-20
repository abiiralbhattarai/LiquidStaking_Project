// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

import {ERC20PermitPermissionedMint} from "./ERC20/ERC20PermitPermissionedMint.sol";

contract bmxETH is ERC20PermitPermissionedMint {
    /* ========== CONSTRUCTOR ========== */
    constructor(
        address _creator_address,
        address _timelock_address
    )
        ERC20PermitPermissionedMint(
            _creator_address,
            _timelock_address,
            "BMX Ether",
            "bmxETH"
        )
    {}
}
