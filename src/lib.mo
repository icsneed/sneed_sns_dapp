// This is the code for the "SneedUpgrade" Converter dApp,
// which lets users convert from OLD tokens to NEW tokens,
// In this case from their OLD (pre-SNS) SNEED tokens into
// NEW (SNS) SNEED tokens.
//
// The dApp works as follows:
// A user can send OLD SNEED tokens to the dApp's backend canister's principal id.
// Doing so builds up a balance on the dApp for the account.
// The user can then convert the balance for their account by calling the dApp's "convert" function (available via
// the dApp's frontend web page UX), providing the principal id (and, optionally, subaccount) of the account they 
// used to send OLD SNEED to the dApp.
//
// The dApp does not require login to use. This means that any user can ask for any account with a balance 
// on the dApp (that has sent OLD SNEED to the dApp) to have that balance converted from OLD SNEED to NEW SNEED,
// which are then sent back to the account the OLD SNEED was sent from.
//
// This is not considered a risk, as the prompt conversion from OLD SNEED to NEW SNEED is the only purpose for  
// sending OLD SNEED to the dApp, and as the conversion to NEW SNEED is the only meaningful usecase
// for OLD SNEED tokens after the launch of the Sneed SNS and the NEW SNEED token.
//
// The dApp keeps track of an account's balance in the following way:
// It starts by asking the OLD SNEED indexer (SneedScan) and the NEW SNEED indexer (The indexer canister
// automatically created for a new SNS token) for all transactions involving the specified account.
// 
// Then the dApp computes a "balance" for the account by: 
//  - increasing the balance for all OLD SNEED tokens sent to the dApp from the account
//  - decreasing the balance for all NEW SNEED tokens sent from the dApp to the account
//  - increasing the balance for all NEW SNEED tokens sent from the account to the dApp
//    (This is for the initial Seeding transactions, but also so that if anyone sends 
//     NEW SNEED to the dApp by mistake they can reclaim it by calling the "convert" function).
//
// LEGEND: 
// Variables beginning with "new_" represent entities and token amounts for the NEW token.
// Variables beginning with "old_" represent entities and token amounts for the OLD token.
// Variables ending in "_d8" represent token amounts for tokens with 8 decimals.  
// Variables ending in "_d12" represent token amounts for tokens with 12 decimals.  
// NB: Variables that represent token amounts and begin with "new_" should end with "_d8",  
//     and variables that represent token amounts and begin with "old_" should end with "_d12".
//     The exceptions are expressions involving an "old_" and a "new_" variable, in which 
//     case one must be converted into the "_d" of the other, so they have the same "_d" suffix.
//     e.g. "var new_total_balance_d8 = old_balance_d8 + new_sent_acct_to_dapp_d8;"
//     where the old balance should normally be in a old_balance_d12 variable, but has been 
//     converted for the purpuse of being used in this expression with another "_d8" variable.

import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Map "mo:base/HashMap";
import List "mo:base/List";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Error "mo:base/Error";

import T "Types";

module {

/// PUBLIC API ///

  public func init() : T.ConverterState {

    // Keep track of the transaction index of the most recent send of the new token the dApp has made to each account. 
    // Before sending any converted tokens to an account, ensure this transaction index (if any) is found in the 
    // list of transactions fetched for the account at the beginning of the conversion.     
    let stable_new_latest_sent_txids : [(Principal, T.TxIndex)]= [];
    let new_latest_sent_txids = Map.HashMap<Principal, T.TxIndex>(10, Principal.equal, Principal.hash);  

    let stable_old_latest_sent_txids : [(Principal, T.TxIndex)]= [];
    let old_latest_sent_txids = Map.HashMap<Principal, T.TxIndex>(10, Principal.equal, Principal.hash); 
    
    // log
    let stable_log : [T.LogItem] = [];
    let log : T.Log = Buffer.Buffer<T.LogItem>(10);

    // Keep track of when the "convert" function was most recently called for each
    // account, and enforce a cooldown preventing the functions being called too
    // frequently for a given account, giving indexers a chance to catch up. 
    // This also prevents reentrancy issues.
    let stable_cooldowns : [(Principal, Time.Time)]= [];
    let cooldowns = Map.HashMap<Principal, Time.Time>(32, Principal.equal, Principal.hash);

    // dApp settings
    let allow_conversions = true;
    let allow_burns = true;

    // Transaction fees of new and old token
    let new_fee_d8 = 1_000;
    let old_fee_d12 = 100_000_000;

    let d8_to_d12 : Nat = 10_000; // 12 to 8 decimals

    // An account sending this amount or more of the NEW token to the dApp is considered a "Seeder".
    // Seeders cannot use the "convert" function to return their funds if "allow_seeder_conversions" is false. 
    // This is expected to be the SNS Treasury, providing the NEW SNEED tokens for conversion.
    //stable var new_seeder_min_amount_d8 : T.Balance = 10_000;          - DEV! NEVER USE IN PRODUCTION!
    let new_seeder_min_amount_d8 : T.Balance = 100_000_000_000; // 1000 NEW tokens

    // An account sending this amount or more of the OLD token to the dApp is considered a "Burner".
    // Burners cannot use the "convert" function to convert their funds if "allow_burner_conversions" is false. 
    // Burners cannot use the "refund" function to reclaim their funds if "allow_burner_refunds" is false. 
    // This is expected to be the Sneed Team, providing the OLD SNEED tokens for burning.
    //stable var old_burner_min_amount_d12 : T.Balance = 100;              - DEV! NEVER USE IN PRODUCTION!
    //stable var old_burner_min_amount_d12 : T.Balance = 1_000_000_000;   // - TEST! NEVER USE IN PRODUCTION!  // 0.01 OLD tokens
    let old_burner_min_amount_d12 : T.Balance = 1000_000_000_000_000;  // 1000 OLD tokens

    // Cooldown time in nanoseconds
    //stable var cooldown_ns : Nat = 60000000000; // "1 minute ns"         - DEV! NEVER USE IN PRODUCTION!
    //stable var cooldown_ns : Nat = 300000000000; // "5 minute ns"      - TEST! NEVER USE IN PRODUCTION!
    //stable var cooldown_ns : Nat = 600000000000; // "10 minutes ns"    - OPTIMISTIC
    let cooldown_ns : Nat = 3600000000000; // "1 hour ns"       - PESSIMISTIC

    /// ACTORS ///

    // Old token canister
    let old_token_canister : T.TokenInterface  = actor ("2vxsx-fae");

    // Old token indexer canister
    let old_indexer_canister : T.OldIndexerInterface = actor ("2vxsx-fae");

    // New token canister
    var new_token_canister : T.TokenInterface  = actor ("2vxsx-fae");

    // New token indexer canister
    var new_indexer_canister : T.NewIndexerInterface = actor ("2vxsx-fae"); 

    {
        persistent = {
        
            var stable_new_latest_sent_txids = stable_new_latest_sent_txids;
            var stable_old_latest_sent_txids = stable_old_latest_sent_txids;
            var stable_cooldowns = stable_cooldowns;
            var stable_log = stable_log;

            var old_token_canister = old_token_canister;
            var old_indexer_canister = old_indexer_canister;
            var new_token_canister = new_token_canister;
            var new_indexer_canister = new_indexer_canister;

            var settings = {

                allow_conversions = allow_conversions;
                allow_burns = allow_burns;

                new_fee_d8 = new_fee_d8;
                old_fee_d12 = old_fee_d12;
                d8_to_d12 = d8_to_d12;

                new_seeder_min_amount_d8 = new_seeder_min_amount_d8;
                old_burner_min_amount_d12 = old_burner_min_amount_d12;
                cooldown_ns = cooldown_ns; 

            };

        };

        ephemeral = {

            var new_latest_sent_txids = new_latest_sent_txids;
            var old_latest_sent_txids = old_latest_sent_txids;
            var cooldowns = cooldowns;
            var log = log;

        };
    };

  };

  // Returns the status of an account 
  public func get_account(context : T.ConverterContext) : async* T.IndexAccountResult {

    // Ensure the dApp has been activated (the canisters for the token ledgers and their indexers have been assigned)
    if (not IsActive(context)) { return #Err(#NotActive); };

    // Ensure account is valid
    if (not ValidateAccount(context.account)) { return #Err(#InvalidAccount); };

    try {

      // Index the account.
      await* IndexAccount(context);

    } catch e {

      return #Err(#ExternalCanisterError({ message = Error.message(e) }));

    };

  };

  // Convert from old tokens to new tokens for an account. 
  // This function sends the new tokens to the user account.
  // The amount matches the number of old tokens the
  // user account has sent to the dApp and that have not 
  // yet been converted.
  // Any new tokens that have been sent from the account
  // to the dApp will also be refunded by a call to this method.
  // After tokens for an account have been converted,
  // a cooldown prevents users from calling the "convert" function 
  // for that same account again before the specified cooldown period has passed.
  public func convert_account(context : T.ConverterContext) : async* T.ConvertResult {

    log_convert_enter(context);

    try {

      // Convert from old to new tokens.
      let result = await* ConvertAccount(context);

      log_convert_exit(context, result, "");

      result;

    } catch e {

      let message = Error.message(e);

      let result : T.ConvertResult = #Err(#ExternalCanisterError({ message = message }));

      log_convert_exit(context, result, message);

      result;

    };
    
  };

  // Burns the specified amount of old tokens. 
  // This method should only be called by the dApp controllers.
  // NB: users will still be able to convert their balances to NEW token,
  //     even when the OLD tokens on the dApp have been burned.
  public func burn_old_tokens(context : T.ConverterContext, amount : T.Balance) : async* T.BurnOldTokensResult {

    log_burn_enter(context);

    try {

      //Burn old tokens
      let result = await* BurnOldTokens(context, amount);

      log_burn_exit(context, result, "");

      result;

    } catch e {

      let message = Error.message(e);

      let result = #Err(#ExternalCanisterError({ message = message }));

      log_burn_exit(context, result, message);

      result;

    };
    
  };  

  // Returns the dApp's settings
  public func get_settings(context : T.ConverterContext) : T.Settings {
    context.state.persistent.settings;
  };

  // Updates the dApp's settings.
  // This method can only be called by the dApp's controllers.
  public func set_settings(context : T.ConverterContext, new_settings : T.Settings) : Bool {

    // Ensure only controllers can call this function
    if (not Principal.isController(context.caller)) { return false; };

    // Store away the old settings in a local variable for logging
    let old_settings = context.state.persistent.settings;

    // Update the settings
    context.state.persistent.settings := new_settings;

    // Log the call
    log_set_settings_call(context, old_settings, new_settings);

    true;
  };

  // Returns the canister identites for the old and the new token.
  public func get_canister_ids(context : T.ConverterContext) : T.GetCanisterIdsResult {
    
    // Extract state from context
    let state = context.state;

    return {
      new_token_canister_id = Principal.fromActor(state.persistent.new_token_canister);
      new_indexer_canister_id = Principal.fromActor(state.persistent.new_indexer_canister);
      old_token_canister_id = Principal.fromActor(state.persistent.old_token_canister);
      old_indexer_canister_id = Principal.fromActor(state.persistent.old_indexer_canister);
    };
  };

  // Updates the canister identites for the new token.
  // This method can only be called by the dApps controllers.
  public func set_canister_ids(
    context : T.ConverterContext, 
    old_token_canister_id : Principal, 
    old_indexer_canister_id : Principal, 
    new_token_canister_id : Principal, 
    new_indexer_canister_id : Principal) : Bool {

    // Ensure only controllers can call this function
    if (not Principal.isController(context.caller)) { return false; };

    // Extract state from context
    let persistent = context.state.persistent;

    let old_canisters : T.CanisterIds = {
      old_token_canister_id = Principal.fromActor(persistent.old_token_canister);
      old_indexer_canister_id = Principal.fromActor(persistent.old_indexer_canister);
      new_token_canister_id = Principal.fromActor(persistent.new_token_canister);
      new_indexer_canister_id = Principal.fromActor(persistent.new_indexer_canister);
    };

    persistent.old_token_canister := actor (Principal.toText(old_token_canister_id));
    persistent.old_indexer_canister := actor (Principal.toText(old_indexer_canister_id));
    persistent.new_token_canister := actor (Principal.toText(new_token_canister_id));
    persistent.new_indexer_canister := actor (Principal.toText(new_indexer_canister_id));

    let new_canisters : T.CanisterIds = {
      old_token_canister_id = old_token_canister_id;
      old_indexer_canister_id = old_indexer_canister_id;
      new_token_canister_id = new_token_canister_id;
      new_indexer_canister_id = new_indexer_canister_id;
    };

    // Log the call
    log_set_canisters_call(context, old_canisters, new_canisters);

    true;
  };

/// PRIVATE FUNCTIONS ///

  // Convert from OLD tokens to NEW tokens for a specified account.
  // This function will:
  // 1) Fetch the list of all NEW token transactions between this dApp 
  //    and the specified account using the NEW token's indexer canister.
  // 2) Fetch the list of all OLD token transactions between this dApp 
  //    and the specified account using the OLD token's indexer canister.
  // 3) If this account has been involved in conversion before, the dApp has
  //    saved away the transaction index of the most recent transaction
  //    in which this dApp sent NEW tokens to the account. If the dApp has
  //    a record of such a transaction for this account, the function will
  //    first verify that this known transaction index is found among the
  //    transactions for the account returned by the indexer, returning
  //    a #StaleIndexer error if not. A user seeing a #StaleIndexer error
  //    should retry after a while, giving the indexer a chance to catch up.
  //    A corresponding verification in the transactions to the OLD account 
  //    is also made to check for the most recent OLD token transaction 
  //    from the dApp to the account (while refunds of OLD tokens are not supported, 
  //    this check is still included as an extra safety measure).
  // 4) Derive the account's balance on the dApp (OLD tokens available to
  //    convert to NEW tokens) by adding up all the OLD token transactions
  //    from the account to the dApp and subtracting all the NEW token transactions 
  //    from the dApp to the account (conversions) as well as any OLD token transactions
  //    from the dApp to the account (OLD token refunds are not supported by dApp 
  //    but any such transactions should still be taken into account for safety).
  // 5) Send an amount of NEW tokens to the account, matching the balance
  //    derived in step 4.
  // 6) Save the transaction index of the sent NEW tokens for later verification
  //    in step 2) if the function is called again for the account.
  public func ConvertAccount(context : T.ConverterContext) : async* T.ConvertResult {

    // Initial Validation

    // Ensure the dApp has been activated (the canisters for the token ledgers and their indexers have been assigned)
    if (not IsActive(context)) { return #Err(#NotActive); };

    // Extract account from context
    let account = context.account;

    // Ensure account is valid
    if (not ValidateAccount(account)) { return #Err(#InvalidAccount); };

    // Ensure the account is not on cooldown.
    if (OnCooldown(context, account.owner)) {
      return #Err(#OnCooldown { 
        since = CooldownSince(context, account.owner); 
        remaining = CooldownRemaining(context, account.owner); })
    };

    // The account was not on cooldown, so we start 
    // the cooldown timer and proceed with the conversion
    context.state.ephemeral.cooldowns.put(account.owner, Time.now());

    // Extract state from context
    let state = context.state;

    // Extract settings from state
    let settings = state.persistent.settings;
    
    // Ensure conversions are allowed
    if (settings.allow_conversions == false) { return #Err(#ConversionsNotAllowed); };

    // Index the account
    let indexedAccount = await* IndexAccount(context);

    switch (indexedAccount) {
      
      // If indexing the account failed, return error    
      case (#Err(error)) { return #Err(error); };
      //case (#Err({message})) { return #Err(#ExternalCanisterError { message = message; }); };
      
      // Indexing succeeded, proceed with conversion
      case (#Ok(indexed_account)) { 
        
        // Verify that the last sent NEW token transaction from the dApp to the account, if any,
        // was found in the list of transactions returned from the NEW token indexer.
        // If not, the account's derived balance on the dApp would be incorrect (it would seem too large).
        // In such a scenario a #StaleIndexer error is returned, and the user has to wait and retry later, 
        // giving the indexer a chance to catch up.  
        if (indexed_account.new_latest_send_found == false and indexed_account.new_latest_send_txid != null) { 
          return #Err(#StaleIndexer { txid = indexed_account.new_latest_send_txid; } ); 
        };

        // Also verify that the last sent OLD token transaction from the dApp to the account, if any,
        // was found in the list of transactions returned from the OLD token indexer.
        if (indexed_account.old_latest_send_found == false and indexed_account.old_latest_send_txid != null) { 
          return #Err(#StaleIndexer { txid = indexed_account.old_latest_send_txid; } ); 
        };

        // Check that the account is not considered a "Seeder". 
        // A Seeder is an account that sent large sums of NEW token to the dApp.
        // Seeders are not allowed to convert/return their NEW token balances.
        if (indexed_account.is_seeder == true) { return #Err(#IsSeeder); };

        // Check that the account is not considered a "Burner". 
        // A Burner is an account that sent large sums of OLD token to the dApp.
        // Burners are not allowed to convert their OLD token balances.
        if (indexed_account.is_burner == true) { return #Err(#IsBurner); };

        // Verify that the indexer did not find any underflow issues.
        if (indexed_account.new_total_balance_underflow_d8 > 0
          or indexed_account.old_balance_underflow_d12 > 0) { 
          return #Err(#IndexUnderflow { 
            new_total_balance_underflow_d8 = indexed_account.new_total_balance_underflow_d8; 
            old_balance_underflow_d12 = indexed_account.old_balance_underflow_d12;
            new_sent_acct_to_dapp_d8 = indexed_account.new_sent_acct_to_dapp_d8;
            new_sent_dapp_to_acct_d8 = indexed_account.new_sent_dapp_to_acct_d8;
            old_sent_acct_to_dapp_d12 = indexed_account.old_sent_acct_to_dapp_d12;
            old_sent_dapp_to_acct_d12 = indexed_account.old_sent_dapp_to_acct_d12;
          }); 
        };

        // Extract new total balance
        let new_total_balance_d8 : Nat = indexed_account.new_total_balance_d8;

        // Check that there is a positive dApp balance for the account, greater than the new token fee.
        if (new_total_balance_d8 <= settings.new_fee_d8) { return #Err(#InsufficientFunds { balance = new_total_balance_d8; }); };

        // put amount in variable that can be sanitized.
        let new_amount_checked_d8 : Nat = new_total_balance_d8 - settings.new_fee_d8;

        // Create the arguments for the transfer transaction request.                
        let transfer_args : T.TransferArgs = {
          from_subaccount = null;
          to = account;
          amount = new_amount_checked_d8;
          fee = ?settings.new_fee_d8;
          memo = ?Blob.fromArray([5,2,3,3,9]);

          created_at_time = null;
        };

        // transfer the new token to the account
        let transfer_result = await state.persistent.new_token_canister.icrc1_transfer(transfer_args);

        // If the transaction succeeded, save away the index of the transfer transaction 
        // for verification during any possible subsequent calls to "convert" for the same account.          
        switch (transfer_result) {
          case (#Ok(txid)) { state.ephemeral.new_latest_sent_txids.put(account.owner, txid); };
          case _ { /* do nothing*/ };
        };

        // Log the transaction attempt
        log_convert_call(context, transfer_result, transfer_args, indexed_account);

        // Return the result of the transfer transaction.
        transfer_result;

      };
    };
  };

  // Burn OLD tokens stored on the dApp.
  public func BurnOldTokens(context : T.ConverterContext, amount_d12: T.Balance) : async* T.BurnOldTokensResult {

    // Initial Validation
    
    // Ensure only controllers can call this function
    if (not Principal.isController(context.caller)) { return #Err(#NotController); };

    // Ensure the dApp has been activated (the canisters for the token ledgers and their indexers have been assigned)
    if (not IsActive(context)) { return #Err(#NotActive); };

    // Ensure the caller is not on cooldown.
    if (OnCooldown(context, context.caller)) {
      return #Err(#OnCooldown { 
        since = CooldownSince(context, context.caller); 
        remaining = CooldownRemaining(context, context.caller); })
    };

    // The caller (controller) was not on cooldown, so we start 
    // the cooldown timer and proceed with the burn.
    // This prevents an accidental double burn 
    // (from accidentally doubly entered DAO propositions to burn.)
    context.state.ephemeral.cooldowns.put(context.caller, Time.now());

    // Extract state from context
    let state = context.state;

    // Extract settings from state
    let settings = state.persistent.settings;

    // Ensure burns are allowed.
    if (settings.allow_burns == false) { return #Err(#BurnsNotAllowed); };

    // Create the arguments for the burn transaction request.                
    let burn_args : T.BurnArgs = {
      from_subaccount = null;
      amount = amount_d12;
      fee = null;
      memo = ?Blob.fromArray([1,3,3,7]);

      created_at_time = null;
    };

    // burn the old tokens
    let burn_result = await state.persistent.old_token_canister.burn(burn_args);

    // Log the transaction attempt
    log_burn_call(context, burn_result, burn_args);

    // Return the result of the burn transactions
    burn_result;

  };

  // Index an account. 
  public func IndexAccount(context : T.ConverterContext) : async* T.IndexAccountResult {

    // Extract account from context
    let account = context.account;

    // Extract state from context
    let state = context.state;

    // Extract settings from state
    let settings = state.persistent.settings;
    
    // Construct the argument for the request to the NEW token indexer.
    let new_index_req : T.NewIndexerRequest = {
      max_results = 10000000000;
      start = null;
      account = account;
    };

    // Request the list of all transactions for the account from the NEW token indexer
    let new_result = await state.persistent.new_indexer_canister.get_account_transactions(new_index_req);
    
    switch (new_result) {

      // If the request to the NEW token indexer failed, return the error.
      //case (#Err(errorType)) { return #Err(errorType); };
      case (#Err({ message })) { return #Err(#ExternalCanisterError({ message = message })); };

      // If the request to the NEW token indexer succeeded, proceed with the sub-indexing.
      case (#Ok(new_transactions)) { 

        // Encourage the OLD token indexer to be up to date.
        // (It is not critical if it fails, worst case the user sees a lower dApp
        // balance than they would expect and will have to check back later).
        let waste = await state.persistent.old_indexer_canister.synch_archive_full(Principal.toText(Principal.fromActor(state.persistent.old_token_canister)));

        // Request the list of all transactions for the account from the OLD token indexer
        let old_transactions = await state.persistent.old_indexer_canister.get_account_transactions(Principal.toText(account.owner));

        // Perform sub-indexing of the OLD token transactions for the account. 
        // Pick out the transactions that are between the dApp and the account.
        // Sum up the amount of OLD tokens sent from the account to the dApp
        // Sum up the amount of OLD tokens sent from the dApp to the account 
        // (refunds not supported by dApp, but such transactions if they exist must be counted)
        let old_balance_result = IndexOldBalance(context, old_transactions);

        let old_balance_d12 = old_balance_result.old_balance_d12;

        // Convert the OLD token balance from d12 to d8. 
        let old_balance_d8 : T.Balance = Int.abs(old_balance_d12 / settings.d8_to_d12);
        
        // Perform sub-indexing of the NEW token transactions for the account. 
        // Pick out the transactions that are between the dApp and the account.
        // Sum up the amount of NEW tokens sent from the dApp to the account (converted tokens).
        // Sum up the amount of NEW tokens sent from the account to the dApp (seeding).
        let new_balance_result = IndexNewBalance(context, new_transactions.transactions);

        let new_sent_acct_to_dapp_d8 = new_balance_result.new_sent_acct_to_dapp_d8;
        let new_sent_dapp_to_acct_d8 = new_balance_result.new_sent_dapp_to_acct_d8;

        // total NEW token balance is:
        // OLD tokens sent to dApp - OLD tokens sent to account + NEW tokens sent to dApp - NEW tokens sent to account
        // or: OLD tokens deposited minus OLD token withdrawn plus NEW tokens deposited minus NEW tokens withdrawn.
        var new_total_balance_d8 = old_balance_d8 + new_sent_acct_to_dapp_d8;
        var new_total_balance_underflow_d8 = 0;

        // If the account has already had some OLD tokens converted into NEW tokens (i.e. NEW tokens have been sent 
        // from the dApp to the account) then we subtract this amount from the "NEW token total balance" for the account.
        if (new_total_balance_d8 >= new_sent_dapp_to_acct_d8) {
          new_total_balance_d8 := new_total_balance_d8 - new_sent_dapp_to_acct_d8;
        } else {
          new_total_balance_underflow_d8 := new_sent_dapp_to_acct_d8 - new_total_balance_d8;
          new_total_balance_d8 := 0;
        };

        let new_sent_dapp_to_acct_d12 : T.Balance = Int.abs(new_sent_dapp_to_acct_d8 * settings.d8_to_d12);
        
        // Return the results of the account indexing operation:
        return #Ok({
          new_total_balance_d8 = new_total_balance_d8;          
          old_balance_d12 = old_balance_d12;

          new_total_balance_underflow_d8 = new_total_balance_underflow_d8;          
          old_balance_underflow_d12 = old_balance_result.old_balance_underflow_d12;
          
          new_sent_acct_to_dapp_d8 = new_sent_acct_to_dapp_d8;
          new_sent_dapp_to_acct_d8 = new_sent_dapp_to_acct_d8;
          old_sent_acct_to_dapp_d12 = old_balance_result.old_sent_acct_to_dapp_d12;
          old_sent_dapp_to_acct_d12 = old_balance_result.old_sent_dapp_to_acct_d12;
          
          is_seeder = new_balance_result.is_seeder;
          is_burner = old_balance_result.is_burner;
          old_latest_send_found = old_balance_result.old_latest_send_found;
          old_latest_send_txid = old_balance_result.old_latest_send_txid;
          new_latest_send_found = new_balance_result.new_latest_send_found;
          new_latest_send_txid = new_balance_result.new_latest_send_txid;
        }); 
      };
    }
  };

  // Index the OLD token balance of the account. 
  public func IndexOldBalance(context : T.ConverterContext, transactions : [T.OldTransaction]) : T.IndexOldBalanceResult {

    // Extract the account from the context
    let account = context.account;

    // Extract the state from the context
    let state = context.state;

    // Extract the settings from the context
    let settings = state.persistent.settings;

    // Track the sum of OLD tokens sent from the account to the dapp
    var old_sent_acct_to_dapp_d12 : T.Balance = 0;

    // Track the sum of OLD tokens sent from the dApp to the account 
    // (refunds not supported by dApp but any such transactions should still be counted)
    var old_sent_dapp_to_acct_d12 : T.Balance = 0;

    // Get the index of the most recent OLD token transfer transaction from the dApp to the account 
    // (if any, null if account has never refunded - which is expected to be the case, since the 
    // dApp does not support refunds of the OLD token.)
    var old_latest_send_txid : ?T.TxIndex = state.ephemeral.old_latest_sent_txids.get(account.owner);
    
    // Track if the most recent OLD token transfer transaction from the dApp to the account (if any)
    // is found in the list of transactions from the OLD token indexer.
    var old_latest_send_found = false;

    // Assign an instance of the this dApp's account to a local variable for efficiency.
    let sneed_converter_dapp = context.converter;

    // Iterate over all the OLD token transactions for the account
    for (tx in transactions.vals()) {

      // Check if the transaction index matches the most recent OLD token transfer transaction from the dApp to the account (if any).
      // If so we set old_latest_send_found to true.
      switch (old_latest_send_txid) {
        case (null) { /* do nothing */ };
        case (?txid) { if (tx.index == txid) { old_latest_send_found := true; }; };
      };

      // Check if it is a transaction of type "transfer"
      switch(tx.transfer){

        case (null) { /* do nothing for mint/burn*/ };
      
        // For a transfer transaction, check if it is "from" or "to" the dApp,
        // if so increase the relevant sum counters.
        case (?transfer) { 

          // The OLD token indexer lists all the transactions for the principal, 
          // including transactions for subaccounts. Thus we have to filter down
          // to transactions that fully match our given account in either
          // the "from" field or the "to" field, using a comparison that includes the subaccount. 
          if (CompareAccounts(transfer.from, account) or CompareAccounts(transfer.to, account)) {

            // This transaction is from the dApp to the account. 
            // Increase the old_sent_dapp_to_acct_d12 counter by the amount.
            if (CompareAccounts(transfer.from, sneed_converter_dapp)) { old_sent_dapp_to_acct_d12 := old_sent_dapp_to_acct_d12 + transfer.amount; };

            // This transaction is from the account to the dApp. 
            // Increase the old_sent_acct_to_dapp_d12 counter by the amount minus the OLD token fee.
            // NB: In the OLD token, the amount is inclusive of the fee.
            if (CompareAccounts(transfer.to, sneed_converter_dapp)) { old_sent_acct_to_dapp_d12 := old_sent_acct_to_dapp_d12 + (transfer.amount - settings.old_fee_d12); };

          }
        };
      };        
    };
    
    // Calculate the OLD token balance as the sum of OLD tokens sent from the account to the dApp,
    // minus the sum of any OLD tokens sent from the dApp to the account (refunds are not supported
    // by the dApp but must be counted if such transactions exist).
    var old_balance_d12 = 0;
    var old_balance_underflow_d12 = 0;
    if (old_sent_acct_to_dapp_d12 >= old_sent_dapp_to_acct_d12) {
      old_balance_d12 := old_sent_acct_to_dapp_d12 - old_sent_dapp_to_acct_d12;
    } else {
      old_balance_underflow_d12 := old_sent_dapp_to_acct_d12 - old_sent_acct_to_dapp_d12;
    };

    // Check if the sum of OLD tokens sent from the account to the dApp qualifies the 
    // account as being considered a "Burner" account. 
    // If so, it may not allowed to convert or refund its OLD tokens. 
    let is_burner = old_sent_acct_to_dapp_d12 >= settings.old_burner_min_amount_d12; 

    // Return the result of the indexing operation.
    return {
      old_balance_d12 = old_balance_d12;
      old_balance_underflow_d12 = old_balance_underflow_d12;
      old_sent_acct_to_dapp_d12 = old_sent_acct_to_dapp_d12;
      old_sent_dapp_to_acct_d12 = old_sent_dapp_to_acct_d12;
      is_burner = is_burner;
      old_latest_send_found = old_latest_send_found;
      old_latest_send_txid = old_latest_send_txid;
    };
  };

  // Index the NEW token balance of the account. 
  public func IndexNewBalance(context : T.ConverterContext, transactions : [T.NewTransactionWithId]) : T.IndexNewBalanceResult {
    
    // Extract the account from the context
    let account = context.account;

    // Extract the state from the context
    let state = context.state;

    // Extract the settings from the context
    let settings = state.persistent.settings;

    // Track the sum of NEW tokens sent from the dApp to the account (Converted).
    var new_sent_dapp_to_acct_d8 : T.Balance = 0;

    // Track the sum of NEW tokens sent from the account to the dApp (Seeding, mistakes)
    var new_sent_acct_to_dapp_d8 : T.Balance = 0;

    // Get the index of the most recent NEW token transfer transaction from the dApp to the account 
    // (if any, null if account has never converted)
    var new_latest_send_txid : ?T.TxIndex = state.ephemeral.new_latest_sent_txids.get(account.owner);
    
    // Track if the most recent NEW token transfer transaction from the dApp to the account (if any)
    // is found in the list of transactions from the NEW token indexer.
    var new_latest_send_found = false;

        // Assign an instance of the this dApp to a local variable for efficiency.
    let sneed_converter_dapp = context.converter;

    // Iterate over all the NEW token transactions for the account
    for (transaction in transactions.vals()) {

      // Check if the transaction index matches the most recent NEW token transfer transaction from the dApp to the account (if any).
      // If so we set new_latest_send_found to true.
      //if (new_latest_send_txid != null and transaction.id == new_latest_send_txid) { new_latest_send_found := true; };
      switch (new_latest_send_txid) {
        case (null) { /* do nothing */ };
        case (?txid) { if (transaction.id == txid) { new_latest_send_found := true; }; };
      };

      // Extract the transaction body from the NewTransactionWithId record.
      let tx = transaction.transaction;

      // Check if it is a transaction of type "transfer"
      switch(tx.transfer){

        case (null) { /* do nothing for mint/burn*/ };

        // For a transfer transaction, check if it is "from" or "to" the dApp,
        // if so increase the relevant sum counters.
        case (?transfer) { 

          // The NEW token indexer does support listing transactions per subaccount, 
          // but we still verify that the transaction matches the specifiec account 
          // in either the "from" field or the "to" field (using a comparison that includes the subaccount.)
          if (CompareAccounts(transfer.from, account) or CompareAccounts(transfer.to, account)) {

            // This transaction is from the dApp to the account. 
            // Increase the new_sent_dapp_to_acct_d8 counter by the amount plus the NEW token fee.
            // In the NEW token, the amount is exclusive of the fee.
            if (CompareAccounts(transfer.from, sneed_converter_dapp)) { new_sent_dapp_to_acct_d8 := new_sent_dapp_to_acct_d8 + (transfer.amount + settings.new_fee_d8) };

            // This transaction is from the account to the dApp. 
            // Increase the new_sent_acct_to_dapp_d8 counter by the amount.
            if (CompareAccounts(transfer.to, sneed_converter_dapp)) { new_sent_acct_to_dapp_d8 := new_sent_acct_to_dapp_d8 + transfer.amount; };

          };
        };
      };
    };

    // Check if the sum of NEW tokens sent from the account to the dApp qualifies the 
    // account as being considered a "Seeder" account. 
    // If so, it may not be allowed to refund its NEW tokens by calling "convert". 
    // Non-seeders are allowed to return NEW tokens sent by accident to the dApp by calling "convert". 
    let is_seeder = new_sent_acct_to_dapp_d8 >= settings.new_seeder_min_amount_d8; 

    // Return the result of the indexing operation.
    return {
      new_sent_dapp_to_acct_d8 = new_sent_dapp_to_acct_d8;
      new_sent_acct_to_dapp_d8 = new_sent_acct_to_dapp_d8;

      is_seeder = is_seeder;
      new_latest_send_found = new_latest_send_found;
      new_latest_send_txid = new_latest_send_txid;
    };
  };

  // Check if the account is on cooldown (i.e. they have to wait until their cooldown expires to call "convert")
  public func OnCooldown(context : T.ConverterContext, owner : Principal) : Bool {

    // Extract cooldowns from context
    let cooldowns = context.state.ephemeral.cooldowns;

    // Extract settings from context
    let settings = context.state.persistent.settings;

    switch (cooldowns.get(owner)) {
      case (null) { return false; };
      case (?since) {
        if ((Time.now() - since) >= settings.cooldown_ns) {
          cooldowns.delete(owner);
          return false;
        } else {
          true;
        };
      };
    };
  };

  // Return the timestamp in nanoseconds for when the account last called the "convert" function. 
  // The cooldown period of an account is counted from this time.
  // Returns 0 if the account has no cooldown timestamp.
  public func CooldownSince(context : T.ConverterContext, owner : Principal) : Int {
    switch (context.state.ephemeral.cooldowns.get(owner)) {
      case (null) { return 0; };
        case (?since) { since; };
    };
  };


  // Return the remainng cooldown time (in nanoseconds) until an account is allowed to call the "convert" function again. 
  // Returns 0 if no cooldown period remains (the account balance is ready to be converted)
  public func CooldownRemaining(context : T.ConverterContext, owner : Principal) : Int {

    // Extract state from context
    let state = context.state;
    
    // Extract settings from state
    let settings = state.persistent.settings;

    switch (state.ephemeral.cooldowns.get(owner)) {
      case (null) { return 0; };
      case (?since) {
        let passed = Time.now() - since; 
        if (passed >= settings.cooldown_ns) {
          return 0;
        } else {
          return settings.cooldown_ns - passed;
        };
      };
    };
  };

  public func CompareAccounts(account1 : T.Account, account2 : T.Account) : Bool {
    if (account1.owner != account2.owner) { return false; };
    if (account1.subaccount == null and account2.subaccount == null) { return true; };
    if (account1.subaccount == null and account2.subaccount 
          == ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])) { return true; };
    if (account1.subaccount == ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
         and account2.subaccount == null) { return true; };

    account1.subaccount == account2.subaccount;
  };

// Taken from https://github.com/NatLabs/icrc1
  // Checks if a subaccount is valid
  public func ValidateSubaccount(subaccount : ?T.Subaccount) : Bool {
      switch (subaccount) {
          case (?bytes) {
              bytes.size() == 32;
          };
          case (_) true;
      };
  };

// Taken from https://github.com/NatLabs/icrc1
  // Checks if an account is valid
  public func ValidateAccount(account : T.Account) : Bool {
      let is_anonymous = Principal.isAnonymous(account.owner);
      let invalid_size = Principal.toBlob(account.owner).size() > 29;

      if (is_anonymous or invalid_size) {
          false;
      } else {
          ValidateSubaccount(account.subaccount);
      };
  };

  // Checks if the application is active (all four collaborator canisters have been assigned.)
  public func IsActive(context : T.ConverterContext) : Bool {
    Principal.isAnonymous(Principal.fromActor(context.state.persistent.old_token_canister)) == false and 
      Principal.isAnonymous(Principal.fromActor(context.state.persistent.old_indexer_canister)) == false and
      Principal.isAnonymous(Principal.fromActor(context.state.persistent.new_token_canister)) == false and 
      Principal.isAnonymous(Principal.fromActor(context.state.persistent.new_indexer_canister)) == false 
  };

  public func get_log(context : T.ConverterContext) : [T.LogItem] {
    
    // Ensure only controllers can call this function
    //if (not Principal.isController(context.caller)) { return []; };

    Buffer.toArray(context.state.ephemeral.log);

  };

  public func get_log_size(context : T.ConverterContext) : Nat {
    
    // Ensure only controllers can call this function
    //if (not Principal.isController(context.caller)) { return 0; };

    context.state.ephemeral.log.size();

  };

  public func get_log_page(context : T.ConverterContext, start : Nat, length : Nat) : [T.LogItem] {
    
    // Ensure only controllers can call this function
    //if (not Principal.isController(context.caller)) { return []; };

    let log = context.state.ephemeral.log;
    let size = log.size();

    if (size < 1) { return []; };

    var chk_start = start;
    var chk_len = length;

    if (chk_start + chk_len >= size) {
      if (chk_start >= size) {
        chk_start := size - 1;
        chk_len := 1;
      } else {
        chk_len := size - chk_start;
      };
    };

    let pre = Buffer.prefix(log, chk_start + chk_len);
    let page = Buffer.suffix(pre, chk_len);

    Buffer.toArray(page);

  };

  public func log_convert_enter(context : T.ConverterContext) : () {
    log_convert(context, "convert_account", "Enter", null, null)
  };

  public func log_convert_call(context : T.ConverterContext, result : T.TransferResult, args : T.TransferArgs, account : T.IndexedAccount) : () {
    let convert : T.ConvertLogItem = {
      result = result;
      args = args;
      account = account;
    };

    log_convert(context, "ConvertAccount", "Complete", ?convert, null)
  };

  public func log_convert_exit(context : T.ConverterContext, result : T.ConvertResult, trapped_message : Text) : () {
    let exit : T.ExitLogItem = {
      convert_result = ?result;
      burn_result = null;
      trapped_message = trapped_message;
    };

    log_convert(context, "convert_account", "Exit", null, ?exit)
  };


  private func log_convert(context : T.ConverterContext, name : Text, message : Text, convert : ?T.ConvertLogItem, exit : ?T.ExitLogItem) : () {
    let logItem : T.LogItem = {
      name = name;
      message = message;
      timestamp = Nat64.fromNat(Int.abs(Time.now()));
      caller = context.caller;
      account = context.account;
      converter = context.converter;
      convert = convert;
      burn = null;
      set_settings = null;
      set_canisters = null;
      exit = exit;
    };

    context.state.ephemeral.log.add(logItem);
  };

  public func log_burn_enter(context : T.ConverterContext) : () {
    log_burn(context, "burn_old_tokens", "Enter", null, null)
  };

  public func log_burn_call(context : T.ConverterContext, result : T.TransferResult, args : T.BurnArgs) : () {
    let burn : T.BurnLogItem = {
      result = result;
      args = args;
    };

    log_burn(context, "BurnOldTokens", "Complete", ?burn, null)
  };

  public func log_burn_exit(context : T.ConverterContext, result : T.BurnOldTokensResult, trapped_message : Text) : () {
    let exit : T.ExitLogItem = {
      convert_result = null;
      burn_result = ?result;
      trapped_message = trapped_message;
    };

    log_burn(context, "burn_old_tokens", "Exit", null, ?exit)
  };

  private func log_burn(context : T.ConverterContext, name : Text, message : Text, burn : ?T.BurnLogItem, exit : ?T.ExitLogItem) : () {
    let logItem : T.LogItem = {
      name = name;
      message = message;
      timestamp = Nat64.fromNat(Int.abs(Time.now()));
      caller = context.caller;
      account = context.account;
      converter = context.converter;
      convert = null;
      burn = burn;
      set_settings = null;
      set_canisters = null;
      exit = exit;
    };

    context.state.ephemeral.log.add(logItem);
  };

  private func log_set_settings_call(context : T.ConverterContext, old_settings : T.Settings, new_settings : T.Settings) : () {
    let logItem : T.LogItem = {
      name = "set_settings";
      message = "Complete";
      timestamp = Nat64.fromNat(Int.abs(Time.now()));
      caller = context.caller;
      account = context.account;
      converter = context.converter;
      convert = null;
      burn = null;
      set_settings = ?{
        old_settings = old_settings;
        new_settings = new_settings;
      };
      set_canisters = null;
      exit = null;
    };

    context.state.ephemeral.log.add(logItem);
  };

  private func log_set_canisters_call(context : T.ConverterContext, old_canisters : T.CanisterIds, new_canisters : T.CanisterIds) : () {
    let logItem : T.LogItem = {
      name = "set_canister_ids";
      message = "Complete";
      timestamp = Nat64.fromNat(Int.abs(Time.now()));
      caller = context.caller;
      account = context.account;
      converter = context.converter;
      convert = null;
      burn = null;
      set_settings = null;
      set_canisters = ?{
        old_canisters = old_canisters;
        new_canisters = new_canisters;
      };
      exit = null;
    };

    context.state.ephemeral.log.add(logItem);
  };

};
