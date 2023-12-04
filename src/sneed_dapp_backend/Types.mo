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
    // The txid of the oldest transaction the account has
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

type TxIndexes = List.List<TxIndex>;

type OldSynchStatus = {
    tx_total : TxIndex;
    tx_synched : TxIndex;
};

// Arguments for a transfer operation
type TransferArgs = {
    from_subaccount : ?Subaccount;
    to : Account;
    amount : Balance;
    fee : ?Balance;
    memo : ?Blob;
    created_at_time : ?Nat64;
};
// Arguments for a burn operation
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
    #OnCooldown : { since : Int; remaining : Int; };
    #StaleIndexer : { txid: ?TxIndex };
    #IsSeeder;
    #IsBurner;
    #NotActive;
    #ConversionsNotAllowed;
    #IndexUnderflow : { 
        new_total_balance_underflow_d8 : Balance;
        old_refundable_balance_underflow_d12 : Balance;
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
type SynchStatus = {
    tx_total : TxIndex;
    tx_synched : TxIndex;
};
type IndexAccountResult = {
    #Ok : IndexedAccount;
    #Err : GetNewTransactionsErr;
};
type IndexedAccount = {
    new_total_balance_d8 : Balance;
    old_refundable_balance_d12 : Balance;
    old_balance_d12 : Balance;
    new_total_balance_underflow_d8 : Balance;
    old_refundable_balance_underflow_d12 : Balance;
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
type RefundOldTokensResult = {
    #Ok : TxIndex;
    #Err : RefundOldTokensErr;
};
type RefundOldTokensErr = ConvertError or {
    #RefundsNotAllowed;
};
type Settings = {
  allow_conversions : Bool;
  allow_refunds : Bool;
  allow_burns : Bool;
  allow_burner_refunds : Bool;
  allow_seeder_conversions : Bool;
  allow_burner_conversions : Bool;
};

type OldIndexerInterface = actor {
    get_account_transactions(account : Text) : async [OldTransaction];
    synch_archive_full(token: Text) : async SynchStatus;
};  

type NewIndexerInterface = actor {
    get_account_transactions(request : NewIndexerRequest) : async GetNewTransactionsResult;
};  

type TokenInterface = actor {
    icrc1_transfer(args : TransferArgs) : async TransferResult;
    burn(args : BurnArgs) : async TransferResult;
};
