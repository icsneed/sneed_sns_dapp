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
                            case (#Err(#NotActive)) { true };
                            case _ { false; };
                        };

                    },
                ),
                it(
                    "Should not be able to call convert_account before activation.",
                    do {

                        let context = TestUtil.get_context();
                        switch (await* Converter.convert_account(context)) {
                            case (#Err(#NotActive)) { true };
                            case _ { false; };
                        };

                    },
                ),
                it(
                    "Should not be able to call burn_old_tokens before activation.",
                    do {

                        let context = TestUtil.get_context();
                        switch (await* Converter.burn_old_tokens(context, 1000000000000)) {
                            case (#Err(#NotActive)) { true };
                            case _ { false; };
                        };

                    },
                ),
                it(
                    "Should be able to call get_account after activation.",
                    do {

                        let context = TestUtil.get_caller_active_context(controller);
                        let result = await* Converter.get_account(context);
                        switch (result) {
                            case (#Err(#ExternalCanisterError({ message }))) { assertTrue( message == "Canister czysu-eaaaa-aaaag-qcvdq-cai not found" ); };
                            case _ { false; };
                        };

                    },
                ),
                it(
                    "Should be able to call convert_account after activation.",
                    do {

                        let context = TestUtil.get_caller_active_context(controller);
                        let result = await* Converter.convert_account(context);
                        switch (result) {
                            case (#Err(#ExternalCanisterError({ message }))) { assertTrue( message == "Canister czysu-eaaaa-aaaag-qcvdq-cai not found" ); };
                            case _ { false; };
                        };

                    },
                ),
                it(
                    "Should be able to call burn_old_tokens after activation.",
                    do {

                        let context = TestUtil.get_caller_active_context(controller);
                        let result = await* Converter.burn_old_tokens(context, 1000);
                        switch (result) {
                            case (#Err(#ExternalCanisterError({ message }))) { assertTrue( message == "Canister czysu-eaaaa-aaaag-qcvdq-cai not found" ); };
                            case _ { false; };
                        };

                    },
                ) 
            ]
        );
    };
};