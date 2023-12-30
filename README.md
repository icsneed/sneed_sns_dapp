# sneed_sns_dapp
Sneed SNS dApp

  ```motoko    
To install and run tests locally:
    git clone https://github.com/icsneed/sneed_sns_dapp
    cd sneed_sns_dapp
    npm install
    dfx start 

In a new console, also in sneed_sns_dapp directory:
    dfx deploy

NB: Make sure the canisters get the principal ids assigned to them in the "local" value in the canister_ids.json file, if not, you may need to deploy the canisters one by one, assigning the correct specific principal id to each ("dfx deploy sneed_dapp_backend bd3sg-teaaa-aaaaa-qaaba-cai" etc).

Then, to run the tests:
    dfx canister call sneed_dapp_tests run_tests

A return value of () means all tests ran successfully. You can also check the first console in which you ran dfx start to see the test output. 

To test that state is preserved between updates:
    dfx canister call sneed_dapp_backend burn_old_tokens '(1_000)' 

It is expected that this call returns an error: (variant { Err = variant { NotActive } })

Then check the log size before and after updating the canisters:    
    dfx canister call sneed_dapp_backend get_log_size
    dfx deploy
    dfx canister call sneed_dapp_backend get_log_size

Make sure that get_log_size returns the same number both calls, and that it is a value greater than zero (expected value would be 2). 


