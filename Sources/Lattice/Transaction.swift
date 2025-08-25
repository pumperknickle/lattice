import Foundation
import Crypto

public struct TransactionInput {
    public let transactionId: String
    public let outputIndex: Int
    public let signature: String
    public let publicKey: String
    
    public init(transactionId: String, outputIndex: Int, signature: String = "", publicKey: String = "") {
        self.transactionId = transactionId
        self.outputIndex = outputIndex
        self.signature = signature
        self.publicKey = publicKey
    }
}

public struct TransactionOutput {
    public let address: String
    public let amount: Double
    
    public init(address: String, amount: Double) {
        self.address = address
        self.amount = amount
    }
}

public struct Transaction {
    public let id: String
    public let inputs: [TransactionInput]
    public let outputs: [TransactionOutput]
    public let timestamp: Date
    public let fee: Double
    
    public init(inputs: [TransactionInput], outputs: [TransactionOutput], fee: Double = 0.0) {
        self.inputs = inputs
        self.outputs = outputs
        self.fee = fee
        self.timestamp = Date()
        self.id = Transaction.calculateId(inputs: inputs, outputs: outputs, timestamp: self.timestamp)
    }
    
    public init(from: String, to: String, amount: Double, fee: Double = 0.0) {
        let input = TransactionInput(transactionId: "", outputIndex: 0, publicKey: from)
        let output = TransactionOutput(address: to, amount: amount)
        
        self.inputs = [input]
        self.outputs = [output]
        self.fee = fee
        self.timestamp = Date()
        self.id = Transaction.calculateId(inputs: self.inputs, outputs: self.outputs, timestamp: self.timestamp)
    }
    
    static func calculateId(inputs: [TransactionInput], outputs: [TransactionOutput], timestamp: Date) -> String {
        let inputData = inputs.map { "\($0.transactionId)\($0.outputIndex)\($0.publicKey)" }.joined()
        let outputData = outputs.map { "\($0.address)\($0.amount)" }.joined()
        let combinedData = inputData + outputData + "\(timestamp.timeIntervalSince1970)"
        
        let data = Data(combinedData.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    public var totalInputAmount: Double {
        return inputs.reduce(0) { sum, _ in
            return sum
        }
    }
    
    public var totalOutputAmount: Double {
        return outputs.reduce(0) { sum, output in
            return sum + output.amount
        }
    }
    
    public func isValid() -> Bool {
        return !id.isEmpty &&
               !inputs.isEmpty &&
               !outputs.isEmpty &&
               outputs.allSatisfy { $0.amount > 0 } &&
               fee >= 0
    }
    
    public static func createCoinbaseTransaction(to address: String, amount: Double) -> Transaction {
        let output = TransactionOutput(address: address, amount: amount)
        let coinbaseInput = TransactionInput(transactionId: "coinbase", outputIndex: 0, publicKey: "system")
        
        return Transaction(inputs: [coinbaseInput], outputs: [output], fee: 0.0)
    }
}