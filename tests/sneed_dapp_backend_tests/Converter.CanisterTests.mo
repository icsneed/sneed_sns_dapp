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
            "SneedConverter dApp Canister Tests",
            [
                it(
                    "Calling get_canister_ids on inactive dApp should return anon canister ids.",
                    do {

                        let context = TestUtil.get_caller_context(controller);
                        let persistent = context.state.persistent;

                        let get_canister_ids_result = Converter.get_canister_ids(context);

                        assertAllTrue([

                            get_canister_ids_result.new_token_canister_id == persistent.new_token_canister,
                            get_canister_ids_result.new_indexer_canister_id == persistent.new_indexer_canister,
                            get_canister_ids_result.old_token_canister_id == persistent.old_token_canister,
                            get_canister_ids_result.old_indexer_canister_id == persistent.old_indexer_canister,

                            get_canister_ids_result.old_token_canister_id == Principal.fromText("2vxsx-fae"),
                            get_canister_ids_result.old_indexer_canister_id == Principal.fromText("2vxsx-fae"),
                            get_canister_ids_result.new_token_canister_id == Principal.fromText("2vxsx-fae"),
                            get_canister_ids_result.new_indexer_canister_id == Principal.fromText("2vxsx-fae"),

                        ]);
                    },
                ),it(
                    "Calling get_canister_ids on active dApp should return the current canister ids.",
                    do {

                        let context = TestUtil.get_context_with_mocks(controller);
                        let persistent = context.state.persistent;

                        let get_canister_ids_result = Converter.get_canister_ids(context);

                        assertAllTrue([

                            get_canister_ids_result.new_token_canister_id == persistent.new_token_canister,
                            get_canister_ids_result.new_indexer_canister_id == persistent.new_indexer_canister,
                            get_canister_ids_result.old_token_canister_id == persistent.old_token_canister,
                            get_canister_ids_result.old_indexer_canister_id == persistent.old_indexer_canister,

                            get_canister_ids_result.old_token_canister_id == Principal.fromText("b77ix-eeaaa-aaaaa-qaada-cai"),
                            get_canister_ids_result.old_indexer_canister_id == Principal.fromText("bw4dl-smaaa-aaaaa-qaacq-cai"),
                            get_canister_ids_result.new_token_canister_id == Principal.fromText("br5f7-7uaaa-aaaaa-qaaca-cai"),
                            get_canister_ids_result.new_indexer_canister_id == Principal.fromText("be2us-64aaa-aaaaa-qaabq-cai"),

                        ]);
                    },
                ),
                it(
                    "Calling set_canister_ids as controller should update the current settings.",
                    do {

                        let context = TestUtil.get_context_with_mocks(controller);
                        let old_token_canister_id = Principal.fromText("3xwpq-ziaaa-aaaah-qcn4a-cai");
                        let old_indexer_canister_id = Principal.fromText("jw7or-laaaa-aaaag-qctca-cai");
                        let new_token_canister_id = Principal.fromText("objst-kqaaa-aaaag-qcumq-cai");
                        let new_indexer_canister_id = Principal.fromText("suaf3-hqaaa-aaaaf-bfyoa-cai");

                        let old_canisters = Converter.get_canister_ids(context);

                        let set_canisters_result = Converter.set_canister_ids(context, 
                                                                                old_token_canister_id,
                                                                                old_indexer_canister_id,
                                                                                new_token_canister_id,
                                                                                new_indexer_canister_id);
                        switch (set_canisters_result) {
                            case (false) { false; };
                            case (true) {

                                let get_canister_ids_result = Converter.get_canister_ids(context);

                                let log_item = TestUtil.must_get_latest_log_item(Converter.get_log(context), 0);
                                let set_canisters_log_item = TestUtil.must_get_set_canisters_log_item(?log_item);
                                let log_old_canisters = set_canisters_log_item.old_canisters;
                                let log_new_canisters = set_canisters_log_item.new_canisters;

                                assertAllTrue([

                                    get_canister_ids_result.old_token_canister_id == old_token_canister_id,
                                    get_canister_ids_result.old_indexer_canister_id == old_indexer_canister_id,
                                    get_canister_ids_result.new_token_canister_id == new_token_canister_id,
                                    get_canister_ids_result.new_indexer_canister_id == new_indexer_canister_id,

                                    log_item.name == "set_canister_ids",
                                    log_item.message == "Complete",
                                    log_item.convert == null,
                                    log_item.burn == null,
                                    log_item.set_settings == null,
                                    log_item.exit == null,

                                    log_new_canisters.old_token_canister_id == old_token_canister_id,
                                    log_new_canisters.old_indexer_canister_id == old_indexer_canister_id,
                                    log_new_canisters.new_token_canister_id == new_token_canister_id,
                                    log_new_canisters.new_indexer_canister_id == new_indexer_canister_id,

                                    log_old_canisters.old_token_canister_id == old_canisters.old_token_canister_id,
                                    log_old_canisters.old_indexer_canister_id == old_canisters.old_indexer_canister_id,
                                    log_old_canisters.new_token_canister_id == old_canisters.new_token_canister_id,
                                    log_old_canisters.new_indexer_canister_id == old_canisters.new_indexer_canister_id,

                                ]);

                            };
                        };
                    },
                ),
                it(
                    "Calling set_canister_ids with non-controller caller should result in a return value of false.",
                    do {

                        let account = TestUtil.get_test_account(1);
                        let context = TestUtil.get_caller_context(account.owner);
                        let old_token_canister_id = Principal.fromText("3xwpq-ziaaa-aaaah-qcn4a-cai");
                        let old_indexer_canister_id = Principal.fromText("jw7or-laaaa-aaaag-qctca-cai");
                        let new_token_canister_id = Principal.fromText("objst-kqaaa-aaaag-qcumq-cai");
                        let new_indexer_canister_id = Principal.fromText("suaf3-hqaaa-aaaaf-bfyoa-cai");


                        not Converter.set_canister_ids(context, 
                                                        old_token_canister_id,
                                                        old_indexer_canister_id,
                                                        new_token_canister_id,
                                                        new_indexer_canister_id);
                    },
                )
            ]
        );
    };
};