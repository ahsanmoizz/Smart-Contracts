# CrowdFunding Contract

## Overview
The **CrowdFunding Contract** is a decentralized smart contract built on the Ethereum blockchain for creating and managing crowdfunding campaigns. It allows project owners to:
- Set up a fundraising campaign with a goal.
- Accept contributions from users.
- Withdraw funds once the campaign goal is met.
- Refund contributors if the goal is not met by the end of the campaign.

This contract helps manage funds securely and efficiently, leveraging Ethereum’s transparency and immutability.

## Features
- **Add Funds**: Allows contributors to donate ETH to the campaign.
- **Withdraw Funds**: Enables the campaign owner to withdraw funds if the fundraising goal is met.
- **Refund Contributors**: If the goal is not met by the campaign deadline, contributors can request refunds.

## Functions

### 1. `addFunds()`
   - **Description**: Contributors can donate funds to the campaign.
   - **Input**: ETH (contributed amount).
   - **Usage**: Contributors call this function to send ETH to the contract.
   - **Example**: 
     ```solidity
     contract.addFunds({ value: ethers.utils.parseEther("1") });
     ```

### 2. `withdrawFunds()`
   - **Description**: The owner of the campaign can withdraw the raised funds once the campaign goal is reached.
   - **Conditions**: The goal must be met, and the campaign must be ended.
   - **Usage**: Only the owner can call this function to withdraw the funds.
   - **Example**:
     ```solidity
     contract.withdrawFunds();
     ```

### 3. `refundContributors()`
   - **Description**: Contributors can request a refund if the campaign goal is not met by the end of the campaign.
   - **Usage**: Contributors who have contributed but the campaign goal was not met can call this function to get their funds back.
   - **Example**:
     ```solidity
     contract.refundContributors();
     ```

## Deployment Instructions

### Prerequisites:
- **Solidity** version 0.8.x.
- **MetaMask** or any Ethereum wallet for interacting with the contract.
- **Truffle** or **Hardhat** framework for deploying and interacting with the contract.

### Steps:
1. **Install Dependencies** (if using Hardhat or Truffle):
   - Install Node.js (if not already installed).
   - Run `npm install` in your project directory to install required packages.

2. **Compile the Contract**:
   - Using Hardhat:
     ```bash
     npx hardhat compile
     ```
   - Using Truffle:
     ```bash
     truffle compile
     ```

3. **Deploy the Contract**:
   - Deploy on a testnet (like Rinkeby or Ropsten) first:
     - Using Hardhat: `npx hardhat run scripts/deploy.js --network rinkeby`
     - Using Truffle: `truffle migrate --network rinkeby`
   
4. **Interact with the Contract**:
   After deployment, you can interact with the contract using a web3 interface (such as MetaMask) or through the command line with Hardhat/Truffle scripts.

## Example Usage

### 1. **Add Funds**
   - Contributors send ETH to the contract via `addFunds()`. Example using a JavaScript script:
     ```javascript
     const tx = await contract.addFunds({ value: ethers.utils.parseEther("0.5") });
     await tx.wait();
     ```

### 2. **Withdraw Funds** (Only for the Campaign Owner)
   - The campaign owner can withdraw funds using `withdrawFunds()`:
     ```javascript
     const tx = await contract.withdrawFunds();
     await tx.wait();
     ```

### 3. **Refund Contributors** (If the Goal is Not Met)
   - If the goal is not met, contributors can request refunds:
     ```javascript
     const tx = await contract.refundContributors();
     await tx.wait();
     ```

## License
This project is licensed under the MIT License 
