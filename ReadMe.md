# Making provably random Raffle contracts

# About

This code is to make a provably random smart contract Lottery

## What this contract is going to do?

1. Users can enter by paying for a ticket
    1. The ticket fees are going to go to the Winner during the draw
2. After X amount of time , the lottery will automatically draw a winner 
    1. this is will be done programmatically
3. Using Chainlink VRF and ChainLink automation
    1. Chainlink VRF-> Randomness
    2. Chainlink automation -> Time based Trigger


using chainlink VRF to generate Randomness outside of the Blockchain
for something to happen on the blockchain someone has to pay some Gas

When we are requesting the random number we don't want anyone else to enter the Raffle



### Test
1. Write Deploy scripts
2. Write our tests
    1. Work on forked tests
    2. Forked TestNet
    3. Forked mainnet


