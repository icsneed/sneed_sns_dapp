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
                                    indexedAccount.new_total_balance_d8 == 0,
                                    indexedAccount.old_refundable_balance_d12 == 0,
                                    indexedAccount.old_balance_d12 == 0,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_refundable_balance_underflow_d12 == 0,
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

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    indexedAccount.new_total_balance_d8 == 99990000,
                                    indexedAccount.old_refundable_balance_d12 == 999900000000,
                                    indexedAccount.old_balance_d12 == 999900000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_refundable_balance_underflow_d12 == 0,
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
                                    indexedAccount.new_latest_send_txid == null
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

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    indexedAccount.new_total_balance_d8 == 299980000,
                                    indexedAccount.old_refundable_balance_d12 == 2999800000000,
                                    indexedAccount.old_balance_d12 == 2999800000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_refundable_balance_underflow_d12 == 0,
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
                                    indexedAccount.new_latest_send_txid == null
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with two old token Account-to-dApp transactions and one old token dApp-to-Account transaction (refund) should yield a balance matching a2d amounts - (2 * old_fee) - d2a amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(3));
                        TestUtil.log_last_seen_old(context, 110);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    indexedAccount.new_total_balance_d8 == 249980000,
                                    indexedAccount.old_refundable_balance_d12 == 2499800000000,
                                    indexedAccount.old_balance_d12 == 2499800000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_refundable_balance_underflow_d12 == 0,
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
                                    indexedAccount.new_latest_send_txid == null
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with two old token Account-to-dApp transactions and one new token dApp-to-Account transaction (conversion) should yield a balance matching old a2d amounts - (2 * old_fee) - new_fee - new d2a amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp) 
                        // new: (115, 50000000, dapp, account) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(4));
                        TestUtil.log_last_seen_new(context, 115);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    indexedAccount.new_total_balance_d8 == 249979000,
                                    indexedAccount.old_refundable_balance_d12 == 2499790000000,
                                    indexedAccount.old_balance_d12 == 2999800000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_refundable_balance_underflow_d12 == 0,
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
                                    indexedAccount.new_latest_send_txid == ?115
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with two old token a2d transactions, one old token d2a transaction (refund) and one new token d2a transaction (conversion) should yield a balance matching old a2d amounts - (2 * old_fee) - old d2a amount - new_fee - new d2a amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        // new: (115, 50000000, dapp, account) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(5));
                        TestUtil.log_last_seen_old(context, 110);
                        TestUtil.log_last_seen_new(context, 115);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    indexedAccount.new_total_balance_d8 == 199979000,
                                    indexedAccount.old_refundable_balance_d12 == 1999790000000,
                                    indexedAccount.old_balance_d12 == 2499800000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_refundable_balance_underflow_d12 == 0,
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
                                    indexedAccount.new_latest_send_txid == ?115
                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Indexing account with two old a2d transactions, one old d2a transaction (refund), one new d2a transaction (conversion) and one new a2d transaction (accident) should yield a balance matching old a2d amounts - (2 * old_fee) - old d2a amount - new_fee - new d2a amount + new a2d amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp), (110, 500000000000, dapp, acct) 
                        // new: (115, 50000000, dapp, account), (125, 25000000, account, dapp)  
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(6));
                        TestUtil.log_last_seen_old(context, 110);
                        TestUtil.log_last_seen_new(context, 125);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        // NB: for old_refundable_balance_d12:
                        // One-way conversion only, so new a2d tx (accident) not credited to old refundable balance,
                        // but new d2a txs (conversion) are deducted, as are old d2a txs (refund).  
                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                assertAllTrue([ 
                                    indexedAccount.new_total_balance_d8 == 224979000,
                                    indexedAccount.old_refundable_balance_d12 == 1999790000000, 
                                    indexedAccount.old_balance_d12 == 2499800000000,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_refundable_balance_underflow_d12 == 0,
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
                                    indexedAccount.new_latest_send_txid == ?125
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
                                    indexedAccount.old_refundable_balance_d12 == 1234467891234, 
                                    indexedAccount.old_balance_d12 == 1234467891234,
                                    indexedAccount.new_total_balance_underflow_d8 == 0,
                                    indexedAccount.old_refundable_balance_underflow_d12 == 0,
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
                )
            ]
        );
    };
};