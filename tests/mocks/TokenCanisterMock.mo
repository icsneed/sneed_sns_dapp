import T "../../src/Types";

shared actor class TokenMock() : T.TokenInterface = {

    public func icrc1_transfer(args : T.TransferArgs) : async T.TransferResult {
        #Ok(1234)
    };

    public func burn(args : T.BurnArgs) : async T.TransferResult {
        #Ok(5678)
    };

}