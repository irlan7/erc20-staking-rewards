// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public rewardRate = 1e16;
    
    mapping(address => uint256) public balance;
    mapping(address => uint256) public lastUpdate;
    mapping(address => uint256) public pendingReward;

    constructor(address _staking, address _reward) {
        stakingToken = IERC20(_staking);
        rewardToken = IERC20(_reward);
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
        stakingToken.transferFrom(msg.sender, address(this), amount);
        balance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(balance[msg.sender] >= amount, "not enough");
        _updateReward(msg.sender);
        balance[msg.sender] -= amount;
        stakingToken.transfer(msg.sender, amount);
    }

    function claim() external {
        _updateReward(msg.sender);
        uint256 reward = pendingReward[msg.sender];
        require(reward > 0, "No reward to claim");
        
        pendingReward[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);
    }
}
