# Sneed SNS Dapp

## Security Assessment Follow-Up

### Title: Type Comparison Warnings
Finding ID: RVVR-SNEED-1

#### Status:
Implemented.

#### Follow-up:
Null case explicitly handled.

### Title: Parallel Burn
Finding ID: RVVR-SNEED-2

#### Status:
Implemented.

#### Follow-up:
Cooldown introduced.

### Title: await Pattern Misuse Leading to State Commit Vulnerabilities
Finding ID: RVVR-SNEED-3

#### Status:
Implemented.

#### Follow-up:
Updated as per recommendation.

### Title: Absence of try/catch handling for asynchronous canister awaits
Finding ID: RVVR-SNEED-4

#### Status:
Implemented.

#### Follow-up:
Try catch introduced in API surface methods, converting to Error. This scenario triggering cooldown is per design (and verified via test), to avoid excessive calls to an external canister that is trapping. Introducing specific try catch blocks around external calls was decided against, as their only role would be to rethrow the exception,
matching current behavior but with more code.  

### Title: 100000 Results - Max Results Attack
Finding ID: RVVR-SNEED-5

#### Status:
Implemented.

#### Follow-up:
The max_results parameter has been increased to 10,000,000,000. Given the transaction fee, we conclude that this makes such an attack impossible since it would require more than the existing supply of the new token to execute.

### Title: Async Indexer Checking
Finding ID: RVVR-SNEED-6

#### Status:
Implemented.

#### Follow-up:
Cooldown for convert_account and burn_old_tokens has been set to 1 hour.

### Title: Cooldown State Not Persisted Across Upgrades
Finding ID: RVVR-SNEED-7

#### Status:
Implemented.

#### Follow-up:
Cooldown state is now saved to stable variable during upgrades. 

### Title: Cycle Drain Attack via Intercanister Calls
Finding ID: RVVR-SNEED-8

#### Status:
No Change.

#### Follow-up:
We see this as a general issue for the IC. We want to keep the application open (no logins). Implementing rate limiting for queries risks hurting legitimate users, so we would rather make sure the canister is monitored and well topped up (which would anyway be the case). Ultimately we believe this is an infrastructure concern that warrants general, rather than dApp-specific, solutions.  

### Title: Inadequate Account Management Through Single-Account Risk
Finding ID: RVVR-SNEED-9

#### Status:
No Change.

#### Follow-up:
This has been the subject of a lot of thought and discussion. That the application requires no login, and that users can send their funds to be converted from any wallet, have been seen as core requirements. This meant that much simpler solutions, such as the straight-forward (implementation wise, not necessarily for the user) Per-User Subaccount Single-transaction Swap, could not be used. It would still be possible to allow for a solution where users first ask the dApp to compute a subaccount for them, and then they send the old tokens to that subaccount of the dApp's principal. However, this would increase complexity in code and for users, and we have concluded that in the end it confers no substantial security advantage. 

Our reasoning is as follows. First, new token funds will always be comingled under the default subaccount of the dApp, so this only concerns the co-mingling of old tokens. It is our conclusion that allowing old tokens to be sent to custom subaccounts would not improve security, since the icrc1_balance_of method for the subaccount would not be the source of truth for how much a certain user should be able to convert, as two users could have sent old tokens to the same subaccount. Only the full inspection of all transactions to the account or subaccount (the current approach) can be the final arbitrer of convertible balance for a user, and adding subaccounts to the mix does not change the security of this approach. Thus, adding per-user dApp subaccounts would only serve to make burning old tokens a much more cumbersome operation, since they are now spread out over thousands of subaccounts. While it could potentially have been argued that using subaccounts would have been safer for the refund operation, we have removed the refund operation, as per advice in RVVR-SNEED-11, making this point moot.

Because adding subaccounts would increase dApp complexity (increasing the surface area for potential bugs), make burn operations cumbersome, and introduce an extra step for users, but still rely on the current approach of inspecting all transactions between the dApp and the account to be watertight (handle the case where two users send funds to the same subaccount), we have decided not to introduce per-user subaccounts to the solution. 

## Title: get_account, convert_account, refund_account - Text Input
Finding ID: RVVR-SNEED-10

#### Status:
Implemented.

#### Follow-up:
Changed to Account input parameter.

### Title: Unnecessary Complexity Due to Refunds Mechanism
Finding ID: RVVR-SNEED-11

#### Status:
Implemented.

#### Follow-up:
Removed refund mechanism.

### Title: Burned Block Pattern Optimization
Finding ID: RVVR-SNEED-12

#### Status:
Implemented.

#### Follow-up:
This would improve speed but not necessarily security. We have opted in favor of keeping minimal state and complexity in the app to optimize for robustness over speed. 

### Title: Null Fee in TransferArgs Could Lead to Unhandled Fee Configuration Changes
Finding ID: RVVR-SNEED-13

#### Status:
Implemented.

#### Follow-up:
Fee is now included in transfer request.

### Title: Null Memos
Finding ID: RVVR-SNEED-14

#### Status:
Implemented.

#### Follow-up:
Memos added to transfer and burn operations. 

### Title: Meaningful Error Codes
Finding ID: RVVR-SNEED-15

#### Status:
Implemented.

#### Follow-up:
Uses of GenericError replaced with specific errors.

### Title: Error Conditions from Indexer Checks
Finding ID: RVVR-SNEED-16

#### Status:
No Change.

#### Follow-up:
We see no actionable distincion for the user if the last sent transaction is not seen because the indexer is lagging in tracking its first transaction (returning no transactions) or a subsequent transaction (returning some transactions but not the tracked one). In both cases the cause would be the same (indexer lag) and the action for the user would be the same (wait a while for the indexer to catch up).

### Title: Lack of Logging Mechanism
Finding ID: RVVR-SNEED-17

#### Status:
Implemented.

#### Follow-up:
Comprehensive logging added to all mutator methods.

### Title: Improper Use of Integer Type for d12_to_d8 Conversion Variable
Finding ID: RVVR-SNEED-18

#### Status:
Implemented.

#### Follow-up:
Changed to Nat. NB: Int.abs( ) is still required to turn the result of a (Nat / Nat) operation from an Int to a Nat. Since both input terms to the division are (now) Nats, neither can be negative so it follows that the result of the division cannot be negative, thus this Int->Nat conversion is safe.

### Title: Inadequate Set-Up of Smart Contract’s Canister ID
Finding ID: RVVR-SNEED-19

#### Status:
Implemented.

#### Follow-up:
Updated as per recommendation.

### Title: Missing Integration Tests for Sneed Converter dApp
Finding ID: RVVR-SNEED-20

#### Status:
Implemented.

#### Follow-up:
Comprehensive set of integration tests added.

### Title: Inadequate Unit Testing for Conversion and Indexing Logic
Finding ID: RVVR-SNEED-21

#### Status:
Implemented.

#### Follow-up:
Comprehensive set of unit tests added.

### Title: Inefficient Map Data Structure in Base Library
Finding ID: RVVR-SNEED-22

#### Status:
No Change.

#### Follow-up:
We opt to sacrifice some speed to avoid including extra dependencies. 

