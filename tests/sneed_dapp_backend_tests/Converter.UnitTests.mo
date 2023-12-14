import Time "mo:base/Time";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Bool "mo:base/Bool";
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

    private func get_old_acct_to_dapp_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.OldTransaction { get_old_tx(context, index, amount, false); };

    private func get_old_dapp_to_acct_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.OldTransaction { 
        context.state.ephemeral.old_latest_sent_txids.put(context.account.owner, index);
        get_old_tx(context, index, amount, true); 
    };

    private func get_old_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance, refund : Bool) : T.OldTransaction {
        let timestamp : T.Timestamp = Nat64.fromNat(Int.abs(Time.now()));
        var from = context.account;
        var to = context.converter;
        if (refund) {
            from := context.converter;
            to := context.account;
        };
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
        : T.NewTransactionWithId { get_new_tx(context, index, amount, false); };

    private func get_new_dapp_to_acct_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance) 
        : T.NewTransactionWithId {     
        context.state.ephemeral.new_latest_sent_txids.put(context.account.owner, index);
        get_new_tx(context, index, amount, true); 
    };

    private func get_new_tx(context : T.ConverterContext, index : T.TxIndex, amount : T.Balance, refund : Bool) : T.NewTransactionWithId {
        let timestamp : T.Timestamp = Nat64.fromNat(Int.abs(Time.now()));
        var from = context.account;
        var to = context.converter;
        if (refund) {
            from := context.converter;
            to := context.account;
        };
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
            "SneedUpgrade Converter dApp Implementation Tests",
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
                )
            ]
        );
    };
};