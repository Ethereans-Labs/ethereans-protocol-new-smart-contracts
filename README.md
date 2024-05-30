# Development of the following Smart Contracts:

## 1. Re-funder:
Implementation of a smart contract dedicated to executing triggers and identifying other smart contracts within the DAO eligible for refund. The objective is to enable the activation of these smart contracts through third-party bots, ensuring them a reward for execution.

## 2. Onchain price Oracle:
Creation of a smart contract for on-chain token price recording through dedicated transactions.
It returs back the price in dollars of a unity of specified token.
The price is always expressed in 18 decimals, no matter how many decimals the source USD token has;
It externally asks to an AMM quoter to resolve the price.

## 3. Gentle Swapper:
Development of a smart contract for intelligent swap execution, featuring a timedelayed swap strategy.

## 4. Time Bomb Ownership:
Smart contract that gives the possibility to manage the ownership of a DAO for a specific period.