// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//This contract is a repesentation of a staking pool, where each user gets a certain amount of rewards for staking tokens in a pool.

//There are several ways of creating a staking pool, and this contract leverages an algorithm to keep track of user staking rewards
//in a gas efficient way.

//100 rewards tokens are given every second to the stakers, and the amount each staker revieces depends on how much tokens the user
//has staked compared to the total amount of tokens the pool holds.

//example: for a given second, if Bob has staked 50 tokens, and the pool holds 100 tokens in total, Bob is elegible for recieving 50%
//of the rewardsToken that are emmited every second, recieving 50 rewards Tokens.

//The problems ocurr when keeping track of the amount of rewards each user is elegible to:
//If we kept track of each reward amount, for each second, for each user the process would be extremely computationally intense, therefore gas-consuming.

//The solution to this problem is leveraging an algorithm which keeps computation at minimum.

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//THE ALGORITHM:

//we want to calculate the staking rewards between t=a and t=b

//L(t) is the total amount of tokens staked at time t
//reward_rate is the total amount of rewards given per second.
//t=0 is the second the pool starts working

//if the amount a user has staked during a period of time in seconds a<=t<=b is constant:

//userRewards = reward_rate * user_amount_staked * (      SUM_between_t0_and_b(  1/L(t)  ) -  SUM_between_t0_and_a-1(  1/L(t) )       )

// "1/L(t)" is the representation of the value that one token holds against the total amount of tokens in the pool for a given second.
// on the previous example it is 1/100, since the second Bob staked the total amount of tokens was 100.

// "SUM_between_t0_and_b(  1/L(t)  )" represents the summation of each individual representation of the value a token holds in the pool for a given
//second between t=0 and t=b, since the moment the pool started working till the moment the user withdraws the stake.

// "SUM_between_t0_and_a-1(  1/L(t) )" represents the same as prevously mentioned, but from t=0 until t=a-1, meaning since the second
//the pool started working until one second before the user deposited his tokens to stake.

// SUM_between_t0_and_b(  1/L(t)  )
// -----------------------------------------------------------------------------
// ^t=0                       ^t=a                                             ^t=b

// SUM_between_t0_and_a-1(  1/L(t) )
// ---------------------------
// ^t=0                      ^t=a-1

//If we subtract the part before the user staked to the total, we are left exclusively with the value of one token against the pool-total
//during the period between a and b, the period the user staked his tokens.

// SUM_between_t0_and_b(  1/L(t)  ) - SUM_between_t0_and_a-1(  1/L(t) )
// ---------------------------++++++++++++++++++++++++++++++++++++++++++++++++++
// ^t=0                       ^t=a                                             ^t=b

//If we multiply this number by the amount of tokens the user staked, and the reward rate we get the total amount the user is elegible to
//for staking user_amount_staked tokens during the period between second a and second b.

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//IMPLEMENTATION AND USE:

//The reason why this algorithm solves the computation-consumption problem is because the contract only has to keep track of one variable per user,
//when the user stakes: SUM_between_t0_and_a-1(  1/L(t) ).

//The contract always keeps track of SUM_between_t0_and_b(  1/L(t)  ), or the total summation of the different values of one token compared to the
//total tokens staked in the pool, and each user only has to keep track of the summation before they started staking.

//When the user wants to claim his reward the contract calculates the summation SUM_between_t0_and_b - the value the contract stored for the user when
//he started staking, and it will multiply it by the reward_rate and user_amount_staked, and it will send the user that amount of rewardTokens.

//We will see the implementation inside the contract itself:
contract StakingReward {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    //Total amount of tokens rewarded to stakers per second
    uint public rewardRate = 100;
    uint public lastUpdateTime;

    //rewardPerTokenStore is the sum of all 1/L(t) from t=0 until b, or as we named it previously SUM_between_t0_and_b(  1/L(t)  )
    uint public rewardPerTokenStored;

    //userRewardPerTokenPaid is a mapping that stores SUM_between_t0_and_a-1(  1/L(t) ) for each user when they stake
    mapping(address => uint) public userRewardPerTokenPaid;

    //A mapping that keeps track of the rewards of each user
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    //modifier that is executed on every one of the three main functions, and updates the three main variables that help calculate
    //the correct rewards per user.

    //Each time it is called with a user address as input, it will calculate how much rewards the address is entitled to recieve and add it
    //to the previous rewards balance.
    //It will also update the general variable SUM_between_t0_and_b(  1/L(t)  ) by calling rewardPerToken(), and set rewardPerTokenStored
    // and the user's rewardPerTokenPaid to the result.

    //This means that the next time updateReward is executed by the same user, it will take as a reward the difference between the amount
    //that was stored for him in userRewardPerTokenPaid and rewardPerTokenStored, which will be updated at the time of execution.

    modifier updateReward(address account) {
        //updates the rewardPerToken storage variable
        rewardPerTokenStored = rewardPerToken();
        //updates the lastUpdateTime, that is used in the rewardPerToken function.
        lastUpdateTime = block.timestamp;

        //updates the rewards mapping from the user,
        rewards[account] = earned(account);
        //resets the SUM_between_t0_and_a-1(  1/L(t) ) variable from the user, which is just rewardPerToken at the time the user "starts" the staking
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function rewardPerToken() public view returns (uint) {
        //the first time its 0
        if (_totalSupply == 0) {
            return 0;
        }
        //after that its SUM_between_t0_and_b(  1/L(t)  ),
        //in the original formula L(t) isn't constant, we just expect to add every instance of it for every second.

        //Since this function is called before every withdraw and stake, we can assume that _totalSupply (aka L(t)) has been constant since the lastUpdatTime
        //
        //therefore the implementation just has to summ the values of 1/_totalSupply for each second that has passed since the lastUpdate, the last time _totalSupply changed.
        //multiplying the (rewardRate * a <= t <=b * (1/L(t))
        //results in the reward per token issued between t=a and t=b, that we finish adding to the global summation of rewardPerTokenStored
        return
            rewardPerTokenStored +
            ((rewardRate * (block.timestamp - lastUpdateTime) * 1e18) /
                _totalSupply);
    }

    //this function is called on every updateReward()
    //Simple subtraction of the currentRewardPerToken (including the last period), with the userRewardPerTokenPaid
    //multiplying the result with the amount of tokens the user has staked gives us the total reward since the last period
    //the user called updateReward with his address.
    //Lastly, this is added into his reward balance.
    function earned(address account) public view returns (uint) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    //The complexity of the stake and withdraw functions are in the updateReward modifier,
    //the rest is just keeping track of tokenBalances and transfering them in and out of the contract.
    function stake(uint _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    //The same goes for getReward, where it just transfers the rewardTokens balance from the user and resets the balance.
    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    //This contract has no access controls, and therefore its not prepared for production. It is just an example of the mechanics
    //of how staking rewards are calculated.
}
