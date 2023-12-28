import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Map "mo:base/HashMap";
import List "mo:base/List";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Error "mo:base/Error";

type Timestamp = Nat64;
type Subaccount = Blob;
type TxIndex = Nat;
type Balance = Nat;
type TxIndexes = List.List<TxIndex>;
type Log = Buffer.Buffer<LogItem>;
     
type ConverterContext = {
    caller : Principal;
    state : ConverterState;
    account : Account;
    converter : Account;
};

type ConverterState = {

    persistent : ConverterPersistentState;
    ephemeral : ConverterEphemeralState;

};

type ConverterPersistentState = {

    var stable_new_latest_sent_txids : [(Principal, TxIndex)];
    var stable_old_latest_sent_txids : [(Principal, TxIndex)];
    var stable_log : [LogItem];

    var old_token_canister : TokenInterface;
    var old_indexer_canister : OldIndexerInterface;
    var new_token_canister : TokenInterface;
    var new_indexer_canister : NewIndexerInterface; 

    var settings : Settings;

};

type ConverterEphemeralState = {
    var new_latest_sent_txids : Map.HashMap<Principal, TxIndex>;
    var old_latest_sent_txids : Map.HashMap<Principal, TxIndex>;
    var cooldowns : Map.HashMap<Principal, Time.Time>;
    var log : Log;
};

type Account = {
    owner : Principal;
    subaccount : ?Subaccount;
};

type AccountBalance = {
    owner : Principal;
    balance : Balance;
};

type NewTransactionWithId = {
    id : TxIndex;
    transaction : NewTransaction;
};

type GetNewTransactions = {
    transactions : [NewTransactionWithId];
    oldest_tx_id : ?TxIndex;
};

type GetNewTransactionsErr = {
    message : Text;
};

type GetNewTransactionsResult = {
    #Ok : GetNewTransactions;
    #Err : GetNewTransactionsErr;
};

type NewTransaction = {
    kind : Text;
    mint : ?Mint;
    burn : ?NewBurn;
    transfer : ?NewTransfer;
    approve : ?Approve;
    timestamp : Nat64;
};

type NewIndexerRequest = {
    max_results : Nat;
    start : ?Nat;
    account : Account;
};

type OldTransaction = {
    kind : Text;
    mint : ?Mint;
    burn : ?OldBurn;
    transfer : ?OldTransfer;
    index : TxIndex;
    timestamp : Timestamp;
};

type OldTransfer = {
    from : Account;
    to : Account;
    amount : Balance;
    fee : ?Balance;
    memo : ?Blob;
    created_at_time : ?Nat64;
};

type NewTransfer = {
    amount : Nat;
    from : Account;
    to : Account;
    spender : ?Account;
    memo : ?Blob;
    created_at_time : ?Nat64;
    fee : ?Nat;
};

type Mint = {
    to : Account;
    amount : Balance;
    memo : ?Blob;
    created_at_time : ?Nat64;
};

type OldBurn = {
    from : Account;
    amount : Balance;
    memo : ?Blob;
    created_at_time : ?Nat64;
};

type NewBurn = {
    amount : Nat;
    from : Account;
    spender : ?Account;
    memo : ?Blob;
    created_at_time : ?Nat64;
};

type Approve = {
    amount : Nat;
    from : Account;
    spender : ?Account;
    expected_allowance : ?Nat;
    expires_at : ?Nat64;
    memo : ?Blob;
    created_at_time : ?Nat64;
    fee : ?Nat;
};

type OldTransactionRange = {
    transactions: [OldTransaction];
};

type OldSynchStatus = {
    tx_total : TxIndex;
    tx_synched : TxIndex;
};

type TransferArgs = {
    from_subaccount : ?Subaccount;
    to : Account;
    amount : Balance;
    fee : ?Balance;
    memo : ?Blob;
    created_at_time : ?Nat64;
};

type BurnArgs = {
    from_subaccount : ?Subaccount;
    amount : Balance;
    memo : ?Blob;
    created_at_time : ?Nat64;
};

type TimeError = {
    #TooOld;
    #CreatedInFuture : { ledger_time : Timestamp };
};

type TransferError = TimeError or {
    #BadFee : { expected_fee : Balance };
    #BadBurn : { min_burn_amount : Balance };
    #InsufficientFunds : { balance : Balance };
    #Duplicate : { duplicate_of : TxIndex };
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
};

type TransferResult = {
    #Ok : TxIndex;
    #Err : TransferError;
};

type ConvertError = TransferError or {
    #InvalidAccount;
    #OnCooldown : { since : Int; remaining : Int; };
    #StaleIndexer : { txid: ?TxIndex };
    #ExternalCanisterError : { message: Text };
    #IsSeeder;
    #IsBurner;
    #NotActive;
    #ConversionsNotAllowed;
    #IndexUnderflow : { 
        new_total_balance_underflow_d8 : Balance;
        old_balance_underflow_d12 : Balance;
        new_sent_acct_to_dapp_d8 : Balance;
        new_sent_dapp_to_acct_d8 : Balance;
        old_sent_acct_to_dapp_d12 : Balance;
        old_sent_dapp_to_acct_d12 : Balance;
    };
};

type ConvertResult = {
    #Ok : TxIndex;
    #Err : ConvertError;
};

type IndexAccountResult = {
    #Ok : IndexedAccount;
    #Err : IndexAccountError;
};

type IndexAccountError = {
    #InvalidAccount;
    #NotActive;
    #ExternalCanisterError : { message: Text };   
};

type IndexedAccount = {
    new_total_balance_d8 : Balance;
    old_balance_d12 : Balance;
    new_total_balance_underflow_d8 : Balance;
    old_balance_underflow_d12 : Balance;
    new_sent_acct_to_dapp_d8 : Balance;
    new_sent_dapp_to_acct_d8 : Balance;
    old_sent_acct_to_dapp_d12 : Balance;
    old_sent_dapp_to_acct_d12 : Balance;
    is_seeder : Bool;
    is_burner : Bool;
    old_latest_send_found : Bool;
    old_latest_send_txid : ?TxIndex;
    new_latest_send_found : Bool;
    new_latest_send_txid : ?TxIndex;
};

type IndexOldBalanceResult = {
    old_balance_d12 : Balance;
    old_balance_underflow_d12 : Balance;
    old_sent_acct_to_dapp_d12 : Balance;
    old_sent_dapp_to_acct_d12 : Balance;
    is_burner : Bool;
    old_latest_send_found : Bool;
    old_latest_send_txid : ?TxIndex;
};

type IndexNewBalanceResult = {
    new_sent_acct_to_dapp_d8 : Balance;
    new_sent_dapp_to_acct_d8 : Balance;
    is_seeder : Bool;
    new_latest_send_found : Bool;
    new_latest_send_txid : ?TxIndex;
};

type GetCanisterIdsResult = {
    new_token_canister_id : Principal;
    new_indexer_canister_id : Principal;
    old_token_canister_id : Principal;
    old_indexer_canister_id : Principal;
};

type BurnOldTokensResult = {
    #Ok : TxIndex;
    #Err : BurnOldTokensErr;
};

type BurnOldTokensErr = ConvertError or {
    #IsNotController;
    #BurnsNotAllowed;
};

type Settings = {
  allow_conversions : Bool;
  allow_burns : Bool;
  new_fee_d8 : Balance;
  old_fee_d12 : Balance;
  d8_to_d12 : Int;
  new_seeder_min_amount_d8 : Balance;
  old_burner_min_amount_d12 : Balance;
  cooldown_ns : Nat; 
};

type LogItem = {
    name : Text;
    message : Text;
    timestamp : Timestamp;
    caller : Principal;
    account : Account;
    converter : Account;

    convert : ?ConvertLogItem;
    burn : ?BurnLogItem;
    exit : ?ExitLogItem;
};

type ConvertLogItem = {
    result : TransferResult;
    args : TransferArgs;
    account : IndexedAccount;
};

type BurnLogItem = {
    result : TransferResult;
    args : BurnArgs;
};

type ExitLogItem = {
    trapped_message : Text;
    convert_result : ?ConvertResult;
    burn_result : ?BurnOldTokensResult;
};

type Mocks = {
    old_token_mock : TokenInterface;
    old_indexer_mock : OldIndexerInterface;
    new_token_mock : TokenInterface;
    new_indexer_mock : NewIndexerInterface;
};

type ConverterInterface = actor {
    get_account(account: Account) : async IndexAccountResult;
    convert_account(account: Account) : async ConvertResult;
    burn_old_tokens(amount : Balance) : async BurnOldTokensResult;
};

type OldIndexerInterface = actor {
    get_account_transactions(account : Text) : async [OldTransaction];
    synch_archive_full(token: Text) : async OldSynchStatus;
};  

type NewIndexerInterface = actor {
    get_account_transactions(request : NewIndexerRequest) : async GetNewTransactionsResult;
};  

type TokenInterface = actor {
    icrc1_transfer(args : TransferArgs) : async TransferResult;
    burn(args : BurnArgs) : async TransferResult;    
};
