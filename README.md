This contract is a repesentation of a staking pool, where each user gets a certain amount of rewards for staking tokens in a pool.

There are several ways of creating a staking pool, and this contract leverages an algorithm to keep track of user staking rewards
in a gas efficient way.

100 rewards tokens are given every second to the stakers, and the amount each staker revieces depends on how much tokens the user
has staked compared to the total amount of tokens the pool holds.

example: for a given second, if Bob has staked 50 tokens, and the pool holds 100 tokens in total, Bob is elegible for recieving 50%
of the rewardsToken that are emmited every second, recieving 50 rewards Tokens.

The problems ocurr when keeping track of the amount of rewards each user is elegible to:
If we kept track of each reward amount, for each second, for each user the process would be extremely computationally intense, therefore gas-consuming.

The solution to this problem is leveraging an algorithm which keeps computation at minimum.



THE ALGORITHM:

we want to calculate the staking rewards between t=a and t=b

L(t) is the total amount of tokens staked at time t
reward_rate is the total amount of rewards given per second.
t=0 is the second the pool starts working

if the amount a user has staked during a period of time in seconds a<=t<=b is constant:

userRewards = reward_rate * user_amount_staked * (      SUM_between_t0_and_b(  1/L(t)  ) -  SUM_between_t0_and_a-1(  1/L(t) )       )

 "1/L(t)" is the representation of the value that one token holds against the total amount of tokens in the pool for a given second.
 on the previous example it is 1/100, since the second Bob staked the total amount of tokens was 100.

 "SUM_between_t0_and_b(  1/L(t)  )" represents the summation of each individual representation of the value a token holds in the pool for a given
second between t=0 and t=b, since the moment the pool started working till the moment the user withdraws the stake.

 "SUM_between_t0_and_a-1(  1/L(t) )" represents the same as prevously mentioned, but from t=0 until t=a-1, meaning since the second
the pool started working until one second before the user deposited his tokens to stake.

 SUM_between_t0_and_b(  1/L(t)  )
 -----------------------------------------------------------------------------
 ^t=0                       ^t=a                                             ^t=b

 SUM_between_t0_and_a-1(  1/L(t) )
 ---------------------------
 ^t=0                      ^t=a-1

If we subtract the part before the user staked to the total, we are left exclusively with the value of one token against the pool-total
during the period between a and b, the period the user staked his tokens.

 SUM_between_t0_and_b(  1/L(t)  ) - SUM_between_t0_and_a-1(  1/L(t) )
 ---------------------------++++++++++++++++++++++++++++++++++++++++++++++++++
 ^t=0                       ^t=a                                             ^t=b

If we multiply this number by the amount of tokens the user staked, and the reward rate we get the total amount the user is elegible to
for staking user_amount_staked tokens during the period between second a and second b.



IMPLEMENTATION AND USE:

The reason why this algorithm solves the computation-consumption problem is because the contract only has to keep track of one variable per user,
when the user stakes: SUM_between_t0_and_a-1(  1/L(t) ).

The contract always keeps track of SUM_between_t0_and_b(  1/L(t)  ), or the total summation of the different values of one token compared to the
total tokens staked in the pool, and each user only has to keep track of the summation before they started staking.

When the user wants to claim his reward the contract calculates the summation SUM_between_t0_and_b - the value the contract stored for the user when
he started staking, and it will multiply it by the reward_rate and user_amount_staked, and it will send the user that amount of rewardTokens.
