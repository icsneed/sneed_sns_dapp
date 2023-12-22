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
import TestUtil "../utils/TestUtil";

module {

    public func test(controller : Principal) : async ActorSpec.Group {

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

                        let context = TestUtil.get_context();
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

                        let context = TestUtil.get_context();
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
                        let context = TestUtil.get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;

                        //amount is inclusive of fee for old token
                        let tx = TestUtil.get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
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
                        let context = TestUtil.get_context();
                        let new_amount_d8 = 100000000; // 1 token

                        //amount is exclusive of fee for new token
                        let tx = TestUtil.get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
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
                        let context = TestUtil.get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_total_d12 = old_amount_d12 + old_amount2_d12;

                        //amount is inclusive of fee for old token
                        let tx = TestUtil.get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let tx2 = TestUtil.get_old_acct_to_dapp_tx(context, 105, old_amount2_d12 + old_fee_d12);
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
                        let context = TestUtil.get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_total_d8 = new_amount_d8 + new_amount2_d8;

                        //amount is exclusive of fee for new token
                        let tx = TestUtil.get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let tx2 = TestUtil.get_new_acct_to_dapp_tx(context, 105, new_amount2_d8);
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
                        let context = TestUtil.get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_amount3_d12 = 500000000000; // 0.5 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_acct_sent_total_d12 = old_amount_d12 + old_amount2_d12;
                        let old_total_d12 = old_acct_sent_total_d12 - old_amount3_d12 - old_fee_d12; // 2.4999 tokens

                        //amount is inclusive of fee for old token
                        let tx = TestUtil.get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let tx2 = TestUtil.get_old_acct_to_dapp_tx(context, 105, old_amount2_d12 + old_fee_d12);
                        let tx3 = TestUtil.get_old_dapp_to_acct_tx(context, 125, old_amount3_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx, tx2, tx3 ];
                        TestUtil.log_last_seen_old(context, 125);

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
                        let context = TestUtil.get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_amount3_d8 = 50000000; // 0.5 tokens
                        let new_acct_sent_total_d8 = new_amount_d8 + new_amount2_d8;
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;
                        let new_total_d8 = new_acct_sent_total_d8 - new_amount3_d8 - new_fee_d8; // 2.4999 tokens

                        //amount is exclusive of fee for new token
                        let tx = TestUtil.get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let tx2 = TestUtil.get_new_acct_to_dapp_tx(context, 105, new_amount2_d8);
                        let tx3 = TestUtil.get_new_dapp_to_acct_tx(context, 125, new_amount3_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx, tx2, tx3 ];
                        TestUtil.log_last_seen_new(context, 125);

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
                        let context = TestUtil.get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_amount3_d12 = 5000000000000; // 5 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_acct_sent_total_d12 = old_amount_d12 + old_amount2_d12;
                        let old_underflow_d12 = old_amount3_d12 + old_fee_d12 - old_acct_sent_total_d12; // 2.0001 tokens

                        //amount is inclusive of fee for old token
                        let tx = TestUtil.get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let tx2 = TestUtil.get_old_acct_to_dapp_tx(context, 105, old_amount2_d12 + old_fee_d12);
                        let tx3 = TestUtil.get_old_dapp_to_acct_tx(context, 125, old_amount3_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx, tx2, tx3 ];
                        TestUtil.log_last_seen_old(context, 125);

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
                        let context = TestUtil.get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_amount3_d8 = 500000000; // 5 tokens
                        let new_acct_sent_total_d8 = new_amount_d8 + new_amount2_d8;
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;

                        //amount is exclusive of fee for new token
                        let tx = TestUtil.get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let tx2 = TestUtil.get_new_acct_to_dapp_tx(context, 105, new_amount2_d8);
                        let tx3 = TestUtil.get_new_dapp_to_acct_tx(context, 125, new_amount3_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx, tx2, tx3 ];
                        TestUtil.log_last_seen_new(context, 125);

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
                        let context = TestUtil.get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;

                        //amount is inclusive of fee for old token
                        let tx = TestUtil.get_old_dapp_to_acct_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx ];
                        TestUtil.log_last_seen_old(context, 100);

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
                        let context = TestUtil.get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;

                        //amount is exclusive of fee for new token
                        let tx = TestUtil.get_new_dapp_to_acct_tx(context, 100, new_amount_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx ];
                        TestUtil.log_last_seen_new(context, 100);

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
                        let context = TestUtil.get_context();
                        let old_amount_d12 = 1001000000000000; // 1001 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;

                        //amount is inclusive of fee for old token
                        let tx = TestUtil.get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx ];

                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);
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
                        let context = TestUtil.get_context();
                        let new_amount_d8 = 100100000000; // 1001 tokens
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;

                        //amount is exclusive of fee for new token
                        let tx = TestUtil.get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
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
                        let context = TestUtil.get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_amount3_d12 = 500000000000; // 0.5 tokens
                        let old_amount4_d12 = 1234567899999; 
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_acct_sent_total_d12 = old_amount_d12 + old_amount2_d12;
                        let old_total_d12 = old_acct_sent_total_d12 - old_amount3_d12 - old_fee_d12; // 2.4999 tokens

                        //amount is inclusive of fee for old token
                        let tx = TestUtil.get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let tx2 = TestUtil.get_old_acct_to_dapp_tx(context, 105, old_amount2_d12 + old_fee_d12);
                        let tx3 = TestUtil.get_old_dapp_to_acct_tx(context, 125, old_amount3_d12 + old_fee_d12);

                        let tx_ignore = TestUtil.get_old_tx(90, old_amount4_d12, context.converter, TestUtil.get_test_account(1));
                        let tx_ignore2 = TestUtil.get_old_tx(95, old_amount4_d12, TestUtil.get_test_account(1), context.converter);
                        let tx_ignore3 = TestUtil.get_old_tx(103, old_amount4_d12, context.account, TestUtil.get_test_account(1));
                        let tx_ignore4 = TestUtil.get_old_tx(110, old_amount4_d12, TestUtil.get_test_account(1), context.account);
                        let tx_ignore5 = TestUtil.get_old_tx(115, old_amount4_d12, TestUtil.get_test_account(1), TestUtil.get_test_account(2));

                        // Different subaccounts should also be ignored
                        let tx_ignore6 = TestUtil.get_old_tx(145, old_amount4_d12, TestUtil.get_test_subaccount(), context.converter);
                        let tx_ignore7 = TestUtil.get_old_tx(155, old_amount4_d12, TestUtil.get_converter_subaccount(), context.account);

                        let transactions : [T.OldTransaction] = [ tx_ignore, tx_ignore2, tx, tx_ignore3, tx2, tx_ignore4, tx_ignore5, tx3, tx_ignore6, tx_ignore7 ];
                        TestUtil.log_last_seen_old(context, 125);

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
                        let context = TestUtil.get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_amount3_d8 = 50000000; // 0.5 tokens
                        let old_amount4_d12 = 1234567899999; 
                        let new_acct_sent_total_d8 = new_amount_d8 + new_amount2_d8;
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;
                        let new_total_d8 = new_acct_sent_total_d8 - new_amount3_d8 - new_fee_d8; // 2.4999 tokens

                        //amount is exclusive of fee for new token
                        let tx = TestUtil.get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let tx2 = TestUtil.get_new_acct_to_dapp_tx(context, 105, new_amount2_d8);
                        let tx3 = TestUtil.get_new_dapp_to_acct_tx(context, 125, new_amount3_d8);

                        let tx_ignore = TestUtil.get_new_tx(90, old_amount4_d12, context.converter, TestUtil.get_test_account(1));
                        let tx_ignore2 = TestUtil.get_new_tx(95, old_amount4_d12, TestUtil.get_test_account(1), context.converter);
                        let tx_ignore3 = TestUtil.get_new_tx(103, old_amount4_d12, context.account, TestUtil.get_test_account(1));
                        let tx_ignore4 = TestUtil.get_new_tx(110, old_amount4_d12, TestUtil.get_test_account(1), context.account);
                        let tx_ignore5 = TestUtil.get_new_tx(115, old_amount4_d12, TestUtil.get_test_account(1), TestUtil.get_test_account(2));

                        // Different subaccounts should also be ignored
                        let tx_ignore6 = TestUtil.get_new_tx(145, old_amount4_d12, TestUtil.get_test_subaccount(), context.converter);
                        let tx_ignore7 = TestUtil.get_new_tx(155, old_amount4_d12, TestUtil.get_converter_subaccount(), context.account);

                        let transactions : [T.NewTransactionWithId] = [ tx_ignore, tx_ignore2, tx, tx_ignore3, tx2, tx_ignore4, tx_ignore5, tx3, tx_ignore6, tx_ignore7 ];
                        TestUtil.log_last_seen_new(context, 125);

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
                    "When latest seen old transaction index is not in list from indexer, old_latest_send_found should return false and the missing tx index should be in old_latest_send_txid.",
                    do {
                        let context = TestUtil.get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_amount3_d12 = 500000000000; // 0.5 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_acct_sent_total_d12 = old_amount_d12 + old_amount2_d12;
                        let old_total_d12 = old_acct_sent_total_d12 - old_amount3_d12 - old_fee_d12; // 2.4999 tokens

                        //amount is inclusive of fee for old token
                        let tx = TestUtil.get_old_acct_to_dapp_tx(context, 100, old_amount_d12 + old_fee_d12);
                        let tx2 = TestUtil.get_old_acct_to_dapp_tx(context, 105, old_amount2_d12 + old_fee_d12);
                        let tx3 = TestUtil.get_old_dapp_to_acct_tx(context, 125, old_amount3_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx, tx2, tx3 ];
                        TestUtil.log_last_seen_old(context, 525);

                        let indexedOldAccount = Converter.IndexOldBalance(context, transactions);
                        TestUtil.print_old_indexed_account(indexedOldAccount);
                        assertAllTrue([ 
                            indexedOldAccount.old_balance_d12 == old_total_d12,
                            indexedOldAccount.old_balance_underflow_d12 == 0,                            
                            indexedOldAccount.old_sent_acct_to_dapp_d12 == old_acct_sent_total_d12,
                            indexedOldAccount.old_sent_dapp_to_acct_d12 == old_amount3_d12 + old_fee_d12,
                            indexedOldAccount.is_burner == false,

                            // Note, while this is false and there is a value in old_latest_send_txid,
                            // the dApp should not allow conversions for the account! The user will
                            // have to try again later, giving the indexer a chance to catch up.
                            indexedOldAccount.old_latest_send_found == false, 
                            indexedOldAccount.old_latest_send_txid == ?525
                         ]);

                    },
                ),
                it(
                    "When latest seen new transaction index is not in list from indexer, new_latest_send_found should return false and the missing tx index should be in new_latest_send_txid.",
                    do {
                        let context = TestUtil.get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_amount3_d8 = 50000000; // 0.5 tokens
                        let new_acct_sent_total_d8 = new_amount_d8 + new_amount2_d8;
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;
                        let new_total_d8 = new_acct_sent_total_d8 - new_amount3_d8 - new_fee_d8; // 2.4999 tokens

                        //amount is exclusive of fee for new token
                        let tx = TestUtil.get_new_acct_to_dapp_tx(context, 100, new_amount_d8);
                        let tx2 = TestUtil.get_new_acct_to_dapp_tx(context, 105, new_amount2_d8);
                        let tx3 = TestUtil.get_new_dapp_to_acct_tx(context, 125, new_amount3_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx, tx2, tx3 ];
                        TestUtil.log_last_seen_new(context, 525);

                        let indexedNewAccount = Converter.IndexNewBalance(context, transactions);
                        assertAllTrue([
                            indexedNewAccount.new_sent_acct_to_dapp_d8 == new_acct_sent_total_d8,
                            indexedNewAccount.new_sent_dapp_to_acct_d8 == new_amount3_d8 + new_fee_d8,                            
                            indexedNewAccount.is_seeder == false,

                            // Note, while this is false and there is a value in new_latest_send_txid,
                            // the dApp should not allow conversions for the account! The user will
                            // have to try again later, giving the indexer a chance to catch up.
                            indexedNewAccount.new_latest_send_found == false,
                            indexedNewAccount.new_latest_send_txid == ?525,
                         ]);

                    },
                ),
                it(
                    "Accounts with subaccount null and subaccount all zeros should match when indexing old tokens.",
                    do {
                        let context = TestUtil.get_context();
                        let old_amount_d12 = 1000000000000; // 1 token
                        let old_amount2_d12 = 2000000000000; // 2 tokens
                        let old_amount3_d12 = 500000000000; // 0.5 tokens
                        let old_fee_d12 = context.state.persistent.settings.old_fee_d12;
                        let old_acct_sent_total_d12 = old_amount_d12 + old_amount2_d12;
                        let old_total_d12 = old_acct_sent_total_d12 - old_amount3_d12 - old_fee_d12; // 2.4999 tokens

                        //amount is inclusive of fee for old token
                        let tx = TestUtil.get_old_tx(100, old_amount_d12 + old_fee_d12, context.account, TestUtil.get_converter_zeroes_subaccount());
                        let tx2 = TestUtil.get_old_tx(105, old_amount2_d12 + old_fee_d12, TestUtil.get_test_zeroes_subaccount(), context.converter);
                        let tx3 = TestUtil.get_old_dapp_to_acct_tx(context, 125, old_amount3_d12 + old_fee_d12);
                        let transactions : [T.OldTransaction] = [ tx, tx2, tx3 ];
                        TestUtil.log_last_seen_old(context, 125);

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
                        let context = TestUtil.get_context();
                        let new_amount_d8 = 100000000; // 1 token
                        let new_amount2_d8 = 200000000; // 2 tokens
                        let new_amount3_d8 = 50000000; // 0.5 tokens
                        let new_acct_sent_total_d8 = new_amount_d8 + new_amount2_d8;
                        let new_fee_d8 = context.state.persistent.settings.new_fee_d8;
                        let new_total_d8 = new_acct_sent_total_d8 - new_amount3_d8 - new_fee_d8; // 2.4999 tokens

                        //amount is exclusive of fee for new token
                        let tx = TestUtil.get_new_tx(100, new_amount_d8, context.account, TestUtil.get_converter_zeroes_subaccount());
                        let tx2 = TestUtil.get_new_tx(105, new_amount2_d8, TestUtil.get_test_zeroes_subaccount(), context.converter);
                        let tx3 = TestUtil.get_new_dapp_to_acct_tx(context, 125, new_amount3_d8);
                        let transactions : [T.NewTransactionWithId] = [ tx, tx2, tx3 ];
                        TestUtil.log_last_seen_new(context, 125);

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
                    "Comparing accounts should yield match only when both principals and subaccounts match (all zero and null subaccounts should match).",
                    do {
                        let context = TestUtil.get_context();
                        assertAllTrue([ 
                            Converter.CompareAccounts(context.account, TestUtil.get_test_zeroes_subaccount()), // same principals, subaccounts are null and [0,0..0]
                            Converter.CompareAccounts(TestUtil.get_test_zeroes_subaccount(), context.account), // same principals, subaccounts are [0,0..0] and null
                            Converter.CompareAccounts(context.account, context.account), // same principals, subaccounts are both null
                            Converter.CompareAccounts(TestUtil.get_test_zeroes_subaccount(), TestUtil.get_test_zeroes_subaccount()), // same principals, subaccounts are both [0,0..0]
                            not Converter.CompareAccounts(context.account, context.converter), // different principals (same subaccount = null)
                            not Converter.CompareAccounts(TestUtil.get_test_zeroes_subaccount(), TestUtil.get_converter_zeroes_subaccount()), // different principals, same subaccounts ([0,0..0])
                            not Converter.CompareAccounts(TestUtil.get_test_subaccount(), TestUtil.get_converter_subaccount()), // different principals, same subaccounts ([1,2..32])
                            not Converter.CompareAccounts(context.account, TestUtil.get_test_subaccount()), // same principals, different subaccounts (null and [1,2..32])
                            not Converter.CompareAccounts(TestUtil.get_test_subaccount(), context.account), // same principals, different subaccounts ([1,2..32] and null)
                            not Converter.CompareAccounts(TestUtil.get_test_zeroes_subaccount(), TestUtil.get_test_subaccount()), // same principals, different subaccounts ([0,0..0] and [1,2..32])
                            not Converter.CompareAccounts(TestUtil.get_test_subaccount(), TestUtil.get_test_zeroes_subaccount()) // same principals, different subaccounts ([1,2..32] and [0.0..0])
                         ]);
                    },
                ),
                it(
                    "Controller should be able to set settings.",
                    do {
                        let context = TestUtil.get_caller_context(controller);
                        let old_settings = Converter.get_settings(context);
                        let new_settings : T.Settings = {
                            allow_conversions = false;
                            allow_burns = false;
                            new_fee_d8 = 12345678;
                            old_fee_d12 = 987654321;
                            d8_to_d12 = 9999;
                            new_seeder_min_amount_d8 = 99999999999;
                            old_burner_min_amount_d12 = 77777777777;
                            cooldown_ns = 42;                                 
                        };

                        let ok = Converter.set_settings(context, new_settings);
                        let new_settings_result = Converter.get_settings(context);

                        assertAllTrue([ 
                            old_settings.allow_conversions == true,
                            old_settings.allow_burns == true,
                            old_settings.new_fee_d8 == 1_000,
                            old_settings.old_fee_d12 ==100_000_000,
                            old_settings.d8_to_d12 == 10_000,
                            old_settings.new_seeder_min_amount_d8 ==100_000_000_000,
                            old_settings.old_burner_min_amount_d12 == 1000_000_000_000_000,
                            old_settings.cooldown_ns == 3600000000000,

                            new_settings.allow_conversions == new_settings_result.allow_conversions,
                            new_settings.new_fee_d8 == new_settings_result.new_fee_d8,
                            new_settings.old_fee_d12 == new_settings_result.old_fee_d12,
                            new_settings.d8_to_d12 == new_settings_result.d8_to_d12,
                            new_settings.new_seeder_min_amount_d8 == new_settings_result.new_seeder_min_amount_d8,
                            new_settings.old_burner_min_amount_d12 == new_settings_result.old_burner_min_amount_d12,
                            new_settings.cooldown_ns == new_settings_result.cooldown_ns
                        ]);
                    },
                ),
                it(
                    "Controller should be able to set canisters.",
                    do {
                        let context = TestUtil.get_caller_context(controller);
                        let old_canister_ids = Converter.get_canister_ids(context);

                        Converter.set_canister_ids(context, "czysu-eaaaa-aaaag-qcvdq-cai", "duww2-liaaa-aaaag-qcvea-cai", "cpi23-5qaaa-aaaag-qcs5a-cai", "ahw5u-keaaa-aaaaa-qaaha-cai");
                        let new_canister_ids = Converter.get_canister_ids(context);

                        assertAllTrue([ 
                            Principal.isAnonymous(old_canister_ids.old_token_canister_id),
                            Principal.isAnonymous(old_canister_ids.old_indexer_canister_id),
                            Principal.isAnonymous(old_canister_ids.new_token_canister_id),
                            Principal.isAnonymous(old_canister_ids.new_indexer_canister_id),
                            Principal.toText(new_canister_ids.old_token_canister_id) == "czysu-eaaaa-aaaag-qcvdq-cai",
                            Principal.toText(new_canister_ids.old_indexer_canister_id) == "duww2-liaaa-aaaag-qcvea-cai",
                            Principal.toText(new_canister_ids.new_token_canister_id) == "cpi23-5qaaa-aaaag-qcs5a-cai",
                            Principal.toText(new_canister_ids.new_indexer_canister_id) == "ahw5u-keaaa-aaaaa-qaaha-cai",
                        ]);
                    },
                ),
                it(
                    "Application should be considered inactive until all four canister ids have been provided.",
                    do {
                        let context = TestUtil.get_caller_context(controller);
                        let active0 = Converter.IsActive(context);
                        Converter.set_canister_ids(context, "czysu-eaaaa-aaaag-qcvdq-cai", "2vxsx-fae", "2vxsx-fae", "2vxsx-fae");
                        let active1 = Converter.IsActive(context);
                        Converter.set_canister_ids(context, "czysu-eaaaa-aaaag-qcvdq-cai", "czysu-eaaaa-aaaag-qcvdq-cai", "2vxsx-fae", "2vxsx-fae");
                        let active2 = Converter.IsActive(context);
                        Converter.set_canister_ids(context, "czysu-eaaaa-aaaag-qcvdq-cai", "czysu-eaaaa-aaaag-qcvdq-cai", "czysu-eaaaa-aaaag-qcvdq-cai", "2vxsx-fae");
                        let active3 = Converter.IsActive(context);
                        Converter.set_canister_ids(context, "czysu-eaaaa-aaaag-qcvdq-cai", "czysu-eaaaa-aaaag-qcvdq-cai", "czysu-eaaaa-aaaag-qcvdq-cai", "czysu-eaaaa-aaaag-qcvdq-cai");
                        let active4 = Converter.IsActive(context);

                        assertAllTrue([ 
                            active0 == false, // Application should not have started out in active state.
                            active1 == false, // Application should not be considered active with one out of four canister ids set
                            active2 == false, // Application should not be considered active with two out of four canister ids set
                            active3 == false, // Application should not be considered active with three out of four canister ids set
                            active4 == true  // Application should be considered active with four out of four canister ids set 
                        ]);
                    },
                ),
                it(
                    "Cooldown should be last for the time specified in nanoseconds in settings.cooldown_ns, then removed from the map when expired.",
                    do {
                        let context = TestUtil.get_context();

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
                        let context = TestUtil.get_context();

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

                // TODO: Test logging
            ]
        );
    };
};