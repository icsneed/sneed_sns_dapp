import T "../../src/Types";

shared actor class OldIndexerMock() : T.OldIndexerInterface = {

    public func get_account_transactions(account : Text) : async [T.OldTransaction] {
        [];
    };

    public func synch_archive_full(token: Text) : async T.OldSynchStatus {
        {
            tx_total = 1234;
            tx_synched = 1233;
        };
    };

}