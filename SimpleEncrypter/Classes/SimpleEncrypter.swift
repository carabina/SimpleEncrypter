//
//  Encrypter.swift
//
//  Created by Alfred Gao on 2016/10/28.
//  Copyright © 2016年 Alfred Gao. All rights reserved.
//

import Foundation
import CryptoSwift
import SwiftCompressor

/// 数据加密协议
///
/// a simple protocol
public protocol SimpleEncrypter {
    var key: String { get }
    init(with key: String)
    func encrypt(_ plaintext: Data) -> Data
    func decrypt(_ cyphertext: Data) -> Data
}

/// 不加密，此类主要用做占位符
///
/// do nothing, this class used for a spaceholder
public class EncrypterNone: NSObject, SimpleEncrypter {
    
    public let key: String
    required public init(with key: String) {
        self.key = key
    }
    
    public func encrypt(_ plaintext: Data) -> Data {
        return plaintext
    }
    public func decrypt(_ cyphertext: Data) -> Data {
        return cyphertext
    }
}

/// 压缩
///
/// Compress (not entrypt) data with same protocol
public class EncrypterCompress: NSObject, SimpleEncrypter {
    
    private let _algorithm: CompressionAlgorithm
    public let key: String
    
    /// - parameter with:
    ///     - 压缩算法
    ///     - compress algorithm
    ///     - "lz4"|"lzma"|zlib"|"lzfse", lzfse is the default
    required public init(with key: String) {
        self.key = key
        switch key {
        case "lz4", "LZ4":
            _algorithm = .lz4
        case "lzma", "LZMA":
            _algorithm = .lzma
        case "zlib", "ZLIB":
            _algorithm = .zlib
        default:
            _algorithm = .lzfse
        }
    }
    
    public func encrypt(_ plaintext: Data) -> Data {
        var cyphertext = Data()
        do {
            cyphertext = try plaintext.compress(algorithm: _algorithm)!
        } catch {
        }
        return cyphertext
    }
    public func decrypt(_ cyphertext: Data) -> Data {
        var plaintext = Data()
        do {
            plaintext = try cyphertext.decompress(algorithm: _algorithm)!
        } catch {
        }
        return plaintext
    }
}

/// AES
public class EncrypterAES: NSObject, SimpleEncrypter {
    public let key: String
    let iv: String
    required public init(with key: String) {
        self.key = key
        iv = key.md5().substring(to: key.index(key.startIndex, offsetBy: 16))
    }
    
    public func encrypt(_ plaintext: Data) -> Data {
        var cyphertext = Data()
        do {
            cyphertext = try plaintext.encrypt(cipher: AES(key: key, iv: iv))
        } catch {
        }
        return cyphertext
    }
    public func decrypt(_ cyphertext: Data) -> Data {
        var plaintext = Data()
        do {
            plaintext = try cyphertext.decrypt(cipher: AES(key: key, iv: iv))
        } catch {
        }
        return plaintext
    }
}

/// XOR
///
/// 加密能力很弱，效果更像“混淆”。不过速度很快
///
/// Fast
public class EncrypterXor: NSObject, SimpleEncrypter {
    public let key: String
    let binarykey: Data
    required public init(with key: String) {
        self.key = key
        self.binarykey = key.data(using: .utf8)!.md5()
        super.init()
    }
    
    private func xor(inData: Data) -> Data {
        var xorData = inData
        
        xorData.withUnsafeMutableBytes { (start: UnsafeMutablePointer<UInt8>) -> Void in
            binarykey.withUnsafeBytes { (keyStart: UnsafePointer<UInt8>) -> Void in
                let b = UnsafeMutableBufferPointer<UInt8>(start: start, count: xorData.count)
                let k = UnsafeBufferPointer<UInt8>(start: keyStart, count: binarykey.count)
                let length = binarykey.count
                
                for i in 0..<xorData.count {
                    b[i] ^= k[i % length]
                }
            }
        }
        
        return xorData
    }
    
    public func encrypt(_ plaintext: Data) -> Data {
        return xor(inData: plaintext)
    }
    public func decrypt(_ cyphertext: Data) -> Data {
        return xor(inData: cyphertext)
    }
}
