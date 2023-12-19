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
            "SneedConverter dApp Activation Tests",
            [
                it(
                    "Should not be able to call get_account before activation.",
                    do {

                        let context = TestUtil.get_context();
                        switch (await* Converter.get_account(context)) {
                            case (#Err(error)) { error.message == "Converter application has not yet been activated." };
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
                    "Should not be able to call burn_old_tokens before activation.",
                    do {

                        let context = TestUtil.get_context();
                        switch (await* Converter.burn_old_tokens(context, 1000000000000)) {
                            case (#Err(#NotActive)) { true };
                            case _ { Debug.trap("Should not have been able to call burn_old_tokens before activation!"); };
                        };

                    },
                ),
                it(
                    "Should be able to call get_account after activation.",
                    do {

                        try {
                            let context = TestUtil.get_caller_active_context(controller);
                            let waste = await* Converter.get_account(context);
                            Debug.trap("Should not have been able to complete call to get_account with fake canister ids!");
                        } catch (e) {
                            Error.message(e) == "Canister czysu-eaaaa-aaaag-qcvdq-cai not found"
                        };

                    },
                ),
                it(
                    "Should be able to call convert_account after activation.",
                    do {

                        try {
                            let context = TestUtil.get_caller_active_context(controller);
                            let waste = await* Converter.convert_account(context);
                            Debug.trap("Should not have been able to complete call to convert_account with fake canister ids!");
                        } catch (e) {
                            Error.message(e) == "Canister czysu-eaaaa-aaaag-qcvdq-cai not found"
                        };

                    },
                ),
                it(
                    "Should be able to call burn_old_tokens after activation.",
                    do {

                        try {
                            let context = TestUtil.get_caller_active_context(controller);
                            let waste = await* Converter.burn_old_tokens(context, 1000);
                            Debug.trap("Should not have been able to complete call to burn_old_tokens with fake canister ids!");
                        } catch (e) {
                            Error.message(e) == "Canister czysu-eaaaa-aaaag-qcvdq-cai not found"
                        };

                    },
                ) 
            ]
        );
    };
};