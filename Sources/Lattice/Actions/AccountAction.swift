import UInt256

public struct AccountAction {
    let address: UInt256
    let oldBalance: UInt64
    let newBalance: UInt64
    
    init(address: UInt256, oldBalance: UInt64, newBalance: UInt64) {
        self.address = address
        self.oldBalance = oldBalance
        self.newBalance = newBalance
    }
}
