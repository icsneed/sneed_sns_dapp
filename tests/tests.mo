// Taken (with minor modifications) from https://github.com/NatLabs/icrc1
import Debug "mo:base/Debug";

import UnitTests "sneed_dapp_backend_tests/Converter.UnitTests";
import IntegrationTests "sneed_dapp_backend_tests/Converter.IntegrationTests";

import ActorSpec "./utils/ActorSpec";

actor {
    let { run } = ActorSpec;

    let test_modules = [
        UnitTests.test,
        IntegrationTests.test
    ];

    public func run_tests() : async () {
        for (test in test_modules.vals()) {
            let success = ActorSpec.run([await test()]);

            if (success == false) {
                Debug.trap("\1b[46;41mTests failed\1b[0m");
            } else {
                Debug.print("\1b[23;42;3m Success!\1b[0m");
            };
        };
    };
};



