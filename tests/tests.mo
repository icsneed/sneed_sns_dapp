// Taken (with minor modifications) from https://github.com/NatLabs/icrc1
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";

import UnitTests "sneed_dapp_backend_tests/Converter.UnitTests";
import ActivationTests "sneed_dapp_backend_tests/Converter.ActivationTests";
import IndexingTests "sneed_dapp_backend_tests/Converter.IndexingTests";
import ConversionTests "sneed_dapp_backend_tests/Converter.ConversionTests";

import ActorSpec "/utils/ActorSpec";
import TestUtil "/utils/TestUtil";

actor Tests {
    let { run } = ActorSpec;

    let test_modules = [
        UnitTests.test,
        ActivationTests.test,
        IndexingTests.test,
        ConversionTests.test
    ];
    
    public func test_it() : async T.ConvertResult {
        let controller = await* get_controller();
        let context = TestUtil.get_account_context_with_mocks(controller, TestUtil.get_test_account(8));

        let convert_result = await* Converter.ConvertOldTokens(context, null);        
        convert_result
    };

    public func run_tests() : async () {
        let controller = await* get_controller();
        for (test in test_modules.vals()) {
            let success = ActorSpec.run([await test(controller)]);

            if (success == false) {
                Debug.trap("\1b[46;41mTests failed\1b[0m");
            } else {
                Debug.print("\1b[23;42;3m Success!\1b[0m");
            };
        };
    };

    private func get_controller() : async* Principal { 
        let controllers = await get_controllers();
        for (controller in controllers.vals()) {
            return controller;
        };
        return Principal.fromText("aaaaa-aa");
    };

    // taken from https://forum.dfinity.org/t/getting-a-canisters-controller-on-chain/7531
    let IC =
        actor "aaaaa-aa" : actor {
        // richer in ic.did
        canister_status : { canister_id : Principal } ->
            async { 
            settings : { controllers : [Principal] }
            };

        };

    private func get_controllers() : async [Principal] {
        let principal = Principal.fromActor(Tests);
        let status = await IC.canister_status({ canister_id = principal });
        return status.settings.controllers;
    };
};



