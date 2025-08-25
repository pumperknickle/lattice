import UInt256

// stored using the nonce
public struct CrossChainDepositAction {
    // Address depositing funds
    let address: UInt256
    // total amount for deposit (and what can be withdrawn later) is newBalance - oldBalance
    let oldBalance: UInt64
    let newBalance: UInt64
    let demand: CrossChainDemandAction
    
    init(address: UInt256, oldBalance: UInt64, newBalance: UInt64, demand: CrossChainDemandAction) {
        self.address = address
        self.oldBalance = oldBalance
        self.newBalance = newBalance
        self.demand = demand
    }
    
    init(oldBalance: UInt64, newBalance: UInt64, demand: CrossChainDemandAction) {
        address = demand.recipient
        self.oldBalance = oldBalance
        self.newBalance = newBalance
        self.demand = demand
    }
}
