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
            "SneedConverter dApp Burn Tests",
            [
                it(
                    "Burning should result in call to burn method of old token ledger requesting to burn the specified amount.",
                    do {

                        let context = TestUtil.get_context_with_mocks(controller);
                        let settings = context.state.persistent.settings;
                        let amount1 = 1000000000000; // 1 old token

                        let burn_result = await* Converter.burn_old_tokens(context, amount1);

                        switch (burn_result) {
                            case (#Err(err)) { Debug.print(debug_show(err)); Debug.trap("Failed:" # debug_show(err)); };
                            case (#Ok(tx_index)) {

                                let log_item_enter = TestUtil.must_get_latest_log_item(Converter.get_log(context), 2);
                                let log_item = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let log_item_exit = TestUtil.must_get_latest_log_item(Converter.get_log(context), 0);
                                let burn_log_item = TestUtil.must_get_burn_log_item(?log_item);
                                let exit_log_item = TestUtil.must_get_exit_log_item(?log_item_exit);

                                assertAllTrue([

                                    tx_index == 5678,
                                    TestUtil.is_ok_burn_result(?burn_log_item.result),
                                    log_item_enter.name == "burn_old_tokens",
                                    log_item.name == "BurnOldTokens",
                                    log_item_exit.name == "burn_old_tokens",
                                    log_item_enter.message == "Enter",
                                    log_item.message == "Complete",
                                    log_item_exit.message == "Exit",
                                    exit_log_item.convert_result == null,
                                    TestUtil.is_ok_burn_result(exit_log_item.burn_result),
                                    exit_log_item.trapped_message == "",
                                    burn_log_item.args.amount == amount1,
                                    burn_log_item.args.from_subaccount == null,
                                    burn_log_item.args.memo == null,
                                    burn_log_item.args.created_at_time == null,

                                ]);
                            };
                        };
                    },
                ),
                it(
                    "Calling burn when old ledger traps should result in #ExternalCanisterError error.",
                    do {

                        let context = TestUtil.get_context_with_mocks(controller);
                        let amount1 = 42000000000000; // 42 old tokens - special value, causes old indexer mock to trap
                        let burn_result = await* Converter.burn_old_tokens(context, amount1);
                        
                        switch (burn_result) {
                            case (#Err(#ExternalCanisterError({ message }))) { 

                                let log_item_enter = TestUtil.must_get_latest_log_item(Converter.get_log(context), 1);
                                let log_item_exit = TestUtil.must_get_latest_log_item(Converter.get_log(context), 0);
                                let exit_log_item = TestUtil.must_get_exit_log_item(?log_item_exit);
                                let expected_msg = "IC0503: Canister b77ix-eeaaa-aaaaa-qaada-cai trapped explicitly: Old ledger canister mock trapped.";

                                // The log should only contain the enter and exit messages, not the ConvertAccount Complete message
                                assertAllTrue([ 
                                    message == expected_msg, 
                                    log_item_enter.name == "burn_old_tokens",
                                    log_item_exit.name == "burn_old_tokens",
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
                    "Calling burn when settings.allow_burns is set to false should result in #BurnsNotAllowed error.",
                    do {

                        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(1));
                        let new_settings : T.Settings = {
                            allow_conversions = true;
                            allow_burns = false;
                            new_fee_d8 = 12345678;
                            old_fee_d12 = 987654321;
                            d8_to_d12 = 9999;
                            new_seeder_min_amount_d8 = 99999999999;
                            old_burner_min_amount_d12 = 77777777777;
                            cooldown_ns = 42;                                 
                        };

                        let ok = Converter.set_settings(context, new_settings);

                        let burn_result = await* Converter.burn_old_tokens(context, 10000000);
                        
                        switch (burn_result) {
                            case (#Err(#BurnsNotAllowed)) { true; };
                            case _ { false; };
                        };
                    },
                )
            ]
        );
    };
};