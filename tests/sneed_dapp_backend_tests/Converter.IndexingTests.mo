import Array "mo:base/Array";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
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
            "SneedConverter dApp Indexing Tests",
            [
                it(
                    "Indexing account with no transactions should yield zero balance.",
                    do {

                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(0));

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),

                                    indexedAccount.new_total_balance_d8 == 0,
                                    indexedAccount.old_balance_d12 == 0,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 0,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 0,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 0,
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
                    "Indexing account with one old token Account-to-dApp transaction should yield a balance matching amount - old_fee.",
                    do {

                        // old: (100, 1000000000000, acct, dapp)
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(1));
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
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
                                    indexedAccount.old_balance_d12 == indexedAccount.new_total_balance_d8 * settings.d12_to_d8,
                                    indexedAccount.old_balance_d12 == indexedAccount.old_sent_acct_to_dapp_d12
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with two old token Account-to-dApp transactions should yield a balance matching amounts - (2 * old_fee).",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(2));
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
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
                                    indexedAccount.old_balance_d12 == indexedAccount.new_total_balance_d8 * settings.d12_to_d8,
                                    indexedAccount.old_balance_d12 == indexedAccount.old_sent_acct_to_dapp_d12
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with two old token Account-to-dApp transactions and one old token dApp-to-Account transaction (refund) "
                        # "should yield a balance matching a2d amounts - (2 * old_fee) - d2a amount. Refunds are not supported by the dApp, " 
                        # "but any d2a transactions that exist must be counted.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(3));
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens
                        let amount3 = 500000000000; // 0.5 old tokens
                        TestUtil.log_last_seen_old(context, 110);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
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
                                    indexedAccount.old_balance_d12 == indexedAccount.new_total_balance_d8 * settings.d12_to_d8,
                                    indexedAccount.old_balance_d12 == indexedAccount.old_sent_acct_to_dapp_d12 - indexedAccount.old_sent_dapp_to_acct_d12,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == amount1 + amount2 - (2 * settings.old_fee_d12),
                                    indexedAccount.old_sent_dapp_to_acct_d12 == amount3
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with two old token Account-to-dApp transactions and one new token dApp-to-Account transaction (conversion) "
                        # "should yield a balance matching old a2d amounts - (2 * old_fee) - new_fee - new d2a amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp) 
                        // new: (115, 50000000, dapp, account) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(4));
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens
                        let amount3 = 50000000; // 0.5 new tokens                        
                        TestUtil.log_last_seen_new(context, 115);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
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

                                    indexedAccount.new_total_balance_d8 * settings.d12_to_d8 == indexedAccount.new_total_balance_d8 * settings.d12_to_d8,
                                    indexedAccount.new_total_balance_d8 * settings.d12_to_d8 == (amount1 + amount2) 
                                                                                    - (2 * settings.old_fee_d12) 
                                                                                    - (amount3 * settings.d12_to_d8) 
                                                                                    - (settings.new_fee_d8 * settings.d12_to_d8),
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
                    "Indexing account with two old token a2d transactions, one old token d2a transaction (refund) and one new token d2a transaction (conversion) "
                        # "should yield a balance matching old a2d amounts - (2 * old_fee) - old d2a amount - new_fee - new d2a amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        // new: (115, 50000000, dapp, account) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(5));
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens
                        let amount3 = 500000000000; // 0.5 old tokens
                        let amount4 = 50000000; // 0.5 new tokens                        
                        TestUtil.log_last_seen_old(context, 110);
                        TestUtil.log_last_seen_new(context, 115);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
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

                                    indexedAccount.new_total_balance_d8 * settings.d12_to_d8 == (amount1 + amount2) 
                                                                                    - (2 * settings.old_fee_d12) 
                                                                                    - amount3
                                                                                    - (amount4 * settings.d12_to_d8) 
                                                                                    - (settings.new_fee_d8 * settings.d12_to_d8),
                                    indexedAccount.new_total_balance_d8 * settings.d12_to_d8 == indexedAccount.old_sent_acct_to_dapp_d12 
                                                                                    - indexedAccount.old_sent_dapp_to_acct_d12
                                                                                    - (indexedAccount.new_sent_dapp_to_acct_d8 * settings.d12_to_d8),
                                    indexedAccount.new_total_balance_d8 * settings.d12_to_d8 == indexedAccount.old_balance_d12 
                                                                                    - (indexedAccount.new_sent_dapp_to_acct_d8 * settings.d12_to_d8),
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
                    "Indexing account with two old a2d transactions, one old d2a transaction (refund), " 
                        # "one new d2a transaction (conversion) and one new a2d transaction (accident) "
                        # "should yield a balance matching old a2d amounts - (2 * old_fee) - old d2a amount - new_fee - new d2a amount + new a2d amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        // new: (115, 50000000, dapp, account), (125, 25000000, account, dapp)  
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(6));
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens
                        let amount3 = 500000000000; // 0.5 old tokens
                        let amount4 = 50000000; // 0.5 new tokens                        
                        let amount5 = 25000000; // 0.25 new tokens                        
                        TestUtil.log_last_seen_old(context, 110);
                        TestUtil.log_last_seen_new(context, 125);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
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
                                
                                    indexedAccount.new_total_balance_d8 * settings.d12_to_d8 == (amount1 + amount2) 
                                                                                    + (amount5 * settings.d12_to_d8)
                                                                                    - (2 * settings.old_fee_d12) 
                                                                                    - amount3
                                                                                    - (amount4 * settings.d12_to_d8) 
                                                                                    - (settings.new_fee_d8 * settings.d12_to_d8), 
                                    indexedAccount.new_total_balance_d8 * settings.d12_to_d8 == indexedAccount.old_sent_acct_to_dapp_d12 
                                                                                    + (indexedAccount.new_sent_acct_to_dapp_d8 * settings.d12_to_d8)
                                                                                    - indexedAccount.old_sent_dapp_to_acct_d12
                                                                                    - (indexedAccount.new_sent_dapp_to_acct_d8 * settings.d12_to_d8),
                                    indexedAccount.new_total_balance_d8 * settings.d12_to_d8 == indexedAccount.old_balance_d12 
                                                                                    + (indexedAccount.new_sent_acct_to_dapp_d8 * settings.d12_to_d8)
                                                                                    - (indexedAccount.new_sent_dapp_to_acct_d8 * settings.d12_to_d8),

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
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(7));

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 

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
                    "Indexing account with one old a2d transaction and one bigger old d2a transaction should yield a zero balance and an underflow.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (195, 2000000000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(8));
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens
                        TestUtil.log_last_seen_old(context, 195);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    
                                    indexedAccount.new_total_balance_d8 == 0,
                                    indexedAccount.old_balance_d12 == 0,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_balance_underflow_d12 == 1000100000000,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 0,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 0,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 999900000000,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 2000000000000,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == true,
                                    indexedAccount.old_latest_send_txid == ?195,
                                    indexedAccount.new_latest_send_found == false,
                                    indexedAccount.new_latest_send_txid == null,

                                    indexedAccount.old_balance_underflow_d12 == indexedAccount.old_sent_dapp_to_acct_d12 - indexedAccount.old_sent_acct_to_dapp_d12,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == amount1 - settings.old_fee_d12,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == amount2
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with one new a2d transaction and one bigger new d2a transaction (and no old a2d transaction) should yield a zero balance and an underflow.",
                    do {

                        // new: (115, 200000000, dapp, acct), (185, 100000000, acct, dapp) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(9));
                        let settings = context.state.persistent.settings;
                        let amount1 = 200000000; // 2 new tokens
                        let amount2 = 100000000; // 1 new token
                        TestUtil.log_last_seen_new(context, 115);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    
                                    indexedAccount.new_total_balance_d8 == 0,
                                    indexedAccount.old_balance_d12 == 0,
                                    indexedAccount.new_total_balance_underflow_d8 == 100001000,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 100000000,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 200001000,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 0,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 0,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == false,
                                    indexedAccount.old_latest_send_txid == null,
                                    indexedAccount.new_latest_send_found == true,
                                    indexedAccount.new_latest_send_txid == ?115,

                                    indexedAccount.new_total_balance_underflow_d8 == indexedAccount.new_sent_dapp_to_acct_d8 - indexedAccount.new_sent_acct_to_dapp_d8,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == amount2,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == amount1 + settings.new_fee_d8
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with one old a2d transaction and one bigger new d2a transaction should yield zero balance and underflow.",
                    do {

                        // old: (100, 1000000000000, acct, dapp) 
                        // new: (115, 200000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(10));
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 200000000; // 2 new tokens
                        TestUtil.log_last_seen_new(context, 115);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    
                                    indexedAccount.new_total_balance_d8 == 0,
                                    indexedAccount.old_balance_d12 == 999900000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 100011000,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 0,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 200001000,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 999900000000,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 0,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == false,
                                    indexedAccount.old_latest_send_txid == null,
                                    indexedAccount.new_latest_send_found == true,
                                    indexedAccount.new_latest_send_txid == ?115,

                                    indexedAccount.new_total_balance_underflow_d8 * settings.d12_to_d8 == 
                                                                (indexedAccount.new_sent_dapp_to_acct_d8 * settings.d12_to_d8) - indexedAccount.old_sent_acct_to_dapp_d12,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == amount1 - settings.old_fee_d12,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == amount2 + settings.new_fee_d8
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with one new a2d transaction and one bigger old d2a transaction should yield zero balance and underflow.",
                    do {

                        // old: (195, 2000000000000, dapp, acct) 
                        // new: (185, 100000000, acct, dapp) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(11));
                        let settings = context.state.persistent.settings;
                        let amount1 = 2000000000000; // 2 old tokens
                        let amount2 = 100000000; // 1 new token
                        TestUtil.log_last_seen_old(context, 195);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {
                                TestUtil.print_indexed_account(indexedAccount);
                                assertAllTrue([ 
                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    
                                    indexedAccount.new_total_balance_d8 == 100000000,
                                    indexedAccount.old_balance_d12 == 0,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_balance_underflow_d12 == 2000000000000,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 100000000,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 0,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 0,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 2000000000000,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == true,
                                    indexedAccount.old_latest_send_txid == ?195,
                                    indexedAccount.new_latest_send_found == false,
                                    indexedAccount.new_latest_send_txid == null,

                                    indexedAccount.old_balance_underflow_d12 == indexedAccount.old_sent_dapp_to_acct_d12,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == amount1,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == amount2
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with one old and one new a2d transaction, one bigger old d2a transaction and one bigger new d2a transaction should yield zero balances and underflows.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (195, 2000000000000, dapp, acct) 
                        // new: (115, 200000000, dapp, acct), (185, 100000000, acct, dapp) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(12));
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 2000000000000; // 2 old tokens
                        let amount3 = 200000000; // 2 new tokens
                        let amount4 = 100000000; // 1 new token
                        TestUtil.log_last_seen_old(context, 195);
                        TestUtil.log_last_seen_new(context, 115);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    
                                    indexedAccount.new_total_balance_d8 == 0,
                                    indexedAccount.old_balance_d12 == 0,
                                    indexedAccount.new_total_balance_underflow_d8 == 100001000,
                                    indexedAccount.old_balance_underflow_d12 == 1000100000000,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 100000000,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 200001000,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 999900000000,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 2000000000000,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == true,
                                    indexedAccount.old_latest_send_txid == ?195,
                                    indexedAccount.new_latest_send_found == true,
                                    indexedAccount.new_latest_send_txid == ?115,

                                    indexedAccount.old_balance_underflow_d12 == indexedAccount.old_sent_dapp_to_acct_d12 - indexedAccount.old_sent_acct_to_dapp_d12,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == amount1 - settings.old_fee_d12,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == amount2,

                                    indexedAccount.new_total_balance_underflow_d8 == indexedAccount.new_sent_dapp_to_acct_d8 - indexedAccount.new_sent_acct_to_dapp_d8,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == amount4,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == amount3 + settings.new_fee_d8
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Converting exact amount should cause underflow by old and new fee.",
                    do {

                        // old: (100, 1000000000000, acct, dapp) 
                        // new: (115, 100000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(13));
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token
                        let amount2 = 100000000; // 1 new token
                        TestUtil.log_last_seen_new(context, 115);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                TestUtil.print_indexed_account(indexedAccount);
                                assertAllTrue([ 
                                    TestUtil.verify_indexed_account_invariants(context, indexedAccount),
                                    
                                    indexedAccount.new_total_balance_d8 == 0,
                                    indexedAccount.old_balance_d12 == 999900000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 11000,
                                    indexedAccount.old_balance_underflow_d12 == 0,
                                    indexedAccount.new_sent_acct_to_dapp_d8 == 0,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == 100001000,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == 999900000000,
                                    indexedAccount.old_sent_dapp_to_acct_d12 == 0,
                                    indexedAccount.is_seeder == false,
                                    indexedAccount.is_burner == false,
                                    indexedAccount.old_latest_send_found == false,
                                    indexedAccount.old_latest_send_txid == null,
                                    indexedAccount.new_latest_send_found == true,
                                    indexedAccount.new_latest_send_txid == ?115,

                                    indexedAccount.new_total_balance_underflow_d8 * settings.d12_to_d8 == 
                                                                (indexedAccount.new_sent_dapp_to_acct_d8 * settings.d12_to_d8) - indexedAccount.old_sent_acct_to_dapp_d12,
                                    indexedAccount.new_total_balance_underflow_d8 * settings.d12_to_d8 == 
                                                                (settings.new_fee_d8 * settings.d12_to_d8) + settings.old_fee_d12,
                                    indexedAccount.old_sent_acct_to_dapp_d12 == amount1 - settings.old_fee_d12,
                                    indexedAccount.new_sent_dapp_to_acct_d8 == amount2 + settings.new_fee_d8
                                ]);

                            };
                        };
                    },
                )
            ]
        );
    };
};