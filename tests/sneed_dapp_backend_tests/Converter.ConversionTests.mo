// NB: For each test it is noted in comments what transactions the mock indexers will return for the 
// particular test account that is used in the test (see tests/mocks/MewIndexerCanisterMock.mo and 
// tests/mocks/OldIndexerCanisterMock.mo), using the following notation:
// old/new: (tx index, amount [as integer, no decimals], from, to)
// An old token transaction with transaction index 10, sending exactly one token from the account
// to the dApp would be: old: (10, 1000000000000, acct, dapp).
// A new token transaction with transaction index 11, sending exactly one token from the dApp
// to the account would be: new: (11, 100000000, dapp, acct).

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Nat8 "mo:base/Nat8";
import Time "mo:base/Time";
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
            "SneedConverter dApp Conversion Tests",
            [
                it(
                    "Converting account with no transactions should result in #InsufficientFunds with zero balance.",
                    do {

                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(0));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#InsufficientFunds({ balance }))) { assertTrue( balance == 0 ); };
                            case _ { Debug.trap("Should have returned #InsufficientFunds error."); };
                        };
                    },
                ),
                it(
                    "Converting account with one old token Account-to-dApp transaction should result in a conversion matching the deposit minus a new fee.",
                    do {

                        // old: (100, 1000000000000, acct, dapp)
                        let account = TestUtil.get_test_account(1);
                        let context = TestUtil.get_account_context_with_mocks(controller, account);
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(err)) { Debug.trap("Failed"); };
                            case (#Ok(tx_index)) {

                                let log_item_enter = TestUtil.must_get_latest_log_item(Converter.get_log(context), 2);
                                let log_item = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let log_item_exit = TestUtil.must_get_latest_log_item(Converter.get_log(context), 0);
                                let convert_log_item = TestUtil.must_get_convert_log_item(?log_item);
                                let exit_log_item = TestUtil.must_get_exit_log_item(?log_item_exit);
                                let indexedAccount = convert_log_item.account;

                                assertAllTrue([

                                    tx_index == 1234,
                                    TestUtil.verify_convert_log_item_invariants(context, convert_log_item),
                                    TestUtil.is_ok_convert_result(?convert_log_item.result),
                                    log_item_enter.name == "convert_account",
                                    log_item.name == "ConvertAccount",
                                    log_item_exit.name == "convert_account",
                                    log_item_enter.message == "Enter",
                                    log_item.message == "Complete",
                                    log_item_exit.message == "Exit",
                                    TestUtil.is_ok_convert_result(exit_log_item.convert_result),
                                    exit_log_item.trapped_message == "",
                                    convert_log_item.args.amount == 99989000,
                                    convert_log_item.args.from_subaccount == null,
                                    Converter.CompareAccounts(convert_log_item.args.to, account),
                                    convert_log_item.args.fee == settings.new_fee_d8,
                                    convert_log_item.args.memo == Blob.fromArray([5,2,3,3,9]),
                                    convert_log_item.args.created_at_time == null,                                
                                    convert_log_item.args.amount * settings.d8_to_d12 == amount1 - settings.old_fee_d12 - (settings.new_fee_d8 * settings.d8_to_d12),

                                    // These properties are verified in the IndexingTests, but we double-check they remain as expected
                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    indexedAccount.new_total_balance_d8 == 99990000,
                                    indexedAccount.old_balance_d12 == 999900000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 0,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 0,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 999900000000,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 0,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == false,
                                    indexedAccount.old_latest_send_txid == null,
                                    indexedAccount.new_latest_send_found == false,
                                    indexedAccount.new_latest_send_txid == null,
                                    indexedAccount.old_balance_d12 == amount1 - settings.old_fee_d12,
                                    indexedAccount.old_balance_d12 == indexedAccount.new_total_balance_d8 * settings.d8_to_d12,
                                    indexedAccount.old_balance_d12 == indexedAccount.old_sent_acct_to_dapp_d12
                                ]);
                            };
                        };
                    },
                ),
                it(
                    "Converting account with two old token Account-to-dApp transactions should result in a conversion matching the two deposits minus a new fee.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp) 
                        let account = TestUtil.get_test_account(2);
                        let context = TestUtil.get_account_context_with_mocks(controller, account);
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(err)) { Debug.trap("Failed"); };
                            case (#Ok(tx_index)) {

                                let log_item = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let convert_log_item = TestUtil.must_get_convert_log_item(?log_item);
                                let indexedAccount = convert_log_item.account;

                                assertAllTrue([ 

                                    tx_index == 1234,
                                    TestUtil.verify_convert_log_item_invariants(context, convert_log_item),
                                    TestUtil.is_ok_convert_result(?convert_log_item.result),
                                    convert_log_item.args.amount == 299979000,
                                    convert_log_item.args.from_subaccount == null,
                                    Converter.CompareAccounts(convert_log_item.args.to, account),
                                    convert_log_item.args.fee == settings.new_fee_d8,
                                    convert_log_item.args.memo == Blob.fromArray([5,2,3,3,9]),
                                    convert_log_item.args.created_at_time == null,                                    
                                    convert_log_item.args.amount * settings.d8_to_d12 == amount1 + amount2 - (2 * settings.old_fee_d12) 
                                                                                            - (settings.new_fee_d8 * settings.d8_to_d12),

                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),                                    
                                    indexedAccount.new_total_balance_d8 == 299980000,
                                    indexedAccount.old_balance_d12 == 2999800000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 0,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 0,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 2999800000000,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 0,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == false,
                                    indexedAccount.old_latest_send_txid == null,
                                    indexedAccount.new_latest_send_found == false,
                                    indexedAccount.new_latest_send_txid == null,
                                    indexedAccount.old_balance_d12 == (amount1 + amount2) - (2 * settings.old_fee_d12),
                                    indexedAccount.old_balance_d12 == indexedAccount.new_total_balance_d8 * settings.d8_to_d12,
                                    indexedAccount.old_balance_d12 == indexedAccount.old_sent_acct_to_dapp_d12
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Converting account with two old token Account-to-dApp transactions and one old token dApp-to-Account transaction (refund) "
                        # "should result in a conversion matching the two deposits minus the withdrawal and minus a new fee.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        let account = TestUtil.get_test_account(3);
                        let context = TestUtil.get_account_context_with_mocks(controller, account);
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens
                        let amount3 = 500000000000; // 0.5 old tokens
                        TestUtil.log_last_seen_old(context, 110);

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(err)) { Debug.trap("Failed"); };
                            case (#Ok(tx_index)) {

                                let log_item = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let convert_log_item = TestUtil.must_get_convert_log_item(?log_item);
                                let indexedAccount = convert_log_item.account;

                                assertAllTrue([ 

                                    tx_index == 1234,
                                    TestUtil.verify_convert_log_item_invariants(context, convert_log_item),
                                    TestUtil.is_ok_convert_result(?convert_log_item.result),
                                    convert_log_item.args.amount == 249979000,
                                    convert_log_item.args.from_subaccount == null,
                                    Converter.CompareAccounts(convert_log_item.args.to, account),
                                    convert_log_item.args.fee == settings.new_fee_d8,
                                    convert_log_item.args.memo == Blob.fromArray([5,2,3,3,9]),
                                    convert_log_item.args.created_at_time == null,                                    
                                    convert_log_item.args.amount * settings.d8_to_d12 == amount1 + amount2 - (2 * settings.old_fee_d12) - amount3
                                                                                            - (settings.new_fee_d8 * settings.d8_to_d12),

                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    indexedAccount.new_total_balance_d8 == 249980000,
                                    indexedAccount.old_balance_d12 == 2499800000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 0,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 0,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 2999800000000,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 500000000000,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == true,
                                    indexedAccount.old_latest_send_txid == ?110,
                                    indexedAccount.new_latest_send_found == false,
                                    indexedAccount.new_latest_send_txid == null,
                                    indexedAccount.old_balance_d12 == (amount1 + amount2) - (2 * settings.old_fee_d12) - amount3,
                                    indexedAccount.old_balance_d12 == indexedAccount.new_total_balance_d8 * settings.d8_to_d12,
                                    indexedAccount.old_balance_d12 == indexedAccount.old_sent_acct_to_dapp_d12 - indexedAccount.old_sent_dapp_to_acct_d12,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == amount1 + amount2 - (2 * settings.old_fee_d12),
                                    indexedAccount.old_sent_dapp_to_acct_d12 == amount3
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Converting account with two old token Account-to-dApp transactions and one new token dApp-to-Account transaction (conversion) "
                        # "should result in a conversion matching old a2d amounts - (2 * old_fee) - (2 * new_fee) - new d2a amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp) 
                        // new: (115, 50000000, dapp, account) 
                        let account = TestUtil.get_test_account(4);
                        let context = TestUtil.get_account_context_with_mocks(controller, account);
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens
                        let amount3 = 50000000; // 0.5 new tokens                        
                        TestUtil.log_last_seen_new(context, 115);

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(err)) { Debug.trap("Failed"); };
                            case (#Ok(tx_index)) {

                                let log_item = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let convert_log_item = TestUtil.must_get_convert_log_item(?log_item);
                                let indexedAccount = convert_log_item.account;

                                assertAllTrue([ 

                                    tx_index == 1234,
                                    TestUtil.verify_convert_log_item_invariants(context, convert_log_item),
                                    TestUtil.is_ok_convert_result(?convert_log_item.result),
                                    convert_log_item.args.amount == 249978000,
                                    convert_log_item.args.from_subaccount == null,
                                    Converter.CompareAccounts(convert_log_item.args.to, account),
                                    convert_log_item.args.fee == settings.new_fee_d8,
                                    convert_log_item.args.memo == Blob.fromArray([5,2,3,3,9]),
                                    convert_log_item.args.created_at_time == null,                                    
                                    convert_log_item.args.amount * settings.d8_to_d12 == amount1 + amount2 - (2 * settings.old_fee_d12)
                                                                                            - (amount3 * settings.d8_to_d12) 
                                                                                            - (2 * settings.new_fee_d8 * settings.d8_to_d12),

                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    indexedAccount.new_total_balance_d8 == 249979000,
                                    indexedAccount.old_balance_d12 == 2999800000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 0,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 50001000,        // the dApp used the amount reported by the indexer, plus the fee
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 2999800000000,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 0,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == false,
                                    indexedAccount.old_latest_send_txid == null,
                                    indexedAccount.new_latest_send_found == true,
                                    indexedAccount.new_latest_send_txid == ?115,

                                    indexedAccount.new_total_balance_d8 * settings.d8_to_d12 == indexedAccount.new_total_balance_d8 * settings.d8_to_d12,
                                    indexedAccount.new_total_balance_d8 * settings.d8_to_d12 == (amount1 + amount2) 
                                                                                    - (2 * settings.old_fee_d12) 
                                                                                    - (amount3 * settings.d8_to_d12) 
                                                                                    - (settings.new_fee_d8 * settings.d8_to_d12),
                                    indexedAccount.old_balance_d12 == (amount1 + amount2) - (2 * settings.old_fee_d12),
                                    indexedAccount.old_balance_d12 == indexedAccount.old_sent_acct_to_dapp_d12,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == amount1 + amount2 - (2 * settings.old_fee_d12),
                                    indexedAccount.new_sent_dapp_to_acct_d8 == amount3 + settings.new_fee_d8
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Converting account with two old token a2d transactions, one old token d2a transaction (refund) and one new token d2a transaction (conversion) "
                        # "should result in a conversion matching old a2d amounts - (2 * old_fee) - old d2a amount - (2 * new_fee) - new d2a amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        // new: (115, 50000000, dapp, account) 
                        let account = TestUtil.get_test_account(5);
                        let context = TestUtil.get_account_context_with_mocks(controller, account);
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens
                        let amount3 = 500000000000; // 0.5 old tokens
                        let amount4 = 50000000; // 0.5 new tokens                        
                        TestUtil.log_last_seen_old(context, 110);
                        TestUtil.log_last_seen_new(context, 115);

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(err)) { Debug.trap("Failed"); };
                            case (#Ok(tx_index)) {

                                let log_item = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let convert_log_item = TestUtil.must_get_convert_log_item(?log_item);
                                let indexedAccount = convert_log_item.account;

                                assertAllTrue([ 

                                    tx_index == 1234,
                                    TestUtil.verify_convert_log_item_invariants(context, convert_log_item),
                                    TestUtil.is_ok_convert_result(?convert_log_item.result),
                                    convert_log_item.args.amount == 199978000,
                                    convert_log_item.args.from_subaccount == null,
                                    Converter.CompareAccounts(convert_log_item.args.to, account),
                                    convert_log_item.args.fee == settings.new_fee_d8,
                                    convert_log_item.args.memo == Blob.fromArray([5,2,3,3,9]),
                                    convert_log_item.args.created_at_time == null,                                    
                                    convert_log_item.args.amount * settings.d8_to_d12 == amount1 + amount2 - (2 * settings.old_fee_d12)
                                                                                            - amount3
                                                                                            - (amount4 * settings.d8_to_d12) 
                                                                                            - (2 * settings.new_fee_d8 * settings.d8_to_d12),

                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    indexedAccount.new_total_balance_d8 == 199979000,
                                    indexedAccount.old_balance_d12 == 2499800000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 0,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 50001000,        // the dApp used the amount reported by the indexer, plus the fee
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 2999800000000,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 500000000000,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == true,
                                    indexedAccount.old_latest_send_txid == ?110,
                                    indexedAccount.new_latest_send_found == true,
                                    indexedAccount.new_latest_send_txid == ?115,

                                    indexedAccount.new_total_balance_d8 * settings.d8_to_d12 == (amount1 + amount2) 
                                                                                    - (2 * settings.old_fee_d12) 
                                                                                    - amount3
                                                                                    - (amount4 * settings.d8_to_d12) 
                                                                                    - (settings.new_fee_d8 * settings.d8_to_d12),
                                    indexedAccount.new_total_balance_d8 * settings.d8_to_d12 == indexedAccount.old_sent_acct_to_dapp_d12 
                                                                                    - indexedAccount.old_sent_dapp_to_acct_d12
                                                                                    - (indexedAccount.new_sent_dapp_to_acct_d8 * settings.d8_to_d12),
                                    indexedAccount.new_total_balance_d8 * settings.d8_to_d12 == indexedAccount.old_balance_d12 
                                                                                    - (indexedAccount.new_sent_dapp_to_acct_d8 * settings.d8_to_d12),
                                    indexedAccount.old_balance_d12 == (amount1 + amount2) - (2 * settings.old_fee_d12) - amount3,
                                    indexedAccount.old_balance_d12 == indexedAccount.old_sent_acct_to_dapp_d12 - indexedAccount.old_sent_dapp_to_acct_d12,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == amount1 + amount2 - (2 * settings.old_fee_d12),
                                    indexedAccount.old_sent_dapp_to_acct_d12 == amount3,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == amount4 + settings.new_fee_d8

                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Converting account with two old a2d transactions, one old d2a transaction (refund), " 
                        # "one new d2a transaction (conversion) and one new a2d transaction (accident) "
                        # "should result in a conversion matching old a2d amounts - (2 * old_fee) - old d2a amount - (2 * new_fee) - new d2a amount + new a2d amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        // new: (115, 50000000, dapp, account), (125, 25000000, account, dapp)  
                        let account = TestUtil.get_test_account(6);
                        let context = TestUtil.get_account_context_with_mocks(controller, account);
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens
                        let amount3 = 500000000000; // 0.5 old tokens
                        let amount4 = 50000000; // 0.5 new tokens                        
                        let amount5 = 25000000; // 0.25 new tokens                        
                        TestUtil.log_last_seen_old(context, 110);
                        TestUtil.log_last_seen_new(context, 125);

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(err)) { Debug.trap("Failed"); };
                            case (#Ok(tx_index)) {

                                let log_item = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let convert_log_item = TestUtil.must_get_convert_log_item(?log_item);
                                let indexedAccount = convert_log_item.account;

                                assertAllTrue([ 

                                    tx_index == 1234,
                                    TestUtil.verify_convert_log_item_invariants(context, convert_log_item),
                                    TestUtil.is_ok_convert_result(?convert_log_item.result),
                                    convert_log_item.args.amount == 224978000,
                                    convert_log_item.args.from_subaccount == null,
                                    Converter.CompareAccounts(convert_log_item.args.to, account),
                                    convert_log_item.args.fee == settings.new_fee_d8,
                                    convert_log_item.args.memo == Blob.fromArray([5,2,3,3,9]),
                                    convert_log_item.args.created_at_time == null,                                    
                                    convert_log_item.args.amount * settings.d8_to_d12 == amount1 + amount2 + (amount5 * settings.d8_to_d12) 
                                                                                            - (2 * settings.old_fee_d12)
                                                                                            - amount3
                                                                                            - (amount4 * settings.d8_to_d12) 
                                                                                            - (2 * settings.new_fee_d8 * settings.d8_to_d12),

                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    indexedAccount.new_total_balance_d8 == 224979000,
                                    indexedAccount.old_balance_d12 == 2499800000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 25000000,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 50001000,        
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 2999800000000,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 500000000000,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == true,
                                    indexedAccount.old_latest_send_txid == ?110,
                                    indexedAccount.new_latest_send_found == true,
                                    indexedAccount.new_latest_send_txid == ?125,                                
                                    indexedAccount.new_total_balance_d8 * settings.d8_to_d12 == (amount1 + amount2) 
                                                                                    + (amount5 * settings.d8_to_d12)
                                                                                    - (2 * settings.old_fee_d12) 
                                                                                    - amount3
                                                                                    - (amount4 * settings.d8_to_d12) 
                                                                                    - (settings.new_fee_d8 * settings.d8_to_d12), 
                                    indexedAccount.new_total_balance_d8 * settings.d8_to_d12 == indexedAccount.old_sent_acct_to_dapp_d12 
                                                                                    + (indexedAccount.new_sent_acct_to_dapp_d8 * settings.d8_to_d12)
                                                                                    - indexedAccount.old_sent_dapp_to_acct_d12
                                                                                    - (indexedAccount.new_sent_dapp_to_acct_d8 * settings.d8_to_d12),
                                    indexedAccount.new_total_balance_d8 * settings.d8_to_d12 == indexedAccount.old_balance_d12 
                                                                                    + (indexedAccount.new_sent_acct_to_dapp_d8 * settings.d8_to_d12)
                                                                                    - (indexedAccount.new_sent_dapp_to_acct_d8 * settings.d8_to_d12),
                                    indexedAccount.old_balance_d12 == (amount1 + amount2) - (2 * settings.old_fee_d12) - amount3,
                                    indexedAccount.old_balance_d12 == indexedAccount.old_sent_acct_to_dapp_d12 - indexedAccount.old_sent_dapp_to_acct_d12,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == amount1 + amount2 - (2 * settings.old_fee_d12),
                                    indexedAccount.old_sent_dapp_to_acct_d12 == amount3,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == amount4 + settings.new_fee_d8,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == amount5
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Decimal conversion from old to new (12 to 8 decimals) should discard last 4 digits of 12 decimal number.",
                    do {

                        // old: (100, 1234567891234, acct, dapp)
                        let account = TestUtil.get_test_account(7);
                        let context = TestUtil.get_account_context_with_mocks(controller, account);
                        let settings = context.state.persistent.settings;

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(err)) { Debug.trap("Failed"); };
                            case (#Ok(tx_index)) {

                                let log_item = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let convert_log_item = TestUtil.must_get_convert_log_item(?log_item);
                                let indexedAccount = convert_log_item.account;

                                assertAllTrue([ 

                                    tx_index == 1234,
                                    TestUtil.verify_convert_log_item_invariants(context, convert_log_item),
                                    TestUtil.is_ok_convert_result(?convert_log_item.result),
                                    convert_log_item.args.amount == 123445789,
                                    convert_log_item.args.from_subaccount == null,
                                    Converter.CompareAccounts(convert_log_item.args.to, account),
                                    convert_log_item.args.fee == settings.new_fee_d8,
                                    convert_log_item.args.memo == Blob.fromArray([5,2,3,3,9]),
                                    convert_log_item.args.created_at_time == null,                                    

                                    indexedAccount.new_total_balance_d8 == 123446789,
                                    indexedAccount.old_balance_d12 == 1234467891234,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 0,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 0,        
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 1234467891234,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 0,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == false,
                                    indexedAccount.old_latest_send_txid == null,
                                    indexedAccount.new_latest_send_found == false,
                                    indexedAccount.new_latest_send_txid == null
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Converting account with one old a2d transaction and one bigger old d2a transaction should result in an #IndexUnderflow error.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (195, 2000000000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(8));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IndexUnderflow(error))) { 
                                    assertAllTrue([

                                        error.new_total_balance_underflow_d8 == 0,
                                        error.old_balance_underflow_d12 == 1000100000000,
                                        error.new_sent_acct_to_dapp_d8 == 0,
                                        error.new_sent_dapp_to_acct_d8 == 0,
                                        error.old_sent_acct_to_dapp_d12 == 999900000000,
                                        error.old_sent_dapp_to_acct_d12 == 2000000000000

                                    ]); 
                                };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with one new a2d transaction and one bigger new d2a transaction (and no old a2d transaction) should result in an #IndexUnderflow error.",
                    do {

                        // new: (115, 200000000, dapp, acct), (185, 100000000, acct, dapp) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(9));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IndexUnderflow(error))) { 
                                    assertAllTrue([

                                        error.new_total_balance_underflow_d8 == 100001000,
                                        error.old_balance_underflow_d12 == 0,
                                        error.new_sent_acct_to_dapp_d8 == 100000000,
                                        error.new_sent_dapp_to_acct_d8 == 200001000,
                                        error.old_sent_acct_to_dapp_d12 == 0,
                                        error.old_sent_dapp_to_acct_d12 == 0

                                    ]); 
                                };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with one old a2d transaction and one bigger new d2a transaction should result in an #IndexUnderflow error.",
                    do {

                        // old: (100, 1000000000000, acct, dapp) 
                        // new: (115, 200000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(10));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IndexUnderflow(error))) { 
                                    assertAllTrue([

                                        error.new_total_balance_underflow_d8 == 100011000,
                                        error.old_balance_underflow_d12 == 0,
                                        error.new_sent_acct_to_dapp_d8 == 0,
                                        error.new_sent_dapp_to_acct_d8 == 200001000,
                                        error.old_sent_acct_to_dapp_d12 == 999900000000,
                                        error.old_sent_dapp_to_acct_d12 == 0

                                    ]); 
                                };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with one new a2d transaction and one bigger old d2a transaction should result in an #IndexUnderflow error.",
                    do {

                        // old: (195, 2000000000000, dapp, acct) 
                        // new: (185, 100000000, acct, dapp) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(11));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IndexUnderflow(error))) { 
                                    assertAllTrue([

                                        error.new_total_balance_underflow_d8 == 0,
                                        error.old_balance_underflow_d12 == 2000000000000,
                                        error.new_sent_acct_to_dapp_d8 == 100000000,
                                        error.new_sent_dapp_to_acct_d8 == 0,
                                        error.old_sent_acct_to_dapp_d12 == 0,
                                        error.old_sent_dapp_to_acct_d12 == 2000000000000

                                    ]); 
                                };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with one old and one new a2d transaction, one bigger old d2a transaction and one bigger new d2a transaction should result in an #IndexUnderflow error.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (195, 2000000000000, dapp, acct) 
                        // new: (115, 200000000, dapp, acct), (185, 100000000, acct, dapp) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(12));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IndexUnderflow(error))) { 
                                    assertAllTrue([

                                        error.new_total_balance_underflow_d8 == 100001000,
                                        error.old_balance_underflow_d12 == 1000100000000,
                                        error.new_sent_acct_to_dapp_d8 == 100000000,
                                        error.new_sent_dapp_to_acct_d8 == 200001000,
                                        error.old_sent_acct_to_dapp_d12 == 999900000000,
                                        error.old_sent_dapp_to_acct_d12 == 2000000000000

                                    ]); 
                                };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting exact amount should result in an #IndexUnderflow error. This is a limit test, not possible for a user to do in the dApp.",
                    do {

                        // old: (100, 1000000000000, acct, dapp) 
                        // new: (115, 100000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(13));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IndexUnderflow(error))) { 
                                    assertAllTrue([

                                        error.new_total_balance_underflow_d8 == 11000,
                                        error.old_balance_underflow_d12 == 0,
                                        error.new_sent_acct_to_dapp_d8 == 0,
                                        error.new_sent_dapp_to_acct_d8 == 100001000,
                                        error.old_sent_acct_to_dapp_d12 == 999900000000,
                                        error.old_sent_dapp_to_acct_d12 == 0

                                    ]); 
                                };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with one huge old token Account-to-dApp transaction should mark the account as a burner and return #IsBurner error.",
                    do {

                        // old: (100, 1001000000000000, acct, dapp)
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(14));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IsBurner)) { true };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with two old token Account-to-dApp transactions, together huge, should mark the account as a burner and return #IsBurner error.",
                    do {

                        // old: (100, 2000000000000, acct, dapp), (105, 999000000000000, acct, dapp) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(15));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IsBurner)) { true };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Old token dApp-to-account transactions do not negate burner status (return #IsBurner error).",
                    do {

                        // old: (100, 1001000000000000, acct, dapp), (195, 999000000000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(16));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IsBurner)) { true };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with one huge new token Account-to-dApp transaction should mark the account as a seeder and return #IsSeeder error.",
                    do {

                        // new: (115, 100100000000, acct, dapp)
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(17));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IsSeeder)) { true };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with two new token Account-to-dApp transactions, together huge, should mark the account as a seeder and return #IsSeeder error.",
                    do {

                        // new: (115, 200000000, acct, dapp), (125, 99900000000, acct, dapp) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(18));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IsSeeder)) { true };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "New token dApp-to-account transactions do not negate seeder status (return #IsSeeder error).",
                    do {

                        // new: (115, 100100000000, acct, dapp), (185, 99900000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(19));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IsSeeder)) { true };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with one huge old a2d transaction and one huge new a2d transaction should mark the account as a burner and a seeder (return #IsSeeder error).",
                    do {

                        // old: (100, 1001000000000000, acct, dapp)
                        // new: (115, 100100000000, acct, dapp)                        
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(19));

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#IsSeeder)) { true };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with unseen old token dApp-to-account transaction should return #StaleIndexer error.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(3));
                        TestUtil.log_last_seen_old(context, 125); // Simulate not finding the last seen old d2a transaction (125 is not in list from indexer)

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#StaleIndexer( error ))) { 
                                switch (error.txid) {
                                    case (null) { Debug.trap("Should have returned #StaleIndexer error with transaction index."); };
                                    case (?txid) {
                                        assertTrue( txid == 125 ); 

                                    };
                                };
                            };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with unseen new token dApp-to-account transaction should return #StaleIndexer error.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp) 
                        // new: (115, 50000000, dapp, account) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(4));
                        TestUtil.log_last_seen_new(context, 125); // Simulate not finding the last seen old d2a transaction (125 is not in list from indexer)

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#StaleIndexer( error ))) { 
                                switch (error.txid) {
                                    case (null) { Debug.trap("Should have returned #StaleIndexer error with transaction index."); };
                                    case (?txid) {
                                        assertTrue( txid == 125 ); 

                                    };
                                };
                            };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Converting account with unseen new and old token dApp-to-account transactions should return #StaleIndexer error.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        // new: (115, 50000000, dapp, account) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(5));
                        TestUtil.log_last_seen_old(context, 325); // Simulate not finding the last seen old d2a transaction (325 is not in list from indexer)
                        TestUtil.log_last_seen_new(context, 425); // Simulate not finding the last seen old d2a transaction (425 is not in list from indexer)

                        let convert_result = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#StaleIndexer( error ))) { 
                                switch (error.txid) {
                                    case (null) { Debug.trap("Should have returned #StaleIndexer error with transaction index."); };
                                    case (?txid) {
                                        assertTrue( txid == 425 ); 

                                    };
                                };
                            };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert twice inside the cooldown period should result in an #OnCooldown error.",
                    do {

                        // old: (100, 1000000000000, acct, dapp)
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(1));

                        let convert_result = await* Converter.convert_account(context);
                        let convert_result2 = await* Converter.convert_account(context);

                        switch (convert_result2) {
                            case (#Err(#OnCooldown( error ))) { 
                                assertAllTrue([ 
                                    error.since > 0,
                                    error.remaining > 0 
                                ]);
                            };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert a second time outside the cooldown period should not result in an #OnCooldown error.",
                    do {

                        // old: (100, 1000000000000, acct, dapp)
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(1));

                        let convert_result = await* Converter.convert_account(context);

                        let since = Converter.CooldownSince(context, context.account.owner);
                        context.state.ephemeral.cooldowns.put(context.account.owner, since 
                                                                                - (context.state.persistent.settings.cooldown_ns + 1));

                        let convert_result2 = await* Converter.convert_account(context);
                        
                        // We expect #StaleIndexer error since the indexer mock will return the same (first) list of transactions for the same account
                        switch (convert_result2) {
                            case (#Err(#StaleIndexer( error ))) { 
                                switch (error.txid) {
                                    case (null) { Debug.trap("Should have returned #StaleIndexer error with transaction index."); };
                                    case (?txid) {
                                        assertTrue( txid == 1234 ); 

                                    };
                                };
                            };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert when balance matches new fee should result in #InsufficientFunds error.",
                    do {

                        // old: (100, 110000000, acct, dapp)
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(21));

                        let convert_result = await* Converter.convert_account(context);
                        
                        switch (convert_result) {
                            case (#Err(#InsufficientFunds({ balance }))) { assertTrue( balance == 1000 ); };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert when balance is below new fee should result in #InsufficientFunds error.",
                    do {

                        // old: (100, 101000000, acct, dapp)
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(22));

                        let convert_result = await* Converter.convert_account(context);
                        
                        switch (convert_result) {
                            case (#Err(#InsufficientFunds({ balance }))) { assertTrue( balance == 100 ); };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert when indexer returns an error should result in #ExternalCanisterError error.",
                    do {

                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(23));

                        let convert_result = await* Converter.convert_account(context);
                        
                        switch (convert_result) {
                            case (#Err(#ExternalCanisterError({ message }))) { assertTrue( message == "Something most unfortunate has occurred." ); };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert when old indexer traps should result in #ExternalCanisterError error.",
                    do {

                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(24));
                        let convert_result = await* Converter.convert_account(context);
                        
                        switch (convert_result) {
                            case (#Err(#ExternalCanisterError({ message }))) { 
                                
                                let log_item_enter = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let log_item_exit = TestUtil.must_get_latest_log_item(Converter.get_log(context), 0);
                                let exit_log_item = TestUtil.must_get_exit_log_item(?log_item_exit);
                                let expected_msg = "IC0503: Canister bw4dl-smaaa-aaaaa-qaacq-cai trapped explicitly: Old indexer canister mock trapped.";

                                // The log should only contain the enter and exit messages, not the ConvertAccount Complete message
                                assertAllTrue([ 
                                    message == expected_msg, 
                                    log_item_enter.name == "convert_account",
                                    log_item_exit.name == "convert_account",
                                    log_item_enter.message == "Enter",
                                    log_item_exit.message == "Exit",
                                    log_item_enter.convert == null,
                                    log_item_enter.exit == null,
                                    exit_log_item.trapped_message == expected_msg
                                ]); 
                            };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert when new indexer traps should result in #ExternalCanisterError error.",
                    do {

                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(25));
                        let convert_result = await* Converter.convert_account(context);
                        
                        switch (convert_result) {
                            case (#Err(#ExternalCanisterError({ message }))) { assertTrue( message == "IC0503: Canister be2us-64aaa-aaaaa-qaabq-cai trapped explicitly: New indexer canister mock trapped." ); };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert when new ledger traps should result in #ExternalCanisterError error.",
                    do {

                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(26));
                        let convert_result = await* Converter.convert_account(context);
                        
                        switch (convert_result) {
                            case (#Err(#ExternalCanisterError({ message }))) { 

                                let log_item_enter = TestUtil.must_get_latest_log_item(Converter.get_log(context), 2);
                                let log_item_convert = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let log_item_exit = TestUtil.must_get_latest_log_item(Converter.get_log(context), 0);
                                let convert_log_item = TestUtil.must_get_convert_log_item(?log_item_convert);
                                let exit_log_item = TestUtil.must_get_exit_log_item(?log_item_exit);

                                assertAllTrue([ 
                                    message == "IC0503: Canister br5f7-7uaaa-aaaaa-qaaca-cai trapped explicitly: New ledger canister mock trapped.",

                                    log_item_enter.name == "convert_account",
                                    log_item_enter.message == "Enter",
                                    log_item_convert.name == "ConvertAccount",
                                    log_item_convert.message == "Failed",
                                    log_item_exit.name == "convert_account",
                                    log_item_exit.message == "Exit",
                                ]); 
                            };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert twice inside the cooldown period when the first call traps externally should result in an #OnCooldown error.",
                    do {

                        // old: (100, 1000000000000, acct, dapp)
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(24));

                        let convert_result = await* Converter.convert_account(context);
                        let convert_result2 = await* Converter.convert_account(context);

                        switch (convert_result) {
                            case (#Err(#ExternalCanisterError( messsage ))) { 
                                switch (convert_result2) {
                                    case (#Err(#OnCooldown( error ))) { 
                                        assertAllTrue([ 
                                            error.since > 0,
                                            error.remaining > 0 
                                        ]);
                                    };
                                    case _ { false; };
                                };
                            };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert with invalid account should result in #InvalidAccount error.",
                    do {
                        let account = {
                            owner = TestUtil.get_test_account(1).owner;
                            subaccount = ?Blob.fromArray(Array.tabulate(25, Nat8.fromNat));
                        };

                        let context = TestUtil.get_account_context_with_mocks(controller, account);

                        let convert_result = await* Converter.convert_account(context);
                        
                        switch (convert_result) {
                            case (#Err(#InvalidAccount)) { true; };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert when settings.allow_conversions is set to false should result in #ConversionsNotAllowed error.",
                    do {

                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(1));
                        let new_settings : T.Settings = {
                            allow_conversions = false;
                            allow_burns = true;
                            new_fee_d8 = 12345678;
                            old_fee_d12 = 987654321;
                            d8_to_d12 = 9999;
                            new_seeder_min_amount_d8 = 99999999999;
                            old_burner_min_amount_d12 = 77777777777;
                            cooldown_ns = 42;
                            max_transactions = 123;
                        };

                        let ok = Converter.set_settings(context, new_settings);

                        let convert_result = await* Converter.convert_account(context);
                        
                        switch (convert_result) {
                            case (#Err(#ConversionsNotAllowed)) { true; };
                            case _ { false; };
                        };
                    },
                ),
                it(
                    "Calling convert when new indexer returns as many transactions as specified in settings.max_transactions (or more) should result in #TooManyTransactions error.",
                    do {

                        // new: (115, 100000000, account, dapp), (196, 100000000, dapp, account), (197, 100000000, dapp, account), (198, 100000000, dapp, account), (199, 100000000, dapp, account) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(27));
                        let new_settings : T.Settings = {
                            allow_conversions = true;
                            allow_burns = true;
                            new_fee_d8 = 12345678;
                            old_fee_d12 = 987654321;
                            d8_to_d12 = 9999;
                            new_seeder_min_amount_d8 = 99999999999;
                            old_burner_min_amount_d12 = 77777777777;
                            cooldown_ns = 42;
                            max_transactions = 5;
                        };

                        let ok = Converter.set_settings(context, new_settings);

                        let convert_result = await* Converter.convert_account(context);
                        
                        switch (convert_result) {
                            case (#Err(#TooManyTransactions)) { true; };
                            case _ { false; };
                        };
                    },
                )
            ]
        );
    };
};