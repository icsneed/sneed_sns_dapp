import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";

import Converter "../../src/";
import T "../../src/Types";

import ActorSpec "../utils/ActorSpec";

module {

    public func get_context() : T.ConverterContext {

        let caller = Principal.fromText("aaaaa-aa");
        let account : T.Account = { 
            owner = Principal.fromText("aaaaa-aa");
            subaccount = null;
        };
        let converter : T.Account = { 
            owner = Principal.fromText("aaaaa-aa");
            subaccount = null;
        };

        let state = Converter.init();

        return {
            caller = caller;
            state = state;
            account = account;
            converter = converter;
        };
    };

    public func test() : async ActorSpec.Group {

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
            "SneedUpgrade Converter dApp Implementation Tests",
            [
                it(
                    "Should not be able to call get_account before activation.",
                    do {

                        let context = get_context();
                        switch (await* Converter.get_account(context)) {
                            case (#Err(error)) { assertAllTrue([ error.message == "Converter application has not yet been activated." ]); };
                            case (#Ok(account)) { Debug.trap("Should not have been able to use application before activation!"); };
                        };

                    },
                ),
                it(
                    "Should not be able to call convert_account before activation.",
                    do {

                        let context = get_context();
                        switch (await* Converter.convert_account(context)) {
                            case (#Err(#NotActive)) { assertAllTrue([ 1 == 1 ]); };
                            case _ { Debug.trap("Should not have been able to use application before activation!"); };
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