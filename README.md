# Project Kardeshev's DAO with Memeframe capabilities

# Handlers List

## Token Module

The token module handles various token-related actions, including information retrieval, balance checking, and token transfer.

### `Info`
- **Tag**: Action: Info
- **Description**: Retrieves information about the token.
- **Required Properties**:
  - `Target`: The recipient of the token information.

### `Balance`
- **Tag**: Action: Balance
- **Description**: Retrieves the balance of a specific account.
- **Required Properties**:
  - `Owner`: The account whose balance is being checked.

### `TokenBalances`
- **Tag**: Action: TokenBalances
- **Description**: Retrieves the balances of all accounts.
- **Required Properties**: None.

### `Transfer`
- **Tag**: Action: Transfer
- **Description**: Transfers tokens from one account to another.
- **Required Properties**:
  - `Recipient`: The account receiving the tokens.
  - `Quantity`: The amount of tokens to transfer.

### `Mint`
- **Description**: Mints new tokens.
- **Required Properties**:
  - `Action`: Must be "Credit-Notice".
  - `From-Process`: Must match the specified CRED identifier.

### `SelfMint`
- **Description**: Allows the process itself to mint new tokens.
- **Required Properties**:
  - `From`: Must match the process ID.
  - `Action`: "SelfMint".
  - `Quantity`: The amount of tokens to mint.

## Proposal Module

The proposal module enables DAO members to submit and vote on proposals.

### `Propose`
- **Tag**: Action: Propose
- **Description**: Submits a new proposal for consideration.
- **Required Properties**:
  - `Stake`: The amount of tokens staked with the proposal.
  - `Title`: The name of the proposal.
  - `Description`: The proposal's details.
  - `Meme-Frame-Id`: (Optional) An associated MemeFrame ID.

### `Vote`
- **Tag**: Action: Vote
- **Description**: Casts a vote on a proposal.
- **Required Properties**:
  - `ProposalId`: The ID of the proposal being voted on.
  - `Vote`: The vote cast ("yay" or "nay").
  - `Stake`: The amount of tokens staked on the vote.

### `GetProposals`
- **Tag**: Action: GetProposals
- **Description**: Retrieves proposals.
- **Required Properties**: None. Specific proposals can be requested.

## Subscription Handlers

Handlers for subscribing and unsubscribing from notifications.

### `Subscribe`
- **Tag**: Action: Subscribe
- **Description**: Subscribes to notifications.
- **Required Properties**:
  - `Target`: The account subscribing.

### `Unsubscribe`
- **Tag**: Action: Unsubscribe
- **Description**: Unsubscribes from notifications.
- **Required Properties**:
  - `Target`: The account unsubscribing.
