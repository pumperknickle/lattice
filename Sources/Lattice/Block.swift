import Foundation
import Crypto
import cashew

public struct Block: Node {
    public func get(property: PathSegment) -> (any cashew.Address)? {
        <#code#>
    }
    
    public func properties() -> Set<PathSegment> {
        <#code#>
    }
    
    public func set(properties: [PathSegment : any cashew.Address]) -> Block {
        <#code#>
    }
    
    public let index: UInt64
    public let previousBlock: HeaderImpl<Block>
    public let timestamp: UInt64
    public let nonce: UInt64
    
}

//
//public struct BlockHeader {
//    public let index: UInt64
//    public let previousHash: String
//    public let merkleRoot: String
//    public let timestamp: Int64  // Milliseconds since epoch
//    public let difficulty: UInt32
//    public let nonce: UInt64
//    
//    public init(index: UInt64, previousHash: String, merkleRoot: String, timestamp: Int64, difficulty: UInt32, nonce: UInt64 = 0) {
//        self.index = index
//        self.previousHash = previousHash
//        self.merkleRoot = merkleRoot
//        self.timestamp = timestamp
//        self.difficulty = difficulty
//        self.nonce = nonce
//    }
//}
//
//public struct Block {
//    public let header: BlockHeader
//    public let transactions: [Transaction]
//    public let hash: String
//    
//    public init(header: BlockHeader, transactions: [Transaction]) {
//        self.header = header
//        self.transactions = transactions
//        self.hash = Block.calculateHash(header: header, transactions: transactions)
//    }
//    
//    public init(index: UInt64, previousHash: String, transactions: [Transaction], difficulty: UInt32 = 4) {
//        let merkleRoot = Block.calculateMerkleRoot(transactions: transactions)
//        let header = BlockHeader(
//            index: index,
//            previousHash: previousHash,
//            merkleRoot: merkleRoot,
//            timestamp: Int64(Date().timeIntervalSince1970 * 1000), // Convert to milliseconds
//            difficulty: difficulty
//        )
//        self.header = header
//        self.transactions = transactions
//        self.hash = Block.calculateHash(header: header, transactions: transactions)
//    }
//    
//    static func calculateHash(header: BlockHeader, transactions: [Transaction]) -> String {
//        let headerData = "\(header.index)\(header.previousHash)\(header.merkleRoot)\(header.timestamp)\(header.difficulty)\(header.nonce)"
//        let transactionData = transactions.map { $0.id }.joined()
//        let combinedData = headerData + transactionData
//        
//        let data = Data(combinedData.utf8)
//        let hash = SHA256.hash(data: data)
//        return hash.compactMap { String(format: "%02x", $0) }.joined()
//    }
//    
//    static func calculateMerkleRoot(transactions: [Transaction]) -> String {
//        if transactions.isEmpty {
//            return String(repeating: "0", count: 64)
//        }
//        
//        var hashes = transactions.map { transaction in
//            let data = Data(transaction.id.utf8)
//            let hash = SHA256.hash(data: data)
//            return hash.compactMap { String(format: "%02x", $0) }.joined()
//        }
//        
//        while hashes.count > 1 {
//            var newHashes: [String] = []
//            
//            for i in stride(from: 0, to: hashes.count, by: 2) {
//                let left = hashes[i]
//                let right = i + 1 < hashes.count ? hashes[i + 1] : left
//                
//                let combined = left + right
//                let data = Data(combined.utf8)
//                let hash = SHA256.hash(data: data)
//                newHashes.append(hash.compactMap { String(format: "%02x", $0) }.joined())
//            }
//            
//            hashes = newHashes
//        }
//        
//        return hashes.first ?? String(repeating: "0", count: 64)
//    }
//    
//    public func isValid(previousBlock: Block?) -> Bool {
//        if let prevBlock = previousBlock {
//            return header.previousHash == prevBlock.hash &&
//                   header.index == prevBlock.header.index + 1 &&
//                   hash == Block.calculateHash(header: header, transactions: transactions)
//        } else {
//            return header.index == 0 && header.previousHash.isEmpty
//        }
//    }
//}
