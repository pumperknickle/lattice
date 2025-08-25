import Foundation
import Crypto

public struct CryptoUtils {
    
    public static func generateKeyPair() -> (privateKey: String, publicKey: String) {
        let privateKey = P256.Signing.PrivateKey()
        let publicKeyData = privateKey.publicKey.rawRepresentation
        let privateKeyData = privateKey.rawRepresentation
        
        let publicKeyHex = publicKeyData.map { String(format: "%02x", $0) }.joined()
        let privateKeyHex = privateKeyData.map { String(format: "%02x", $0) }.joined()
        
        return (privateKeyHex, publicKeyHex)
    }
    
    public static func sign(message: String, privateKeyHex: String) -> String? {
        guard let privateKeyData = Data(hex: privateKeyHex),
              let privateKey = try? P256.Signing.PrivateKey(rawRepresentation: privateKeyData) else {
            return nil
        }
        
        let messageData = Data(message.utf8)
        guard let signature = try? privateKey.signature(for: messageData) else {
            return nil
        }
        
        return signature.rawRepresentation.map { String(format: "%02x", $0) }.joined()
    }
    
    public static func verify(message: String, signature: String, publicKeyHex: String) -> Bool {
        guard let publicKeyData = Data(hex: publicKeyHex),
              let publicKey = try? P256.Signing.PublicKey(rawRepresentation: publicKeyData),
              let signatureData = Data(hex: signature),
              let ecdsaSignature = try? P256.Signing.ECDSASignature(rawRepresentation: signatureData) else {
            return false
        }
        
        let messageData = Data(message.utf8)
        return publicKey.isValidSignature(ecdsaSignature, for: messageData)
    }
    
    public static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    public static func ripemd160(_ input: String) -> String {
        return sha256(input)
    }
    
    public static func createAddress(from publicKey: String) -> String {
        let hash1 = sha256(publicKey)
        let hash2 = ripemd160(hash1)
        return "1" + hash2.prefix(32)
    }
}

extension Data {
    init?(hex: String) {
        let cleanHex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        
        guard cleanHex.count % 2 == 0 else { return nil }
        
        var data = Data()
        var index = cleanHex.startIndex
        
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            let byteString = String(cleanHex[index..<nextIndex])
            
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            
            index = nextIndex
        }
        
        self = data
    }
    
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}