// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingALg {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint256 public rewardRate = 10;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => uint256) private balances;
    uint256 public _totalSupply;

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    modifier  {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        _;
    }

    function rewargPerToken() public view returns(uint256) {
        if(_totalSupply == 0) {
            return 0;
        }
        return rewardPerTokenStored + (
            rewardRate * (block.timestamp - lastUpdateTime)
        ) * 1e18 / _totalSupply;
    }

    function earned(address _account) public view returns(uint256) {
        return (
            _balances[_account] * (
                rewardPerToken() - userRewardTokenPaid[_account]
            ) / 1e18
        ) + rewards[_account];
    }

    function stake(uint _amount) external updateReward(msg.sender){
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(_amount) external updateReward(msg.sender){
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    } 

    function getReward() external updateReward(msg.sender){
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    } 
        
}