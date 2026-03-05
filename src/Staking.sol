// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking {
    using SafeERC20 for IERC20;

    IERC20 public immutable STAKING_TOKEN;
    IERC20 public immutable REWARD_TOKEN;
    uint256 public rewardRate = 1e16;
    
    mapping(address => uint256) public balance;
    mapping(address => uint256) public lastUpdate;
    mapping(address => uint256) public pendingReward;

    constructor(address _staking, address _reward) {
        STAKING_TOKEN = IERC20(_staking);
        REWARD_TOKEN = IERC20(_reward);
    }

    function _updateReward(address account) internal {
        uint256 time = block.timestamp - lastUpdate[account];
        if (time > 0 && balance[account] > 0) {
            uint256 reward = balance[account] * rewardRate * time / 1e18;
            pendingReward[account] += reward;
        }
        lastUpdate[account] = block.timestamp;
    }

    function stake(uint256 amount) external {
        _updateReward(msg.sender);
        STAKING_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        balance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(balance[msg.sender] >= amount, "not enough");
        _updateReward(msg.sender);
        balance[msg.sender] -= amount;
        STAKING_TOKEN.safeTransfer(msg.sender, amount);
    }

    function claim() external {
        _updateReward(msg.sender);
        uint256 reward = pendingReward[msg.sender];
        require(reward > 0, "No reward to claim");
        
        pendingReward[msg.sender] = 0;
        REWARD_TOKEN.safeTransfer(msg.sender, reward);
    }
}
