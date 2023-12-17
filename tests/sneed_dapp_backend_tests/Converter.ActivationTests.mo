import Array "mo:base/Array";
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
            "SneedConverter dApp Integration Tests",
            [
                it(
                    "Should not be able to call get_account before activation.",
                    do {

                        let context = TestUtil.get_context();
                        switch (await* Converter.get_account(context)) {
                            case (#Err(error)) { assertAllTrue([ error.message == "Converter application has not yet been activated." ]); };
                            case (#Ok(account)) { Debug.trap("Should not have been able to call get_account before activation!"); };
                        };

                    },
                ),
                it(
                    "Should not be able to call convert_account before activation.",
                    do {

                        let context = TestUtil.get_context();
                        switch (await* Converter.convert_account(context)) {
                            case (#Err(#NotActive)) { true };
                            case _ { Debug.trap("Should not have been able to call convert_account before activation!"); };
                        };

                    },
                ),
                it(
                    "Should not be able to call refund_account before activation.",
                    do {

                        let context = TestUtil.get_context();
                        switch (await* Converter.refund_account(context)) {
                            case (#Err(#NotActive)) { true };
                            case _ { Debug.trap("Should not have been able to call refund_account before activation!"); };
                        };

                    },
                ),
                it(
                    "Should not be able to call burn_old_tokens before activation.",
                    do {

                        let context = TestUtil.get_context();
                        switch (await* Converter.burn_old_tokens(context, 1000000000000)) {
                            case (#Err(#NotActive)) { true };
                            case _ { Debug.trap("Should not have been able to call burn_old_tokens before activation!"); };
                        };

                    },
                )/*,
                it(
                    "Get indexing information for account.",
                    do {

                        let context = get_context();
                        switch (await* Converter.get_account(context)) {
                            case (#Err(error)) { Debug.trap(error.message); false; };
                            case (#Ok(account)) {

                                assertAllTrue([
                                    account.new_total_balance_d8 == 1                             
                                ]);

                            };
                        };

                    },
                )*/
            ]
        );
    };
};