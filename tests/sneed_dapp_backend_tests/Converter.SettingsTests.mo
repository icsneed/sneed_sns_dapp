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
            "SneedConverter dApp Settings Tests",
            [
                it(
                    "Calling get_settings should return the current settings.",
                    do {

                        let context = TestUtil.get_context_with_mocks(controller);
                        let settings = context.state.persistent.settings;

                        let get_settings_result = Converter.get_settings(context);

                        assertAllTrue([

                            get_settings_result.allow_conversions == settings.allow_conversions,
                            get_settings_result.allow_burns == settings.allow_burns,
                            get_settings_result.new_fee_d8 == settings.new_fee_d8,
                            get_settings_result.old_fee_d12 == settings.old_fee_d12,
                            get_settings_result.d8_to_d12 == settings.d8_to_d12,
                            get_settings_result.new_seeder_min_amount_d8 == settings.new_seeder_min_amount_d8,
                            get_settings_result.old_burner_min_amount_d12 == settings.old_burner_min_amount_d12,
                            get_settings_result.cooldown_ns == settings.cooldown_ns,
                            get_settings_result.max_transactions == settings.max_transactions

                        ]);
                    },
                ),
                it(
                    "Calling set_settings as controller should update the current settings.",
                    do {

                        let context = TestUtil.get_context_with_mocks(controller);
                        let new_settings : T.Settings = {
                            allow_conversions = false;
                            allow_burns = false;
                            new_fee_d8 = 12345678;
                            old_fee_d12 = 987654321;
                            d8_to_d12 = 9999;
                            new_seeder_min_amount_d8 = 99999999999;
                            old_burner_min_amount_d12 = 77777777777;
                            cooldown_ns = 42;
                            max_transactions = 123;                   
                        };

                        let old_settings = Converter.get_settings(context);

                        let set_settings_result = Converter.set_settings(context, new_settings);
                        switch (set_settings_result) {
                            case (false) { false; };
                            case (true) {

                                let get_settings_result = Converter.get_settings(context);

                                let log_item = TestUtil.must_get_latest_log_item(Converter.get_log(context), 0);
                                let set_settings_log_item = TestUtil.must_get_set_settings_log_item(?log_item);
                                let log_old_settings = set_settings_log_item.old_settings;
                                let log_new_settings = set_settings_log_item.new_settings;

                                assertAllTrue([

                                    get_settings_result.allow_conversions == new_settings.allow_conversions,
                                    get_settings_result.allow_burns == new_settings.allow_burns,
                                    get_settings_result.new_fee_d8 == new_settings.new_fee_d8,
                                    get_settings_result.old_fee_d12 == new_settings.old_fee_d12,
                                    get_settings_result.d8_to_d12 == new_settings.d8_to_d12,
                                    get_settings_result.new_seeder_min_amount_d8 == new_settings.new_seeder_min_amount_d8,
                                    get_settings_result.old_burner_min_amount_d12 == new_settings.old_burner_min_amount_d12,
                                    get_settings_result.cooldown_ns == new_settings.cooldown_ns,
                                    get_settings_result.max_transactions == new_settings.max_transactions,

                                    log_item.name == "set_settings",
                                    log_item.message == "Complete",
                                    log_item.convert == null,
                                    log_item.burn == null,
                                    log_item.set_canisters == null,
                                    log_item.exit == null,

                                    log_new_settings.allow_conversions == new_settings.allow_conversions,
                                    log_new_settings.allow_burns == new_settings.allow_burns,
                                    log_new_settings.new_fee_d8 == new_settings.new_fee_d8,
                                    log_new_settings.old_fee_d12 == new_settings.old_fee_d12,
                                    log_new_settings.d8_to_d12 == new_settings.d8_to_d12,
                                    log_new_settings.new_seeder_min_amount_d8 == new_settings.new_seeder_min_amount_d8,
                                    log_new_settings.old_burner_min_amount_d12 == new_settings.old_burner_min_amount_d12,
                                    log_new_settings.cooldown_ns == new_settings.cooldown_ns,
                                    log_new_settings.max_transactions == new_settings.max_transactions,

                                    log_old_settings.allow_conversions == old_settings.allow_conversions,
                                    log_old_settings.allow_burns == old_settings.allow_burns,
                                    log_old_settings.new_fee_d8 == old_settings.new_fee_d8,
                                    log_old_settings.old_fee_d12 == old_settings.old_fee_d12,
                                    log_old_settings.d8_to_d12 == old_settings.d8_to_d12,
                                    log_old_settings.new_seeder_min_amount_d8 == old_settings.new_seeder_min_amount_d8,
                                    log_old_settings.old_burner_min_amount_d12 == old_settings.old_burner_min_amount_d12,
                                    log_old_settings.cooldown_ns == old_settings.cooldown_ns,
                                    log_old_settings.max_transactions == old_settings.max_transactions

                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Calling set_settings with non-controller caller should result in a return value of false.",
                    do {

                        let account = TestUtil.get_test_account(1);
                        let context = TestUtil.get_caller_context(account.owner);
                        let new_settings : T.Settings = {
                            allow_conversions = false;
                            allow_burns = false;
                            new_fee_d8 = 12345678;
                            old_fee_d12 = 987654321;
                            d8_to_d12 = 9999;
                            new_seeder_min_amount_d8 = 99999999999;
                            old_burner_min_amount_d12 = 77777777777;
                            cooldown_ns = 42;
                            max_transactions = 123;                           
                        };

                        not Converter.set_settings(context, new_settings);
                    },
                )
            ]
        );
    };
};