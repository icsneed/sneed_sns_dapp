// // This is the code for the Sneed "Converter" dApp,
// // which lets users convert from OLD tokens to NEW tokens,
// // In this case from their OLD (pre-SNS) SNEED tokens into
// // NEW (SNS) SNEED tokens.
// //
// // The dApp works as follows:
// // A user can send OLD SNEED tokens to the dApp's backend canister id: czysu-eaaaa-aaaag-qcvdq-cai.
// // Doing so builds up a balance on the dApp for the account.
// // The user can then convert the balance for their account by calling the dApp's "convert" function (available via
// // the dApp's frontend web page UX), providing the principal id (and, optionally, subaccount) of the account they 
// // used to send OLD SNEED to the dApp.
// //
// // The dApp does not require login to use. This means that any user can ask for any account with a balance 
// // on the dApp (that has sent OLD SNEED to the dApp) to have that balance converted from OLD SNEED to NEW SNEED,
// // which are then sent back to the account the OLD SNEED was sent from.
// //
// // This is not considered a risk, as the prompt conversion from OLD SNEED to NEW SNEED is the only purpose for  
// // sending OLD SNEED to the dApp, and as the conversion to NEW SNEED is the only meaningful usecase
// // for OLD SNEED tokens after the launch of the Sneed SNS and the NEW SNEED token.
// //
// // The dApp keeps track of an account's balance in the following way:
// // It starts by asking the OLD SNEED indexer (SneedScan) and the NEW SNEED indexer (The indexer canister
// // automatically created for a new SNS token) for all transactions involving the specified account.
// // 
// // Then the dApp computes a "balance" for the account by: 
// //  - increasing the balance for all OLD SNEED tokens sent to the dApp from the account
// //  - decreasing the balance for all NEW SNEED tokens sent from the dApp to the account
// //  - increasing the balance for all NEW SNEED tokens sent from the account to the dApp
// //    (This is for the initial Seeding transactions, but also so that if anyone sends 
// //     NEW SNEED to the dApp by mistake they can reclaim it by calling the "convert" function).
// //  - decreasing the balance for all OLD SNEED tokens sent from the dApp to the account (refunds).
// //
// // LEGEND: 
// // Variables beginning with "new_" represent entities and token amounts for the NEW token.
// // Variables beginning with "old_" represent entities and token amounts for the OLD token.
// // Variables ending in "_d8" represent token amounts for tokens with 8 decimals.  
// // Variables ending in "_d12" represent token amounts for tokens with 12 decimals.  
// // NB: Variables that represent token amounts and begin with "new_" should end with "_d8",  
// //     and variables that represent token amounts and begin with "old_" should end with "_d12".
// //     The exceptions are expressions involving an "old_" and a "new_" variable, in which 
// //     case one must be converted into the "_d" of the other, so they have the same "_d" suffix.
// //     e.g. "var new_total_balance_d8 = old_balance_d8 + new_sent_acct_to_dapp_d8;"
// //     where the old balance should normally be in a old_balance_d12 variable, but has been 
// //     converted for the purpuse of being used in this expression with another "_d8" variable.

// import Time "mo:base/Time";
// import Int "mo:base/Int";
// import Nat "mo:base/Nat";
// import Nat64 "mo:base/Nat64";
// import Text "mo:base/Text";
// import Iter "mo:base/Iter";
// import Array "mo:base/Array";
// import Hash "mo:base/Hash";
// import Map "mo:base/HashMap";
// import List "mo:base/List";
// import Buffer "mo:base/Buffer";
// import Result "mo:base/Result";
// import Principal "mo:base/Principal";
// import Error "mo:base/Error";

// import T "../Types";
// import Apa "apa";

// shared ({ caller = _initializer_ }) actor class SneedUpgrade() /*: async T.ConverterInterface*/ = this {

// /// VARIABLES ///

//   // Token and indexer canister ids of old and new token
//   //stable var new_token_id = "zfcdd-tqaaa-aaaaq-aaaga-cai"; // TODO (Currently SNS-1)
//   //stable var new_indexer_id = "zlaol-iaaaa-aaaaq-aaaha-cai"; // TODO (Currently SNS-1)
//   stable var new_token_id = "aaaaa-aa"; 
//   stable var new_indexer_id = "aaaaa-aa"; 
//   let old_token_id = "r7cp6-6aaaa-aaaag-qco5q-cai";
//   let old_indexer_id = "xavfs-zyaaa-aaaak-afc2q-cai"; 

//   // Keep track of the transaction index of the most recent send of the new token the dApp has made to each account. 
//   // Before sending any converted tokens to an account, ensure this transaction index (if any) is found in the 
//   // list of transactions fetched for the account at the beginning of the conversion.     
//   stable var stable_new_latest_sent_txids : [(Principal, T.TxIndex)]= [];
//   let new_latest_sent_txids = Map.fromIter<Principal, T.TxIndex>(stable_new_latest_sent_txids.vals(), 10, Principal.equal, Principal.hash);


//   stable var stable_old_latest_sent_txids : [(Principal, T.TxIndex)]= [];
//   let old_latest_sent_txids = Map.fromIter<Principal, T.TxIndex>(stable_old_latest_sent_txids.vals(), 10, Principal.equal, Principal.hash);

//   // dApp settings
//   stable var allow_conversions = true;
//   stable var allow_refunds = true;
//   stable var allow_burns = true;
//   stable var allow_burner_refunds = false;
//   stable var allow_seeder_conversions = false;
//   stable var allow_burner_conversions = false;

//   // Transaction fees of new and old token
//   stable var new_fee_d8 = 1_000;
//   stable var old_fee_d12 = 100_000_000;

//   stable var  d12_to_d8 : Int = 10_000; // 12 to 8 decimals

//   // An account sending this amount or more of the NEW token to the dApp is considered a "Seeder".
//   // Seeders cannot use the "convert" function to return their funds if "allow_seeder_conversions" is false. 
//   // This is expected to be the SNS Treasury, providing the NEW SNEED tokens for conversion.
//   //stable var new_seeder_min_amount_d8 : T.Balance = 10_000;          - DEV! NEVER USE IN PRODUCTION!
//   stable var new_seeder_min_amount_d8 : T.Balance = 100_000_000_000; // 1000 NEW tokens

//   // An account sending this amount or more of the OLD token to the dApp is considered a "Burner".
//   // Burners cannot use the "convert" function to convert their funds if "allow_burner_conversions" is false. 
//   // Burners cannot use the "refund" function to reclaim their funds if "allow_burner_refunds" is false. 
//   // This is expected to be the Sneed Team, providing the OLD SNEED tokens for burning.
//   //stable var old_burner_min_amount_d12 : T.Balance = 100;              - DEV! NEVER USE IN PRODUCTION!
//   //stable var old_burner_min_amount_d12 : T.Balance = 1_000_000_000;   // - TEST! NEVER USE IN PRODUCTION!  // 0.01 OLD tokens
//   stable var old_burner_min_amount_d12 : T.Balance = 1000_000_000_000_000;  // 1000 OLD tokens


//   //stable var cooldown_ns : Nat = 60000000000; // "1 minute ns"         - DEV! NEVER USE IN PRODUCTION!
//   //stable var cooldown_ns : Nat = 300000000000; // "5 minute ns"      - TEST! NEVER USE IN PRODUCTION!
//   //stable var cooldown_ns : Nat = 600000000000; // "10 minutes ns"    - OPTIMISTIC
//   stable var cooldown_ns : Nat = 3600000000000; // "1 hour ns"       - PESSIMISTIC

//   // Keep track of when the "convert" or "refund" function was most recently called for each
//   // account, and enforce a cooldown preventing the functions being called too
//   // frequently for a given account. This also prevents reentrancy issues.
//   let cooldowns = Map.HashMap<Principal, Time.Time>(32, Principal.equal, Principal.hash);

//   // The account representing this dApp
//   func sneed_converter_account() : T.Account {
//     {
//       owner = Principal.fromActor(this);
//       subaccount = null;
//     };    
//   };

// /// ACTORS ///

//   // Old token canister
//   let old_token_canister : T.TokenInterface  = actor (old_token_id);

//   // Old token indexer canister
//   let old_indexer_canister : T.OldIndexerInterface = actor (old_indexer_id);

//   // New token canister
//   var new_token_canister : T.TokenInterface  = actor (new_token_id);

//   // New token indexer canister
//   var new_indexer_canister : T.NewIndexerInterface = actor (new_indexer_id); 

// /// PUBLIC API ///

//   // Returns the status of an account 
//   public func get_account(owner : Text, subaccount: T.Subaccount) : async T.IndexAccountResult {

//     // Ensure the dApp has been activated (the canisters for the NEW token its indexer have been assigned)
//     if (IsInactive()) { return #Err( { message = "Converter application has not yet been activated."; } ); };

//     let account : T.Account = {
//       owner = Principal.fromText(owner);
//       subaccount = ?subaccount;
//     };
 
//     await IndexAccount(account);

//   };

//   // Convert from old tokens to new tokens for an account. 
//   // This function sends the new tokens to the user account.
//   // The amount matches the number of old tokens the
//   // user account has sent to the dApp and that have not 
//   // yet been converted.
//   // Any new tokens that have been sent from the account
//   // to the dApp will also be refunded by a call to this method.
//   // After tokens for an account have been converted,
//   // a cooldown prevents users from calling the "convert" (or "refund") function 
//   // for that same account again before the specified cooldown period has passed.
//   public func convert_account(owner : Text, subaccount: T.Subaccount) : async T.ConvertResult {

//     // Ensure the dApp has been activated (the canisters for the NEW token its indexer have been assigned)
//     if (IsInactive()) { return #Err(#NotActive); };

//     let account : T.Account = {
//       owner = Principal.fromText(owner);
//       subaccount = ?subaccount;
//     };

//     // Ensure the account is not on cooldown.
//     if (OnCooldown(account.owner)) {
//       return #Err(#OnCooldown { 
//         since = CooldownSince(account.owner); 
//         remaining = CooldownRemaining(account.owner); })
//     };

//     // The account was not on cooldown, so we start 
//     // the cooldown timer and proceed with the conversion
//     cooldowns.put(account.owner, Time.now());

//     // Convert from old to new tokens.
//     await ConvertOldTokens(account, null);
    
//   };

//   // Refund old tokens for an account. 
//   // This function sends the old tokens to the user account.
//   // The amount matches the number of old tokens the
//   // user account has sent to the dApp and that have not 
//   // yet been converted.
//   // After tokens for an account have been refunded,
//   // a cooldown prevents users from calling the "refund" (or "convert") function 
//   // for that same account again before the specified cooldown period has passed.
//   public func refund_account(owner : Text, subaccount: T.Subaccount) : async T.RefundOldTokensResult {

//     // Ensure the dApp has been activated (the canisters for the NEW token its indexer have been assigned)
//     if (IsInactive()) { return #Err(#NotActive); };

//     let account : T.Account = {
//       owner = Principal.fromText(owner);
//       subaccount = ?subaccount;
//     };

//     // Ensure the account is not on cooldown.
//     if (OnCooldown(account.owner)) {
//       return #Err(#OnCooldown { 
//         since = CooldownSince(account.owner); 
//         remaining = CooldownRemaining(account.owner); })
//     };

//     // The account was not on cooldown, so we start 
//     // the cooldown timer and proceed with the refund
//     cooldowns.put(account.owner, Time.now());

//     // Refund old tokens.
//     await RefundOldTokens(account, null);
    
//   };

//   // Burns the specified amount of old tokens. 
//   // This method should only be called by the dApp controllers,
//   // And only with great care so no unconverted old tokens are burned,
//   // leaving users able to refund their old token balances! 
//   // NB: users would in still be able to convert their balances to NEW token,
//   //     even if the old tokens on the dApp have been burned.
//   public shared ({ caller }) func burn_old_tokens(amount : T.Balance) : async T.BurnOldTokensResult {

//     // Ensure the dApp has been activated (the canisters for the NEW token its indexer have been assigned)
//     if (IsInactive()) { return #Err(#NotActive); };
    
//     // Ensure only controllers can call this function
//     assert Principal.isController(caller);

//     //Burn old tokens
//     await BurnOldTokens(amount);
    
//   };  

//   // Returns the dApp's settings
//   public func get_settings() : async T.Settings {
//     return {
//       allow_conversions = allow_conversions;
//       allow_refunds = allow_refunds;
//       allow_burns = allow_burns;
//       allow_burner_refunds = allow_burner_refunds;
//       allow_seeder_conversions = allow_seeder_conversions;
//       allow_burner_conversions = allow_burner_conversions;
//       new_fee_d8 = new_fee_d8;
//       old_fee_d12 = old_fee_d12;
//       d12_to_d8 = d12_to_d8;
//       new_seeder_min_amount_d8 = new_seeder_min_amount_d8;
//       old_burner_min_amount_d12 = old_burner_min_amount_d12;
//       cooldown_ns = cooldown_ns;
//     };
//   };

//   // Updates the dApp's settings.
//   // This method can only be called by the dApps controllers.
//   public shared ({ caller }) func set_settings(new_settings : T.Settings) : async Bool {

//     // Ensure only controllers can call this function
//     assert Principal.isController(caller);

//     allow_conversions := new_settings.allow_conversions;
//     allow_refunds := new_settings.allow_refunds;
//     allow_burns := new_settings.allow_burns;
//     allow_burner_refunds := new_settings.allow_burner_refunds;
//     allow_seeder_conversions := new_settings.allow_seeder_conversions;
//     allow_burner_conversions := new_settings.allow_burner_conversions;
//     new_fee_d8 := new_settings.new_fee_d8;
//     old_fee_d12 := new_settings.old_fee_d12;
//     d12_to_d8 := new_settings.d12_to_d8;
//     new_seeder_min_amount_d8 := new_settings.new_seeder_min_amount_d8;
//     old_burner_min_amount_d12 := new_settings.old_burner_min_amount_d12;
//     cooldown_ns := new_settings.cooldown_ns;

//     true;
//   };

//   // Returns the canister identites for the old and the new token.
//   public func get_canister_ids() : async T.GetCanisterIdsResult {
//     return {
//       new_token_canister_id = Principal.fromText(new_token_id);
//       new_indexer_canister_id = Principal.fromText(new_indexer_id);
//       old_token_canister_id = Principal.fromText(old_token_id);
//       old_indexer_canister_id = Principal.fromText(old_indexer_id);
//     };
//   };

//   // Updates the canister identites for the new token.
//   // This method can only be called by the dApps controllers.
//   public shared ({ caller }) func set_new_token_canister_ids(new_token_canister_id : Text, new_indexer_canister_id : Text) : async Bool {

//     // Ensure only controllers can call this function
//     assert Principal.isController(caller);

//     new_token_id := new_token_canister_id;
//     new_indexer_id := new_indexer_canister_id;

//     new_token_canister := actor (new_token_id);
//     new_indexer_canister := actor (new_indexer_id);

//     true;
//   };

// /// PRIVATE FUNCTIONS ///

//   // Convert from OLD tokens to NEW tokens for a specified account.
//   // This function will:
//   // 1) Fetch the list of all NEW token transactions between this dApp 
//   //    and the specified account using the NEW token's indexer canister.
//   // 2) Fetch the list of all OLD token transactions between this dApp 
//   //    and the specified account using the OLD token's indexer canister.
//   // 3) If this account has been involved in conversion before, the dApp has
//   //    saved away the transaction index of the most recent transaction
//   //    in which this dApp sent NEW tokens to the account. If the dApp has
//   //    a record of such a transaction for this account, the function will
//   //    first verify that this known transaction index is found among the
//   //    transactions for the account returned by the indexer, returning
//   //    a #StaleIndexer error if not. A user seeing a #StaleIndexer error
//   //    should retry after a while, giving the indexer a chance to catch up.
//   //    A corresponding verification in the transactions to the OLD account 
//   //    is also made to check for the most recent OLD token transaction 
//   //    from the dApp to the account (refunds).
//   // 4) Derive the account's balance on the dApp (OLD tokens available to
//   //    convert to NEW tokens) by adding up all the OLD token transactions
//   //    from the account to the dApp and subtracting all the NEW token transactions 
//   //    from the dApp to the account (conversions) as well as any OLD token transactions
//   //    from the dApp to the account (OLD token refunds).
//   // 5) Send an amount of NEW tokens to the account, matching the balance
//   //    derived in step 4.
//   // 6) Save the transaction index of the sent NEW tokens for later verification
//   //    in step 2) if the function is called again for the account.
//   private func ConvertOldTokens(account : T.Account, amount_d8: ?T.Balance) : async T.ConvertResult {

//     // Ensure conversions are allowed
//     if (allow_conversions == false) { return #Err(#ConversionsNotAllowed); };

//     // Index the account
//     let indexedAccount = await IndexAccount(account);

//     switch (indexedAccount) {
      
//       // If indexing the account failed, return error    
//       case (#Err({message})) { 
//         return #Err(#GenericError {
//               error_code = 0;
//               message = message;
//           }); 
//       };
      
//       // Indexing succeeded, proceed with conversion
//       case (#Ok(indexed_account)) { 
        
//         // Verify that the last sent NEW token transaction from the dApp to the account, if any,
//         // was found in the list of transactions returned from the NEW token indexer.
//         // If not, the account's derived balance on the dApp would be incorrect (it would seem too large).
//         // In such a scenario a #StaleIndexer error is returned, and the user has to wait and retry later, 
//         // giving the indexer a chance to catch up.  
//         if (indexed_account.new_latest_send_found == false and indexed_account.new_latest_send_txid != null) { 
//           return #Err(#StaleIndexer { txid = indexed_account.new_latest_send_txid; } ); 
//         };

//         // Also verify that the last sent OLD token transaction from the dApp to the account, if any,
//         // was found in the list of transactions returned from the OLD token indexer.
//         if (indexed_account.old_latest_send_found == false and indexed_account.old_latest_send_txid != null) { 
//           return #Err(#StaleIndexer { txid = indexed_account.old_latest_send_txid; } ); 
//         };

//         // Check that the account is not considered a "Seeder". 
//         // A Seeder is an account that sent large sums of NEW token to the dApp.
//         // Seeders are not allowed to convert/return their NEW token balances when allow_seeder_conversions is false.
//         if (indexed_account.is_seeder == true and allow_seeder_conversions == false) { return #Err(#IsSeeder); };

//         // Check that the account is not considered a "Burner". 
//         // A Burner is an account that sent large sums of OLD token to the dApp.
//         // Burners are not allowed to convert their OLD token balances when allow_burner_conversions is false.
//         if (indexed_account.is_burner == true and allow_burner_conversions == false) { return #Err(#IsBurner); };

//         // Check that there is a positive dApp balance for the account.
//         if (indexed_account.new_total_balance_d8 <= 0) { return #Err(#InsufficientFunds { balance = 0; }); };

//         // Verify that the indexer did not find any underflow issues.
//         if (indexed_account.new_total_balance_underflow_d8 > 0
//           or indexed_account.old_refundable_balance_underflow_d12 > 0
//           or indexed_account.old_balance_underflow_d12 > 0) { 
//           return #Err(#IndexUnderflow { 
//             new_total_balance_underflow_d8 = indexed_account.new_total_balance_underflow_d8; 
//             old_refundable_balance_underflow_d12 = indexed_account.old_refundable_balance_underflow_d12;
//             old_balance_underflow_d12 = indexed_account.old_balance_underflow_d12;
//             new_sent_acct_to_dapp_d8 = indexed_account.new_sent_acct_to_dapp_d8;
//             new_sent_dapp_to_acct_d8 = indexed_account.new_sent_dapp_to_acct_d8;
//             old_sent_acct_to_dapp_d12 = indexed_account.old_sent_acct_to_dapp_d12;
//             old_sent_dapp_to_acct_d12 = indexed_account.old_sent_dapp_to_acct_d12;
//           }); 
//         };

//         // put balance and amount in variables that can be sanitized.
//         var new_balance_checked_d8 : Nat = indexed_account.new_total_balance_d8;
//         var new_amount_checked_d8 : Nat = 0;

//         // Compute the max amount that can be sent (balance - fee)
//         var new_max_d8 = 0;
//         if (new_balance_checked_d8 > new_fee_d8) {
//           new_max_d8 := new_balance_checked_d8 - new_fee_d8;
//         };

//         // if no amount was passed to the function's amount_d8 parameter,
//         // use the account's full balance minus the transaction fee as amount.
//         // (NEW token amount is exclusive of fee)
//         switch (amount_d8) {
//           case (null) { new_amount_checked_d8 := new_max_d8; };
//           case (?amt) { new_amount_checked_d8 := amt; };
//         };

//         // If the amount matches the full account balance, subtract the transaction fee.
//         if (new_amount_checked_d8 == new_balance_checked_d8) { new_amount_checked_d8 := new_max_d8};

//         // Verify that the amount is valid: It must be greater than 0.
//         if (new_amount_checked_d8 <= 0) { return #Err(#GenericError { error_code = 0; message = "Amount must be greater than zero."; }); }; 

//         // Verify that the balance is valid: It must be greater than or equal to the sum of the amount and the transaction fee.
//         if (new_balance_checked_d8 < new_amount_checked_d8 + new_fee_d8) { return #Err(#InsufficientFunds { balance = new_balance_checked_d8; }); };        

//         // Create the arguments for the transfer transaction request.                
//         let transfer_args : T.TransferArgs = {
//           from_subaccount = null;
//           to = account;
//           amount = new_amount_checked_d8;
//           fee = null;
//           memo = null;

//           created_at_time = null;
//         };

//         // transfer the new token to the account
//         let transfer_result = await new_token_canister.icrc1_transfer(transfer_args);

//         // If the transaction succeeded, save away the index of the transfer transaction 
//         // for verification during any possible subsequent calls to "convert" for the same account.  
//         switch (transfer_result) {
//           case (#Ok(txid)) { new_latest_sent_txids.put(account.owner, txid); };
//           case _ { /* do nothing*/ };
//         };

//         // Return the result of the transfer transaction.
//         transfer_result;

//       };
//     };
//   };

//   // Refund OLD tokens for a specified account.
//   private func RefundOldTokens(account : T.Account, amount_d12: ?T.Balance) : async T.RefundOldTokensResult {

//     // Ensure refunds are allowed.
//     if (allow_refunds == false) { return #Err(#RefundsNotAllowed); };

//     // Index the account.
//     let indexedAccount = await IndexAccount(account);

//     switch (indexedAccount) {
      
//       // If indexing the account failed, return error    
//       case (#Err({message})) { 
//         return #Err(#GenericError {
//               error_code = 0;
//               message = message;
//           }); 
//       };
      
//       // Indexing succeeded, proceed with conversion
//       case (#Ok(indexed_account)) { 
        
//         // Verify that the last sent OLD token transaction from the dApp to the account, if any,
//         // was found in the list of transactions returned from the OLD token indexer.
//         // If not, the account's derived refundable balance on the dApp would be incorrect (it would seem too large).
//         // In such a scenario a #StaleIndexer error is returned, and the user has to wait and retry later, 
//         // giving the indexer a chance to catch up.  
//         if (indexed_account.old_latest_send_found == false and indexed_account.old_latest_send_txid != null) { 
//           return #Err(#StaleIndexer { txid = indexed_account.old_latest_send_txid; } ); 
//         };

//         // Also verify that the last sent NEW token transaction from the dApp to the account, if any,
//         // was found in the list of transactions returned from the NEW token indexer.
//         if (indexed_account.new_latest_send_found == false and indexed_account.new_latest_send_txid != null) { 
//           return #Err(#StaleIndexer { txid = indexed_account.new_latest_send_txid; } ); 
//         };

//         // Check that the account is not considered a "Burner". 
//         // A Burner is an account that sent large sums of OLD token to the dApp.
//         // Burners are not allowed to refund their OLD token balances when allow_burner_refunds is false.
//         if (indexed_account.is_burner == true and allow_burner_refunds == false) { return #Err(#IsBurner); };

//         // Check that there is a positive dApp balance for the account.
//         if (indexed_account.old_refundable_balance_d12 <= 0) { return #Err(#InsufficientFunds { balance = 0; }); };

//         // Verify that the indexer did not find any underflow issues.
//         if (indexed_account.new_total_balance_underflow_d8 > 0
//           or indexed_account.old_refundable_balance_underflow_d12 > 0
//           or indexed_account.old_balance_underflow_d12 > 0) { 
//           return #Err(#IndexUnderflow { 
//             new_total_balance_underflow_d8 = indexed_account.new_total_balance_underflow_d8; 
//             old_refundable_balance_underflow_d12 = indexed_account.old_refundable_balance_underflow_d12;
//             old_balance_underflow_d12 = indexed_account.old_balance_underflow_d12;
//             new_sent_acct_to_dapp_d8 = indexed_account.new_sent_acct_to_dapp_d8;
//             new_sent_dapp_to_acct_d8 = indexed_account.new_sent_dapp_to_acct_d8;
//             old_sent_acct_to_dapp_d12 = indexed_account.old_sent_acct_to_dapp_d12;
//             old_sent_dapp_to_acct_d12 = indexed_account.old_sent_dapp_to_acct_d12;
//           }); 
//         };

//         // put refundable balance and amount in variables that can be sanitized.
//         var old_refundable_balance_checked_d12 : Nat = indexed_account.old_refundable_balance_d12;
//         var old_amount_checked_d12 : Nat = 0;

//         // if no amount was passed to the function's amount_d12 parameter,
//         // use the account's full refundable balance as amount. 
//         // OLD fee token amount is inclusive of fee.
//         switch (amount_d12) {
//           case (null) { old_amount_checked_d12 := old_refundable_balance_checked_d12; };
//           case (?amt) { old_amount_checked_d12 := amt; };
//         };

//         // Verify that the amount is valid: It must be greater than fee.
//         if (old_amount_checked_d12 <= old_fee_d12) { return #Err(#GenericError { error_code = 0; message = "Amount must be greater than transaction fee."; }); }; 

//         // Verify that the balance is valid: It must be greater than or equal to the sum of the amount.
//         if (old_refundable_balance_checked_d12 < old_amount_checked_d12) { return #Err(#InsufficientFunds { balance = old_refundable_balance_checked_d12; }); };        

//         // Create the arguments for the transfer transaction request.                
//         let transfer_args : T.TransferArgs = {
//           from_subaccount = null;
//           to = account;
//           amount = old_amount_checked_d12;
//           fee = null;
//           memo = null;

//           created_at_time = null;
//         };

//         // transfer the OLD tokens to the account
//         let transfer_result = await old_token_canister.icrc1_transfer(transfer_args);

//         // If the transaction succeeded, save away the index of the transfer transaction 
//         // for verification during any possible subsequent calls to "refund" for the same account.  
//         switch (transfer_result) {
//           case (#Ok(txid)) { old_latest_sent_txids.put(account.owner, txid); };
//           case _ { /* do nothing*/ };
//         };

//         // Return the result of the transfer transaction.
//         transfer_result;

//       };
//     };
//   };

//   // Burn OLD tokens stored on the dApp.
//   private func BurnOldTokens(amount_d12: T.Balance) : async T.BurnOldTokensResult {

//     // Ensure burns are allowed.
//     if (allow_burns == false) { return #Err(#BurnsNotAllowed); };

//     // Create the arguments for the burn transaction request.                
//     let burn_args : T.BurnArgs = {
//       from_subaccount = null;
//       amount = amount_d12;
//       fee = null;
//       memo = null;

//       created_at_time = null;
//     };

//     // burn the old tokens
//     await old_token_canister.burn(burn_args);

//   };

//   // Index an account. 
//   private func IndexAccount(account : T.Account) : async T.IndexAccountResult {

//     // Construct the argument for the request to the NEW token indexer.
//     let new_index_req : T.NewIndexerRequest = {
//       max_results = 100000;
//       start = null;
//       account = account;
//     };

//     // Request the list of all transactions for the account from the NEW token indexer
//     let new_result = await new_indexer_canister.get_account_transactions(new_index_req);
    
//     switch (new_result) {

//       // If the request to the NEW token indexer failed, return the error.
//       case (#Err(errorType)) { return #Err(errorType); };

//       // If the request to the NEW token indexer succeeded, proceed with the sub-indexing.
//       case (#Ok(get_transactions)) { 

//         // Encourage the OLD token indexer to be up to date.
//         // (It is not critical if it fails, worst case the user sees a lower dApp
//         // balance than they would expect and will have to check back later).
//         let waste = await old_indexer_canister.synch_archive_full(old_token_id);

//         // Request the list of all transactions for the account from the OLD token indexer
//         let old_result = await old_indexer_canister.get_account_transactions(Principal.toText(account.owner));

//         // Perform sub-indexing of the OLD token transactions for the account. 
//         // Pick out the transactions that are between the dApp and the account.
//         // Sum up the amount of OLD tokens sent from the account to the dApp
//         // Sum up the amount of OLD tokens sent from the dApp to the account (refunds)
//         let old_balance_result = IndexOldBalance(account, old_result);

//         let old_balance_d12 = old_balance_result.old_balance_d12;

//         // Convert the OLD token balance from d12 to d8. 
//         let old_balance_d8 : T.Balance = Int.abs(old_balance_d12 / d12_to_d8);

//         // Perform sub-indexing of the NEW token transactions for the account. 
//         // Pick out the transactions that are between the dApp and the account.
//         // Sum up the amount of NEW tokens sent from the dApp to the account (converted tokens).
//         // Sum up the amount of NEW tokens sent from the account to the dApp (seeding).
//         let new_balance_result = IndexNewBalance(account, get_transactions.transactions);

//         let new_sent_acct_to_dapp_d8 = new_balance_result.new_sent_acct_to_dapp_d8;
//         let new_sent_dapp_to_acct_d8 = new_balance_result.new_sent_dapp_to_acct_d8;

//         // total NEW token balance is:
//         // OLD tokens sent to dApp - OLD tokens sent to account + NEW tokens sent to dApp - NEW tokens sent to account
//         // or: OLD tokens deposited minus OLD token withdrawn plus NEW tokens deposited minus NEW tokens withdrawn.
//         var new_total_balance_d8 = old_balance_d8 + new_sent_acct_to_dapp_d8;
//         var new_total_balance_underflow_d8 = 0;

//         // If the account has already had some OLD tokens converted into NEW tokens (i.e. NEW tokens have been sent 
//         // from the dApp to the account) then we subtract this amount from the "NEW token total balance" for the account.
//         if (new_total_balance_d8 >= new_sent_dapp_to_acct_d8) {
//           new_total_balance_d8 := new_total_balance_d8 - new_sent_dapp_to_acct_d8;
//         } else {
//           new_total_balance_underflow_d8 := new_sent_dapp_to_acct_d8 - new_total_balance_d8;
//           new_total_balance_d8 := 0;
//         };

//         let new_sent_dapp_to_acct_d12 : T.Balance = Int.abs(new_sent_dapp_to_acct_d8 * d12_to_d8);

//         // The refundable OLD token balance is the OLD token balance minus any funds that have already been converted. 
//         var old_refundable_balance_d12 = 0;
//         var old_refundable_balance_underflow_d12 = 0;
//         if (old_balance_d12 >= new_sent_dapp_to_acct_d12) {
//           old_refundable_balance_d12 := old_balance_d12 - new_sent_dapp_to_acct_d12;
//         } else {
//           old_refundable_balance_underflow_d12 := new_sent_dapp_to_acct_d12 - old_balance_d12;
//         };
        
//         // Return the results of the account indexing operation:
//         return #Ok({
//           new_total_balance_d8 = new_total_balance_d8;          
//           old_refundable_balance_d12 = old_refundable_balance_d12;
//           old_balance_d12 = old_balance_d12;

//           new_total_balance_underflow_d8 = new_total_balance_underflow_d8;          
//           old_refundable_balance_underflow_d12 = old_refundable_balance_underflow_d12;
//           old_balance_underflow_d12 = old_balance_result.old_balance_underflow_d12;
          
//           new_sent_acct_to_dapp_d8 = new_sent_acct_to_dapp_d8;
//           new_sent_dapp_to_acct_d8 = new_sent_dapp_to_acct_d8;
//           old_sent_acct_to_dapp_d12 = old_balance_result.old_sent_acct_to_dapp_d12;
//           old_sent_dapp_to_acct_d12 = old_balance_result.old_sent_dapp_to_acct_d12;
          
//           is_seeder = new_balance_result.is_seeder;
//           is_burner = old_balance_result.is_burner;
//           old_latest_send_found = old_balance_result.old_latest_send_found;
//           old_latest_send_txid = old_balance_result.old_latest_send_txid;
//           new_latest_send_found = new_balance_result.new_latest_send_found;
//           new_latest_send_txid = new_balance_result.new_latest_send_txid;
//         }); 
//       };
//     }
//   };

//   // Index the OLD token balance of the account. 
//   private func IndexOldBalance(account : T.Account, transactions : [T.OldTransaction]) : T.IndexOldBalanceResult {

//     // Track the sum of OLD tokens sent from the account to the dapp
//     var old_sent_acct_to_dapp_d12 : T.Balance = 0;

//     // Track the sum of OLD tokens sent from the dApp to the account (refunds)
//     var old_sent_dapp_to_acct_d12 : T.Balance = 0;

//     // Get the index of the most recent OLD token transfer transaction from the dApp to the account 
//     // (if any, null if account has never refunded)
//     var old_latest_send_txid : ?T.TxIndex = old_latest_sent_txids.get(account.owner);
    
//     // Track if the most recent OLD token transfer transaction from the dApp to the account (if any)
//     // is found in the list of transactions from the OLD token indexer.
//     var old_latest_send_found = false;

//     // Assign an instance of the this dApp to a local variable for efficiency.
//     let sneed_converter_dapp = sneed_converter_account();

//     // Iterate over all the OLD token transactions for the account
//     for (tx in transactions.vals()) {

//       // Check if the transaction index matches the most recent OLD token transfer transaction from the dApp to the account (if any).
//       // If so we set old_latest_send_found to true.
//       if (tx.index == old_latest_send_txid) { old_latest_send_found := true; };

//       // Check if it is a transaction of type "transfer"
//       switch(tx.transfer){

//         case (null) { /* do nothing for mint/burn*/ };
      
//         // For a transfer transaction, check if it is "from" or "to" the dApp,
//         // if so increase the relevant sum counters.
//         case (?transfer) { 

//           // The OLD token indexer lists all the transactions for the principal, 
//           // including transactions for subaccounts. Thus we have to filter down
//           // to transactions that fully match our given account in either
//           // the "from" field or the "to" field, using a comparison that includes the subaccount. 
//           if (transfer.from == account or transfer.to == account) {

//             // This transaction is from the dApp to the account. 
//             // Increase the old_sent_dapp_to_acct_d12 counter by the amount.
//             if (transfer.from == sneed_converter_dapp) { old_sent_dapp_to_acct_d12 := old_sent_dapp_to_acct_d12 + transfer.amount; };

//             // This transaction is from the account to the dApp. 
//             // Increase the old_sent_acct_to_dapp_d12 counter by the amount minus the OLD token fee.
//             // NB: In the OLD token, the amount is inclusive of the fee.
//             if (transfer.to == sneed_converter_dapp) { old_sent_acct_to_dapp_d12 := old_sent_acct_to_dapp_d12 + (transfer.amount - old_fee_d12); };

//           }
//         };
//       };        
//     };
    
//     // Check if the sum of OLD tokens sent from the account to the dApp qualifies the 
//     // account as being considered a "Burner" account. 
//     // If so, it may not allowed to convert or refund its OLD tokens. 
//     let is_burner = old_sent_acct_to_dapp_d12 >= old_burner_min_amount_d12; 

//     // Calculate the OLD token balance as the sum of OLD tokens sent from the account to the dApp,
//     // minus the sum of any OLD tokens sent from the dApp to the account (refunds).
//     var old_balance_d12 = 0;
//     var old_balance_underflow_d12 = 0;
//     if (old_sent_acct_to_dapp_d12 >= old_sent_dapp_to_acct_d12) {
//       old_balance_d12 := old_sent_acct_to_dapp_d12 - old_sent_dapp_to_acct_d12;
//     } else {
//       old_balance_underflow_d12 := old_sent_dapp_to_acct_d12 - old_sent_acct_to_dapp_d12;
//     };

//     // Return the result of the indexing operation.
//     return {
//       old_balance_d12 = old_balance_d12;
//       old_balance_underflow_d12 = old_balance_underflow_d12;
//       old_sent_acct_to_dapp_d12 = old_sent_acct_to_dapp_d12;
//       old_sent_dapp_to_acct_d12 = old_sent_dapp_to_acct_d12;
//       is_burner = is_burner;
//       old_latest_send_found = old_latest_send_found;
//       old_latest_send_txid = old_latest_send_txid;
//     };
//   };

//   // Index the NEW token balance of the account. 
//   private func IndexNewBalance(account : T.Account, transactions : [T.NewTransactionWithId]) : T.IndexNewBalanceResult {

//     // Track the sum of NEW tokens sent from the dApp to the account (Converted).
//     var new_sent_dapp_to_acct_d8 : T.Balance = 0;

//     // Track the sum of NEW tokens sent from the account to the dApp (Seeding, mistakes)
//     var new_sent_acct_to_dapp_d8 : T.Balance = 0;

//     // Get the index of the most recent NEW token transfer transaction from the dApp to the account 
//     // (if any, null if account has never converted)
//     var new_latest_send_txid : ?T.TxIndex = new_latest_sent_txids.get(account.owner);
    
//     // Track if the most recent NEW token transfer transaction from the dApp to the account (if any)
//     // is found in the list of transactions from the NEW token indexer.
//     var new_latest_send_found = false;

//         // Assign an instance of the this dApp to a local variable for efficiency.
//     let sneed_converter_dapp = sneed_converter_account();

//     // Iterate over all the NEW token transactions for the account
//     for (transaction in transactions.vals()) {

//       // Check if the transaction index matches the most recent NEW token transfer transaction from the dApp to the account (if any).
//       // If so we set new_latest_send_found to true.
//       if (transaction.id == new_latest_send_txid) { new_latest_send_found := true; };

//       // Extract the transaction body from the NewTransactionWithId record.
//       let tx = transaction.transaction;

//       // Check if it is a transaction of type "transfer"
//       switch(tx.transfer){

//         case (null) { /* do nothing for mint/burn*/ };

//         // For a transfer transaction, check if it is "from" or "to" the dApp,
//         // if so increase the relevant sum counters.
//         case (?transfer) { 

//           // The NEW token indexer does support listing transactions per subaccount, 
//           // but we still verify that the transaction matches the specifiec account 
//           // in either the "from" field or the "to" field (using a comparison that includes the subaccount.)
//           if (transfer.from == account or transfer.to == account) {

//             // This transaction is from the dApp to the account. 
//             // Increase the new_sent_dapp_to_acct_d8 counter by the amount plus the NEW token fee.
//             // In the NEW token, the amount is exclusive of the fee.
//             if (transfer.from == sneed_converter_dapp) { new_sent_dapp_to_acct_d8 := new_sent_dapp_to_acct_d8 + (transfer.amount + new_fee_d8) };

//             // This transaction is from the account to the dApp. 
//             // Increase the new_sent_acct_to_dapp_d8 counter by the amount.
//             if (transfer.to == sneed_converter_dapp) { new_sent_acct_to_dapp_d8 := new_sent_acct_to_dapp_d8 + transfer.amount; };

//           };
//         };
//       };
//     };

//     // Check if the sum of NEW tokens sent from the account to the dApp qualifies the 
//     // account as being considered a "Seeder" account. 
//     // If so, it may not be allowed to refund its NEW tokens by calling "convert". 
//     // Non-seeders are allowed to return NEW tokens sent by accident to the dApp by calling "convert". 
//     let is_seeder = new_sent_acct_to_dapp_d8 >= new_seeder_min_amount_d8; 

//     // Return the result of the indexing operation.
//     return {
//       new_sent_dapp_to_acct_d8 = new_sent_dapp_to_acct_d8;
//       new_sent_acct_to_dapp_d8 = new_sent_acct_to_dapp_d8;

//       is_seeder = is_seeder;
//       new_latest_send_found = new_latest_send_found;
//       new_latest_send_txid = new_latest_send_txid;
//     };
//   };


//   // Check if the account is on cooldown (i.e. they have to wait until their cooldown expires to call "convert")
//   private func OnCooldown(caller : Principal) : Bool {
//     switch (cooldowns.get(caller)) {
//       case (null) { return false; };
//       case (?since) {
//         if ((Time.now() - since) >= cooldown_ns) {
//           cooldowns.delete(caller);
//           return false;
//         } else {
//           true;
//         };
//       };
//     };
//   };

//   // Return the timestamp in nanoseconds for when the account last called the "convert" function. 
//   // The cooldown period of an account is counted from this time.
//   // Returns 0 if the account has no cooldown timestamp.
//   private func CooldownSince(caller : Principal) : Int {
//     switch (cooldowns.get(caller)) {
//       case (null) { return 0; };
//         case (?since) { since; };
//     };
//   };


//   // Return the remainng cooldown time (in nanoseconds) until an account is allowed to call the "convert" function again. 
//   // Returns 0 if no cooldown period remains (the account balance is ready to be converted)
//   private func CooldownRemaining(caller : Principal) : Int {
//     switch (cooldowns.get(caller)) {
//       case (null) { return 0; };
//       case (?since) {
//         let passed = Time.now() - since; 
//         if (passed >= cooldown_ns) {
//           return 0;
//         } else {
//           return cooldown_ns - passed;
//         };
//       };
//     };
//   };

//   private func IsInactive() : Bool {
//     new_token_id == "aaaaa-aa" or new_indexer_id == "aaaaa-aa" 
//   };

// /// SYSTEM EVENTS ///  

//   system func preupgrade() {
//     stable_new_latest_sent_txids := Iter.toArray(new_latest_sent_txids.entries());
//     stable_old_latest_sent_txids := Iter.toArray(old_latest_sent_txids.entries());
//   };

//   system func postupgrade() {
//     stable_new_latest_sent_txids := [];
//     stable_old_latest_sent_txids := [];
//   };

// };
