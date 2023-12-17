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

                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(2));

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                TestUtil.print_indexed_account(indexedAccount);
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
                    "Indexing account with two old token Account-to-dApp transactions and one new token dApp-to-Account transaction (conversion) should yield a balance matching to-dApp amounts - (2 * old_fee) - new_fee - from-dApp amount.",
                    do {

                        // old: (100, 1000000000000, acct, dapp), (105, 2000000000000, acct, dapp) 
                        // new: (115, 50000000, dapp, account) 
                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(3));

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                TestUtil.print_indexed_account(indexedAccount);
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