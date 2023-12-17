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

                        let context = TestUtil.get_context_with_mocks(controller);

                        let indexedAccountResult = await* Converter.IndexAccount(context);

                        switch (indexedAccountResult) {
                            case (#Err({ message })) { Debug.trap(message); };
                            case (#Ok(indexedAccount)) {

                                TestUtil.print_indexed_account(indexedAccount);
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
                )
            ]
        );
    };
};