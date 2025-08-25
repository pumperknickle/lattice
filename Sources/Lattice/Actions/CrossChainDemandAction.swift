import UInt256

public struct CrossChainDemandAction {
    // "id" of demand
    let nonce: UInt128
    // cryptographic hash of recipient public key
    let recipient: UInt256
    // Total amount to send
    let amount: UInt64
    
    init(nonce: UInt128, recipient: UInt256, amount: UInt64) {
        self.nonce = nonce
        self.recipient = recipient
        self.amount = amount
    }
    
    init(recipient: UInt256, amount: UInt64) {
        nonce = UInt128.random(in: 0...UInt128.max)
        self.recipient = recipient
        self.amount = amount
    }
}

