// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {ERC20, ERC4626, xERC4626} from "ERC4626/xERC4626.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/// @title Vault token for staked bmxETH
/// @notice Is a vault that takes bmxETH and gives you sbmxETH erc20 tokens
/** @dev Exchange rate between bmxETH and sbmxETH floats, you can convert your sbmxETH for more bmxETH over time.
    Exchange rate increases as the frax msig mints new bmxETH corresponding to the staking yield and drops it into the vault (sbmxETH contract).
    There is a short time period, “cycles” which the exchange rate increases linearly over. This is to prevent gaming the exchange rate (MEV).
    The cycles are constant length, but calling syncRewards slightly into a would-be cycle keeps the same would-be endpoint (so cycle ends are every X seconds).
    Someone must call syncRewards, which queues any new bmxETH in the contract to be added to the redeemable amount.
    sbmxETH adheres to ERC-4626 vault specs 
    Mint vs Deposit
    mint() - deposit targeting a specific number of sbmxETH out
    deposit() - deposit knowing a specific number of bmxETH in */
contract sbmxETH is xERC4626, ReentrancyGuard {
    /* ========== CONSTRUCTOR ========== */
    constructor(
        ERC20 _underlying,
        uint32 _rewardsCycleLength
    )
        ERC4626(_underlying, "Staked Frax Ether", "sbmxETH")
        xERC4626(_rewardsCycleLength)
    {}

    /// @notice Syncs rewards if applicable beforehand. Noop if otherwise
    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        super.beforeWithdraw(assets, shares); // call xERC4626's beforeWithdraw first
        if (block.timestamp >= rewardsCycleEnd) {
            syncRewards();
        }
    }

    /// @notice How much bmxETH is 1E18 sbmxETH worth. Price is in ETH, not USD
    function pricePerShare() public view returns (uint256) {
        return convertToAssets(1e18);
    }

    /// @notice Approve and deposit() in one transaction
    function depositWithSignature(
        uint256 assets,
        address receiver,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant returns (uint256 shares) {
        uint256 amount = approveMax ? type(uint256).max : assets;
        asset.permit(msg.sender, address(this), amount, deadline, v, r, s);
        return (deposit(assets, receiver));
    }

    /// @notice Approve and mint() in one transaction
    /// @dev Similar to the deposit method, but you give it the number of shares you want instead.
    function mintWithSignature(
        uint256 shares,
        address receiver,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant returns (uint256 assets) {
        uint256 amount = approveMax ? type(uint256).max : previewMint(shares);
        asset.permit(msg.sender, address(this), amount, deadline, v, r, s);
        return (mint(shares, receiver));
    }
}
