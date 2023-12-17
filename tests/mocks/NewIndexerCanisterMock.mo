import T "../../src/Types";

shared actor class NewIndexerMock() : T.NewIndexerInterface = {

    public func get_account_transactions(request : T.NewIndexerRequest) : async T.GetNewTransactionsResult {
        #Ok({
            transactions = [];
            oldest_tx_id = null;
        })
    };

}