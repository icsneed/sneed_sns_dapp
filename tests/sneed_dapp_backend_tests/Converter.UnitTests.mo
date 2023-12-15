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

import ActorSpec "../utils/ActorSpec";

module {

    private func get_context() : T.ConverterContext {

        let caller = Principal.fromText("aaaaa-aa");
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

    private func get_converter_subaccount() : T.Account {
        {
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = ?Blob.fromArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);
        };
    };

    private func get_converter_zeroes_subaccount() : T.Account {
        {
            owner = Principal.fromText("czysu-eaaaa-aaaag-qcvdq-cai");
            subaccount = ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        };
    };

    private func get_test_subaccount() : T.Account {
        {
            owner = Principal.fromText("cpi23-5qaaa-aaaag-qcs5a-cai");
            subaccount = ?Blob.fromArray([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]);
        };
    };

    private func get_test_zeroes_subaccount() : T.Account {
        {
            owner = Principal.fromText("cpi23-5qaaa-aaaag-qcs5a-cai");
            subaccount = ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        };
    };

    private func get_test_account1() : T.Account {
        {
            owner = Principal.fromText("auzum-qe7jl-z2f6l-rwp3r-wkr4f-3rcz3-l7ejm-ltcku-c45fw-w7pi4-hqe");
            subaccount = null;
        };
    };

    private func get_test_account2() : T.Account {
        {
            owner = Principal.fromText("rkf6t-7iaaa-aaaag-qco6a-cai");
            subaccount = null;
        };
    };

    private func get_old_acct_to_dapp_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.OldTransaction { get_old_tx(context, index, amount, context.account, context.converter); };

    private func get_old_dapp_to_acct_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.OldTransaction { 
        context.state.ephemeral.old_latest_sent_txids.put(context.account.owner, index);
        get_old_tx(context, index, amount, context.converter, context.account); 
    };

    private func get_old_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance, from : T.Account, to : T.Account) : T.OldTransaction {
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

    private func get_new_acct_to_dapp_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.NewTransactionWithId { get_new_tx(context, index, amount, context.account, context.converter); };

    private func get_new_dapp_to_acct_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.NewTransactionWithId {     
        context.state.ephemeral.new_latest_sent_txids.put(context.account.owner, index);
        get_new_tx(context, index, amount, context.converter, context.account); 
    };

    private func get_new_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance, from : T.Account, to : T.Account) : T.NewTransactionWithId {
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

    private func print_old_indexed_account(indexed : T.IndexOldBalanceResult) : () {
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

    private func print_new_indexed_account(indexed : T.IndexNewBalanceResult) : () {
        Debug.print("new_sent_acct_to_dapp_d8: " # Nat.toText(indexed.new_sent_acct_to_dapp_d8));
        Debug.print("new_sent_dapp_to_acct_d8: " # Nat.toText(indexed.new_sent_dapp_to_acct_d8));
        Debug.print("is_seeder: " # Bool.toText(indexed.is_seeder));
        Debug.print("new_latest_send_found: " # Bool.toText(indexed.new_latest_send_found));
        switch (indexed.new_latest_send_txid) {
            case (null) { Debug.print("new_latest_send_txid: null"); };
            case (?new_latest_send_txid) { Debug.print("new_latest_send_txid: " # Nat.toText(new_latest_send_txid)); };
        }
    };

    public func test() : async ActorSpec.Group {

        let {
            assertTrue;
            assertFalse;
            assertAllTrue;
            describe;
            it;
            skip;
            pending;
            run;
        } = ActorSpec;

        return describe(
            "SneedConverter dApp Unit Tests",
            [
                it(
                    "Indexing empty transaction array for old token should yield 0 old balance.",
                    do {

                        let context = get_context();
                        let transactions : [T.OldTransaction] = [];
                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);
                        assertAllTrue([ 
                            indexedOldAccount.old_balance_d12 == 0,
                            indexedOldAccount.old_balance_underflow_d12 == 0,                            
                            indexedOldAccount.old_sent_acct_to_dapp_d12 == 0,
                            indexedOldAccount.old_sent_dapp_to_acct_d12 == 0,
                            indexedOldAccount.is_burner == false,
                            indexedOldAccount.old_latest_send_found == false,
                            indexedOldAccount.old_latest_send_txid == null
                         ]);

                    },
                ),
                it(
                    "Indexing empty transaction array for new token should yield 0 new balance.",
                    do {

                        let context = get_context();
                        let transactions : [T.NewTransactionWithId] = [];
                        let indexedNewAccount = Converter.IndexNewBalance(context, transactions);
                        assertAllTrue([ 
                            indexedNewAccount.new_sent_acct_to_dapp_d8 == 0,
                            indexedNewAccount.new_sent_dapp_to_acct_d8 == 0,                            
                            indexedNewAccount.is_seeder == false,
                            indexedNewAccount.new_latest_send_found == false,
                            indexedNewAccount.new_latest_send_txid == null
                         ]);

                    },
                ),
                it(
                    "Indexing Account-to-dApp transaction for old token should yield amount as old balance.",
                    do {
                        let context = get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;

                        //amount is inclusive of fee for old token
                        let tx = get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx ];

                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);
                        assertAllTrue([ 
                            indexedOldAccount.old_balance_d12 == old_amount_d12,
                            indexedOldAccount.old_balance_underflow_d12 == 0,                            
                            indexedOldAccount.old_sent_acct_to_dapp_d12 == old_amount_d12,
                            indexedOldAccount.old_sent_dapp_to_acct_d12 == 0,
                            indexedOldAccount.is_burner == false,
                            indexedOldAccount.old_latest_send_found == false,
                            indexedOldAccount.old_latest_send_txid == null
                         ]);

                    },
                ),
                it(
                    "Indexing Account-to-dApp transaction for new token should yield amount as new balance.",
                    do {
                        let context = get_context();
                        let new_amount_d8 = 100000000; // 1 token

                        //amount is exclusive of fee for new token
                        let tx = get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx ];

                        let indexedNewAccount = Converter.IndexNewBalance(context, transactions);
                        assertAllTrue([
                            indexedNewAccount.new_sent_acct_to_dapp_d8 == new_amount_d8,
                            indexedNewAccount.new_sent_dapp_to_acct_d8 == 0,                            
                            indexedNewAccount.is_seeder == false,
                            indexedNewAccount.new_latest_send_found == false,
                            indexedNewAccount.new_latest_send_txid == null
                         ]);

                    },
                ),
                it(
                    "Indexing two Account-to-dApp transactions for old token should yield amount + amount2 as old balance.",
                    do {
                        let context = get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_total_d12 = old_amount_d12 + old_amount2_d12;

                        //amount is inclusive of fee for old token
                        let tx = get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let tx2 = get_old_acct_to_dapp_tx(context, 105, old_amount2_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx, tx2 ];

                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);
                        assertAllTrue([ 
                            indexedOldAccount.old_balance_d12 == old_total_d12,
                            indexedOldAccount.old_balance_underflow_d12 == 0,                            
                            indexedOldAccount.old_sent_acct_to_dapp_d12 == old_total_d12,
                            indexedOldAccount.old_sent_dapp_to_acct_d12 == 0,
                            indexedOldAccount.is_burner == false,
                            indexedOldAccount.old_latest_send_found == false,
                            indexedOldAccount.old_latest_send_txid == null
                         ]);

                    },
                ),
                it(
                    "Indexing two Account-to-dApp transactions for new token should yield amount + amount2 as new balance.",
                    do {
                        let context = get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_total_d8 = new_amount_d8 + new_amount2_d8;

                        //amount is exclusive of fee for new token
                        let tx = get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let tx2 = get_new_acct_to_dapp_tx(context, 105, new_amount2_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx, tx2 ];

                        let indexedNewAccount = Converter.IndexNewBalance(context, transactions);
                        assertAllTrue([
                            indexedNewAccount.new_sent_acct_to_dapp_d8 == new_total_d8,
                            indexedNewAccount.new_sent_dapp_to_acct_d8 == 0,                            
                            indexedNewAccount.is_seeder == false,
                            indexedNewAccount.new_latest_send_found == false,
                            indexedNewAccount.new_latest_send_txid == null
                         ]);

                    },
                ),
                it(
                    "Indexing two Account-to-dApp and one dApp-to-Account transaction for old token should yield amount + amount2 - amount3 - old_fee as old balance.",
                    do {
                        let context = get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_amount3_d12 = 500000000000; // 0.5 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_acct_sent_total_d12 = old_amount_d12 + old_amount2_d12;
                        let old_total_d12 = old_acct_sent_total_d12 - old_amount3_d12 - old_fee_d12; // 2.4999 tokens

                        //amount is inclusive of fee for old token
                        let tx = get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let tx2 = get_old_acct_to_dapp_tx(context, 105, old_amount2_d12 + old_fee_d12);
                        let tx3 = get_old_dapp_to_acct_tx(context, 125, old_amount3_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx, tx2, tx3 ];

                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);
                        assertAllTrue([ 
                            indexedOldAccount.old_balance_d12 == old_total_d12,
                            indexedOldAccount.old_balance_underflow_d12 == 0,                            
                            indexedOldAccount.old_sent_acct_to_dapp_d12 == old_acct_sent_total_d12,
                            indexedOldAccount.old_sent_dapp_to_acct_d12 == old_amount3_d12 + old_fee_d12,
                            indexedOldAccount.is_burner == false,
                            indexedOldAccount.old_latest_send_found == true,
                            indexedOldAccount.old_latest_send_txid == ?125
                         ]);

                    },
                ),
                it(
                    "Indexing two Account-to-dApp and one dApp-to-Account transaction for new token should yield amount + amount2 - amount3 - new_fee as new balance.",
                    do {
                        let context = get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_amount3_d8 = 50000000; // 0.5 tokens
                        let new_acct_sent_total_d8 = new_amount_d8 + new_amount2_d8;
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;
                        let new_total_d8 = new_acct_sent_total_d8 - new_amount3_d8 - new_fee_d8; // 2.4999 tokens

                        //amount is exclusive of fee for new token
                        let tx = get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let tx2 = get_new_acct_to_dapp_tx(context, 105, new_amount2_d8);
                        let tx3 = get_new_dapp_to_acct_tx(context, 125, new_amount3_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx, tx2, tx3 ];

                        let indexedNewAccount = Converter.IndexNewBalance(context, transactions);
                        assertAllTrue([
                            indexedNewAccount.new_sent_acct_to_dapp_d8 == new_acct_sent_total_d8,
                            indexedNewAccount.new_sent_dapp_to_acct_d8 == new_amount3_d8 + new_fee_d8,                            
                            indexedNewAccount.is_seeder == false,
                            indexedNewAccount.new_latest_send_found == true,
                            indexedNewAccount.new_latest_send_txid == ?125,

                            // new balance
                            indexedNewAccount.new_sent_acct_to_dapp_d8 - indexedNewAccount.new_sent_dapp_to_acct_d8 == new_total_d8
                         ]);

                    },
                ),
                it(
                    "Indexing two Account-to-dApp and one bigger dApp-to-Account transaction for old token should yield zero balance and track the underflow.",
                    do {
                        let context = get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_amount3_d12 = 5000000000000; // 5 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_acct_sent_total_d12 = old_amount_d12 + old_amount2_d12;
                        let old_underflow_d12 = old_amount3_d12 + old_fee_d12 - old_acct_sent_total_d12; // 2.0001 tokens

                        //amount is inclusive of fee for old token
                        let tx = get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let tx2 = get_old_acct_to_dapp_tx(context, 105, old_amount2_d12 + old_fee_d12);
                        let tx3 = get_old_dapp_to_acct_tx(context, 125, old_amount3_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx, tx2, tx3 ];

                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);                        
                        assertAllTrue([ 
                            indexedOldAccount.old_balance_d12 == 0,
                            indexedOldAccount.old_balance_underflow_d12 == old_underflow_d12,               // 2000100000000                          
                            indexedOldAccount.old_sent_acct_to_dapp_d12 == old_acct_sent_total_d12,         // 3000000000000
                            indexedOldAccount.old_sent_dapp_to_acct_d12 == old_amount3_d12 + old_fee_d12,   // 5000100000000
                            indexedOldAccount.is_burner == false,
                            indexedOldAccount.old_latest_send_found == true,
                            indexedOldAccount.old_latest_send_txid == ?125
                         ]);
                    },
                ),
                it(
                    "Indexing two Account-to-dApp and one bigger dApp-to-Account transaction for new token should yield larger new_sent_dapp_to_acct_d8 than new_sent_acct_to_dapp_d8.",
                    do {
                        let context = get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_amount3_d8 = 500000000; // 5 tokens
                        let new_acct_sent_total_d8 = new_amount_d8 + new_amount2_d8;
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;

                        //amount is exclusive of fee for new token
                        let tx = get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let tx2 = get_new_acct_to_dapp_tx(context, 105, new_amount2_d8);
                        let tx3 = get_new_dapp_to_acct_tx(context, 125, new_amount3_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx, tx2, tx3 ];

                        let indexedNewAccount = Converter.IndexNewBalance(context, transactions);
                        assertAllTrue([
                            indexedNewAccount.new_sent_acct_to_dapp_d8 == new_acct_sent_total_d8,
                            indexedNewAccount.new_sent_dapp_to_acct_d8 == new_amount3_d8 + new_fee_d8,                            
                            indexedNewAccount.is_seeder == false,
                            indexedNewAccount.new_latest_send_found == true,
                            indexedNewAccount.new_latest_send_txid == ?125,

                            // underflow
                            indexedNewAccount.new_sent_dapp_to_acct_d8 > indexedNewAccount.new_sent_acct_to_dapp_d8
                         ]);
                    },
                ),
                it(
                    "Indexing dApp-to-Account transaction for old token should yield zero balance and track the underflow (amount + old_fee).",
                    do {
                        let context = get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;

                        //amount is inclusive of fee for old token
                        let tx = get_old_dapp_to_acct_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx ];

                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);
                        assertAllTrue([ 
                            indexedOldAccount.old_balance_d12 == 0,
                            indexedOldAccount.old_balance_underflow_d12 == old_amount_d12 + old_fee_d12,
                            indexedOldAccount.old_sent_acct_to_dapp_d12 == 0,
                            indexedOldAccount.old_sent_dapp_to_acct_d12 == old_amount_d12 + old_fee_d12,
                            indexedOldAccount.is_burner == false,
                            indexedOldAccount.old_latest_send_found == true,
                            indexedOldAccount.old_latest_send_txid == ?100
                         ]);

                    },
                ),
                it(
                    "Indexing dApp-to-Account transaction for new token should yield amount + new_fee as new_sent_dapp_to_acct_d8 and 0 as new_sent_acct_to_dapp_d8.",
                    do {
                        let context = get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;

                        //amount is exclusive of fee for new token
                        let tx = get_new_dapp_to_acct_tx(context, 100, new_amount_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx ];

                        let indexedNewAccount = Converter.IndexNewBalance(context, transactions);
                        assertAllTrue([
                            indexedNewAccount.new_sent_acct_to_dapp_d8 == 0,
                            indexedNewAccount.new_sent_dapp_to_acct_d8 == new_amount_d8 + new_fee_d8,                            
                            indexedNewAccount.is_seeder == false,
                            indexedNewAccount.new_latest_send_found == true,
                            indexedNewAccount.new_latest_send_txid == ?100
                         ]);

                    },
                ),
                it(
                    "Indexing huge Account-to-dApp transaction for old token should result in account being tagged with is_burner=true.",
                    do {
                        let context = get_context();
                        let old_amount_d12 = 1001000000000000; // 1001 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;

                        //amount is inclusive of fee for old token
                        let tx = get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx ];

                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);
                        print_old_indexed_account(indexedOldAccount);
                        assertAllTrue([ 
                            indexedOldAccount.old_balance_d12 == old_amount_d12,
                            indexedOldAccount.old_balance_underflow_d12 == 0,
                            indexedOldAccount.old_sent_acct_to_dapp_d12 == old_amount_d12,
                            indexedOldAccount.old_sent_dapp_to_acct_d12 == 0,
                            indexedOldAccount.is_burner == true,
                            indexedOldAccount.old_latest_send_found == false,
                            indexedOldAccount.old_latest_send_txid == null
                         ]);

                    },
                ),
                it(
                    "Indexing huge Account-to-dApp transaction for new token should result in account being tagged with is_seeder=true.",
                    do {
                        let context = get_context();
                        let new_amount_d8 = 100100000000; // 1001 tokens
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;

                        //amount is exclusive of fee for new token
                        let tx = get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx ];

                        let indexedNewAccount = Converter.IndexNewBalance(context, transactions);
                        assertAllTrue([
                            indexedNewAccount.new_sent_acct_to_dapp_d8 == new_amount_d8,
                            indexedNewAccount.new_sent_dapp_to_acct_d8 == 0,                            
                            indexedNewAccount.is_seeder == true,
                            indexedNewAccount.new_latest_send_found == false,
                            indexedNewAccount.new_latest_send_txid == null
                         ]);

                    },
                ),
                it(
                    "Transactions for the old token that are not between the dApp and the Account should be ignored.",
                    do {
                        let context = get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_amount3_d12 = 500000000000; // 0.5 tokens
                        let old_amount4_d12 = 1234567899999; 
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_acct_sent_total_d12 = old_amount_d12 + old_amount2_d12;
                        let old_total_d12 = old_acct_sent_total_d12 - old_amount3_d12 - old_fee_d12; // 2.4999 tokens

                        //amount is inclusive of fee for old token
                        let tx = get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let tx2 = get_old_acct_to_dapp_tx(context, 105, old_amount2_d12 + old_fee_d12);
                        let tx3 = get_old_dapp_to_acct_tx(context, 125, old_amount3_d12 + old_fee_d12);

                        let tx_ignore = get_old_tx(context, 90, old_amount4_d12, context.converter, get_test_account1());
                        let tx_ignore2 = get_old_tx(context, 95, old_amount4_d12, get_test_account1(), context.converter);
                        let tx_ignore3 = get_old_tx(context, 103, old_amount4_d12, context.account, get_test_account1());
                        let tx_ignore4 = get_old_tx(context, 110, old_amount4_d12, get_test_account1(), context.account);
                        let tx_ignore5 = get_old_tx(context, 115, old_amount4_d12, get_test_account1(), get_test_account2());

                        // Different subaccounts should also be ignored
                        let tx_ignore6 = get_old_tx(context, 145, old_amount4_d12, get_test_subaccount(), context.converter);
                        let tx_ignore7 = get_old_tx(context, 155, old_amount4_d12, get_converter_subaccount(), context.account);

                        let transactions : [T.OldTransaction] = [ tx_ignore, tx_ignore2, tx, tx_ignore3, tx2, tx_ignore4, tx_ignore5, tx3, tx_ignore6, tx_ignore7 ];

                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);
                        assertAllTrue([ 
                            indexedOldAccount.old_balance_d12 == old_total_d12,
                            indexedOldAccount.old_balance_underflow_d12 == 0,                            
                            indexedOldAccount.old_sent_acct_to_dapp_d12 == old_acct_sent_total_d12,
                            indexedOldAccount.old_sent_dapp_to_acct_d12 == old_amount3_d12 + old_fee_d12,
                            indexedOldAccount.is_burner == false,
                            indexedOldAccount.old_latest_send_found == true,
                            indexedOldAccount.old_latest_send_txid == ?125
                         ]);

                    },
                ),
                it(
                    "Transactions for the new token that are not between the dApp and the Account should be ignored.",
                    do {
                        let context = get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_amount3_d8 = 50000000; // 0.5 tokens
                        let old_amount4_d12 = 1234567899999; 
                        let new_acct_sent_total_d8 = new_amount_d8 + new_amount2_d8;
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;
                        let new_total_d8 = new_acct_sent_total_d8 - new_amount3_d8 - new_fee_d8; // 2.4999 tokens

                        //amount is exclusive of fee for new token
                        let tx = get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let tx2 = get_new_acct_to_dapp_tx(context, 105, new_amount2_d8);
                        let tx3 = get_new_dapp_to_acct_tx(context, 125, new_amount3_d8);

                        let tx_ignore = get_new_tx(context, 90, old_amount4_d12, context.converter, get_test_account1());
                        let tx_ignore2 = get_new_tx(context, 95, old_amount4_d12, get_test_account1(), context.converter);
                        let tx_ignore3 = get_new_tx(context, 103, old_amount4_d12, context.account, get_test_account1());
                        let tx_ignore4 = get_new_tx(context, 110, old_amount4_d12, get_test_account1(), context.account);
                        let tx_ignore5 = get_new_tx(context, 115, old_amount4_d12, get_test_account1(), get_test_account2());

                        // Different subaccounts should also be ignored
                        let tx_ignore6 = get_new_tx(context, 145, old_amount4_d12, get_test_subaccount(), context.converter);
                        let tx_ignore7 = get_new_tx(context, 155, old_amount4_d12, get_converter_subaccount(), context.account);

                        let transactions : [T.NewTransactionWithId] = [ tx_ignore, tx_ignore2, tx, tx_ignore3, tx2, tx_ignore4, tx_ignore5, tx3, tx_ignore6, tx_ignore7 ];

                        let indexedNewAccount = Converter.IndexNewBalance(context, transactions);
                        assertAllTrue([
                            indexedNewAccount.new_sent_acct_to_dapp_d8 == new_acct_sent_total_d8,
                            indexedNewAccount.new_sent_dapp_to_acct_d8 == new_amount3_d8 + new_fee_d8,                            
                            indexedNewAccount.is_seeder == false,
                            indexedNewAccount.new_latest_send_found == true,
                            indexedNewAccount.new_latest_send_txid == ?125,

                            // new balance
                            indexedNewAccount.new_sent_acct_to_dapp_d8 - indexedNewAccount.new_sent_dapp_to_acct_d8 == new_total_d8
                         ]);

                    },
                ),
                it(
                    "Accounts with subaccount null and subaccount all zeros should match when indexing old tokens.",
                    do {
                        let context = get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_amount3_d12 = 500000000000; // 0.5 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_acct_sent_total_d12 = old_amount_d12 + old_amount2_d12;
                        let old_total_d12 = old_acct_sent_total_d12 - old_amount3_d12 - old_fee_d12; // 2.4999 tokens

                        //amount is inclusive of fee for old token
                        let tx = get_old_tx(context, 100, old_amount_d12 + old_fee_d12, context.account, get_converter_zeroes_subaccount());
                        let tx2 = get_old_tx(context, 105, old_amount2_d12 + old_fee_d12, get_test_zeroes_subaccount(), context.converter);
                        let tx3 = get_old_dapp_to_acct_tx(context, 125, old_amount3_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx, tx2, tx3 ];

                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);
                        assertAllTrue([ 
                            indexedOldAccount.old_balance_d12 == old_total_d12,
                            indexedOldAccount.old_balance_underflow_d12 == 0,                            
                            indexedOldAccount.old_sent_acct_to_dapp_d12 == old_acct_sent_total_d12,
                            indexedOldAccount.old_sent_dapp_to_acct_d12 == old_amount3_d12 + old_fee_d12,
                            indexedOldAccount.is_burner == false,
                            indexedOldAccount.old_latest_send_found == true,
                            indexedOldAccount.old_latest_send_txid == ?125
                         ]);

                    },
                ),
                it(
                    "Accounts with subaccount null and subaccount all zeros should match when indexing new tokens.",
                    do {
                        let context = get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_amount3_d8 = 50000000; // 0.5 tokens
                        let new_acct_sent_total_d8 = new_amount_d8 + new_amount2_d8;
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;
                        let new_total_d8 = new_acct_sent_total_d8 - new_amount3_d8 - new_fee_d8; // 2.4999 tokens

                        //amount is exclusive of fee for new token
                        let tx = get_new_tx(context, 100, new_amount_d8, context.account, get_converter_zeroes_subaccount());
                        let tx2 = get_new_tx(context, 105, new_amount2_d8, get_test_zeroes_subaccount(), context.converter);
                        let tx3 = get_new_dapp_to_acct_tx(context, 125, new_amount3_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx, tx2, tx3 ];

                        let indexedNewAccount = Converter.IndexNewBalance(context, transactions);
                        print_new_indexed_account(indexedNewAccount);
                        assertAllTrue([
                            indexedNewAccount.new_sent_acct_to_dapp_d8 == new_acct_sent_total_d8,
                            indexedNewAccount.new_sent_dapp_to_acct_d8 == new_amount3_d8 + new_fee_d8,                            
                            indexedNewAccount.is_seeder == false,
                            indexedNewAccount.new_latest_send_found == true,
                            indexedNewAccount.new_latest_send_txid == ?125,

                            // new balance
                            indexedNewAccount.new_sent_acct_to_dapp_d8 - indexedNewAccount.new_sent_dapp_to_acct_d8 == new_total_d8
                         ]);

                    },
                ),
                it(
                    "Comparing accounts should yield match only when both principals and subaccounts match (all zero and null subaccounts should match).",
                    do {
                        let context = get_context();
                        assertAllTrue([ 
                            Converter.CompareAccounts(context.account, get_test_zeroes_subaccount()), // same principals, subaccounts are null and [0,0..0]
                            Converter.CompareAccounts(get_test_zeroes_subaccount(), context.account), // same principals, subaccounts are [0,0..0] and null
                            Converter.CompareAccounts(context.account, context.account), // same principals, subaccounts are both null
                            Converter.CompareAccounts(get_test_zeroes_subaccount(), get_test_zeroes_subaccount()), // same principals, subaccounts are both [0,0..0]
                            not Converter.CompareAccounts(context.account, context.converter), // different principals (same subaccount = null)
                            not Converter.CompareAccounts(get_test_zeroes_subaccount(), get_converter_zeroes_subaccount()), // different principals, same subaccounts ([0,0..0])
                            not Converter.CompareAccounts(get_test_subaccount(), get_converter_subaccount()), // different principals, same subaccounts ([1,2..32])
                            not Converter.CompareAccounts(context.account, get_test_subaccount()), // same principals, different subaccounts (null and [1,2..32])
                            not Converter.CompareAccounts(get_test_subaccount(), context.account), // same principals, different subaccounts ([1,2..32] and null)
                            not Converter.CompareAccounts(get_test_zeroes_subaccount(), get_test_subaccount()), // same principals, different subaccounts ([0,0..0] and [1,2..32])
                            not Converter.CompareAccounts(get_test_subaccount(), get_test_zeroes_subaccount()) // same principals, different subaccounts ([1,2..32] and [0.0..0])
                         ]);
                    },
                ),
                it(
                    "Cooldown should be last for the time specified in nanoseconds in settings.cooldown_ns, then removed from the map when expired.",
                    do {
                        let context = get_context();

                        // Extract cooldowns
                        let cooldowns = context.state.ephemeral.cooldowns;

                        var result = assertAllTrue([ 
                            not Converter.OnCooldown(context, context.account.owner),
                            not Converter.OnCooldown(context, context.converter.owner),
                            Converter.CooldownSince(context, context.account.owner) == 0,
                            Converter.CooldownSince(context, context.converter.owner) == 0,
                            Converter.CooldownRemaining(context, context.account.owner) == 0,
                            Converter.CooldownRemaining(context, context.converter.owner) == 0,
                            cooldowns.get(context.account.owner) == null,
                            cooldowns.get(context.converter.owner) == null
                        ]);

                        if (not result) { Debug.trap("Cooldown map was not clear at start."); };

                        cooldowns.put(context.account.owner, Time.now());

                        result := assertAllTrue([ 
                            Converter.OnCooldown(context, context.account.owner),
                            not Converter.OnCooldown(context, context.converter.owner),
                            Converter.CooldownSince(context, context.account.owner) > 0,
                            Converter.CooldownSince(context, context.converter.owner) == 0,
                            Converter.CooldownRemaining(context, context.account.owner) > 0,
                            Converter.CooldownRemaining(context, context.converter.owner) == 0,
                            cooldowns.get(context.account.owner) != null,
                            cooldowns.get(context.converter.owner) == null
                        ]);

                        if (not result) { Debug.trap("Cooldown map was not filled."); };

                        cooldowns.put(context.account.owner, Time.now() - (context.state.persistent.settings.cooldown_ns + 1));

                        assertAllTrue([ 
                            not Converter.OnCooldown(context, context.account.owner),
                            not Converter.OnCooldown(context, context.converter.owner),
                            Converter.CooldownSince(context, context.account.owner) == 0,
                            Converter.CooldownSince(context, context.converter.owner) == 0,
                            Converter.CooldownRemaining(context, context.account.owner) == 0,
                            Converter.CooldownRemaining(context, context.converter.owner) == 0,
                            cooldowns.get(context.account.owner) == null,
                            cooldowns.get(context.converter.owner) == null
                        ]);
                    },
                ),
                // Taken from https://github.com/NatLabs/icrc1
                it(
                    "should return false for invalid subaccount (length < 32)",
                    do {
                        let context = get_context();

                        var len = 0;
                        var is_valid = false;

                        label _loop while (len < 32){
                            let account = {
                                owner = context.account.owner;
                                subaccount = ?Blob.fromArray(Array.tabulate(len, Nat8.fromNat));
                            };

                            is_valid := is_valid or Converter.ValidateAccount(account) 
                                        or Converter.ValidateSubaccount(account.subaccount);

                            if (is_valid) {
                                break _loop;
                            };

                            len += 1;
                        };
                        
                        not is_valid;
                    }
                )

                // TODO: Test cooldowns
            ]
        );
    };
};