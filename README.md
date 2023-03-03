This contract is a repesentation of a staking pool, where each user gets a certain amount of rewards for staking tokens in a pool.

There are several ways of creating a staking pool, and this contract leverages an algorithm to keep track of user staking rewards
in a gas efficient way.

100 rewards tokens are given every second to the stakers, and the amount each staker revieces depends on how much tokens the user
has staked compared to the total amount of tokens the pool holds.

example: for a given second, if Bob has staked 50 tokens, and the pool holds 100 tokens in total, Bob is elegible for recieving 50%
of the rewardsToken that are emmited every second, recieving 50 rewards Tokens.

The problems ocurr when keeping track of the amount of rewards each user is elegible to:
If we kept track of each reward amount, for each second, for each user the process would be extremely computationally intensive, therefore gas-consuming.

The solution to this problem is leveraging an algorithm which keeps computation at minimum.



