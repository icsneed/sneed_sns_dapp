import Time "mo:base/Time";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Bool "mo:base/Bool";
import Blob "mo:base/Blob";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";

import Converter "../../src/";
import T "../../src/Types";

import ActorSpec "ActorSpec";

module {

    public func get_context() : T.ConverterContext {

        let caller = Principal.fromText("2vxsx-fae");
        let account : T.Account = { 
            owner = Principal.fromText("cpi23-5qaaa-aaaag-qcs5a-cai");
            subaccount = null;
        };
        let converter : T.Account = { 
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = null;
        };

        let state = Converter.init();

        return {
            caller = caller;
            state = state;
            account = account;
            converter = converter;
        };
    };

    public func get_caller_context(caller : Principal) : T.ConverterContext {

        let account : T.Account = { 
            owner = Principal.fromText("cpi23-5qaaa-aaaag-qcs5a-cai");
            subaccount = null;
        };
        let converter : T.Account = { 
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = null;
        };

        let state = Converter.init();

        return {
            caller = caller;
            state = state;
            account = account;
            converter = converter;
        };
    };

    public func get_caller_active_context(caller : Principal) : T.ConverterContext {

        let account : T.Account = { 
            owner = Principal.fromText("cpi23-5qaaa-aaaag-qcs5a-cai");
            subaccount = null;
        };
        let converter : T.Account = { 
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = null;
        };

        let state = Converter.init();

        let context = {
            caller = caller;
            state = state;
            account = account;
            converter = converter;
        };

        let waste = Converter.set_canister_ids(context, "czysu-eaaaa-aaaag-qcvdq-cai", "czysu-eaaaa-aaaag-qcvdq-cai", "czysu-eaaaa-aaaag-qcvdq-cai", "czysu-eaaaa-aaaag-qcvdq-cai");

        return context;
    };

    public func get_converter_subaccount() : T.Account {
        {
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = ?Blob.fromArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);
        };
    };

    public func get_converter_zeroes_subaccount() : T.Account {
        {
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        };
    };

    public func get_test_subaccount() : T.Account {
        {
            owner = Principal.fromText("cpi23-5qaaa-aaaag-qcs5a-cai");
            subaccount = ?Blob.fromArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);
        };
    };

    public func get_test_zeroes_subaccount() : T.Account {
        {
            owner = Principal.fromText("cpi23-5qaaa-aaaag-qcs5a-cai");
            subaccount = ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        };
    };

    public func get_test_account1() : T.Account {
        {
            owner = Principal.fromText("auzum-qe7jl-z2f6l-rwp3r-wkr4f-3rcz3-l7ejm-ltcku-c45fw-w7pi4-hqe");
            subaccount = null;
        };
    };

    public func get_test_account2() : T.Account {
        {
            owner = Principal.fromText("rkf6t-7iaaa-aaaag-qco6a-cai");
            subaccount = null;
        };
    };

    public func get_old_acct_to_dapp_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.OldTransaction { get_old_tx(context, index, amount, context.account, context.converter); };

    public func get_old_dapp_to_acct_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.OldTransaction { 
        context.state.ephemeral.old_latest_sent_txids.put(context.account.owner, index);
        get_old_tx(context, index, amount, context.converter, context.account); 
    };

    public func get_old_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance, from : T.Account, to : T.Account) : T.OldTransaction {
        let timestamp : T.Timestamp = Nat64.fromNat(Int.abs(Time.now()));
        return {
            kind = "TRANSFER";
            mint = null;
            burn = null;
            transfer = ?{
                from = from;
                to = to;
                amount = amount;
                fee = null;
                memo = null;
                created_at_time = ?timestamp;
            };
            index = index;
            timestamp = timestamp;
        };
    };

    public func get_new_acct_to_dapp_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.NewTransactionWithId { get_new_tx(context, index, amount, context.account, context.converter); };

    public func get_new_dapp_to_acct_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.NewTransactionWithId {     
        context.state.ephemeral.new_latest_sent_txids.put(context.account.owner, index);
        get_new_tx(context, index, amount, context.converter, context.account); 
    };

    public func get_new_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance, from : T.Account, to : T.Account) : T.NewTransactionWithId {
        let timestamp : T.Timestamp = Nat64.fromNat(Int.abs(Time.now()));
        return {
            id = index;
            transaction = {
                kind = "TRANSFER";
                mint = null;
                burn = null;
                transfer = ?{
                    from = from;
                    to = to;
                    amount = amount;
                    spender = null;
                    fee = null;
                    memo = null;
                    created_at_time = ?timestamp;
                };
                approve = null;
                timestamp = timestamp;
            }
        };
    };

    public func print_old_indexed_account(indexed : T.IndexOldBalanceResult) : () {
        Debug.print("old_balance_d12: " # Nat.toText(indexed.old_balance_d12));
        Debug.print("old_balance_underflow_d12: " # Nat.toText(indexed.old_balance_underflow_d12));
        Debug.print("old_sent_acct_to_dapp_d12: " # Nat.toText(indexed.old_sent_acct_to_dapp_d12));
        Debug.print("old_sent_dapp_to_acct_d12: " # Nat.toText(indexed.old_sent_dapp_to_acct_d12));
        Debug.print("is_burner: " # Bool.toText(indexed.is_burner));
        Debug.print("old_latest_send_found: " # Bool.toText(indexed.old_latest_send_found));
        switch (indexed.old_latest_send_txid) {
            case (null) { Debug.print("old_latest_send_txid: null"); };
            case (?old_latest_send_txid) { Debug.print("old_latest_send_txid: " # Nat.toText(old_latest_send_txid)); };
        }
    };

    public func print_new_indexed_account(indexed : T.IndexNewBalanceResult) : () {
        Debug.print("new_sent_acct_to_dapp_d8: " # Nat.toText(indexed.new_sent_acct_to_dapp_d8));
        Debug.print("new_sent_dapp_to_acct_d8: " # Nat.toText(indexed.new_sent_dapp_to_acct_d8));
        Debug.print("is_seeder: " # Bool.toText(indexed.is_seeder));
        Debug.print("new_latest_send_found: " # Bool.toText(indexed.new_latest_send_found));
        switch (indexed.new_latest_send_txid) {
            case (null) { Debug.print("new_latest_send_txid: null"); };
            case (?new_latest_send_txid) { Debug.print("new_latest_send_txid: " # Nat.toText(new_latest_send_txid)); };
        }
    };

};