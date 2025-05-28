/*
 
 Copyright (c) <2020>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */

import Foundation

/**
 Typed value strucutes for HeaderBlocks
 */
public protocol HDUValue : CustomStringConvertible {
    
    var hashable : AnyHashable { get }
    
    var toString : String { get }
    
    init?<F: FixedWidthInteger>(i: F)
}

struct AnyHDUValue {
    
    public static func parse(_ string: String, for keyword: HDUKeyword, context: Context?) -> Any? {
        
        let trimmed = string.trimmingCharacters(in: CharacterSet.whitespaces)
        
        switch keyword {
        case HDUKeyword.BITPIX:
            if let raw = Int(trimmed) {
                return FITS.BITPIX(rawValue: raw)
            }
        case HDUKeyword.DATE:
            let plainString = trimmed.trimmingCharacters(in: CharacterSet.init(arrayLiteral: "'"))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let date = dateFormatter.date(from: plainString ) {
                return date
            } else {
                return plainString
            }
        case _ where keyword.rawValue.starts(with: "TFORM"):
            if context is BintableHDU.Type {
                return FITS.BFORM.parse(trimmed)
            } else {
                return FITS.TFORM.parse(trimmed)
            }
        case _ where keyword.rawValue.starts(with: "TDISP"):
            if context is BintableHDU.Type {
                return FITS.BDISP.parse(trimmed)
            } else {
                return FITS.TDISP.parse(trimmed)
            }
        default:
            // autodetect explicit specified types
            if trimmed == "T" { return true}
            if trimmed == "F" { return false}
            if let integer = Int(trimmed) { return integer}
            if let float = Float(trimmed) { return float}
            if trimmed.starts(with: "'") {return trimmed.trimmingCharacters(in: CharacterSet.init(arrayLiteral: "'"))}
            
            let split = trimmed.split(separator: " ")
            if split.count == 2, let real = Double(split[0]), let imaginary = Double(split[1]){
                return FITSComplex(real, imaginary)
            }
        }
        
        //not found
        return nil
    }
    
}

extension HDUValue where Self : Hashable {
    
    public func hash(hasher: inout Hasher){
        hasher.combine(self)
    }
    
    public var hashable : AnyHashable {
        AnyHashable(self)
    }
}

extension String : HDUValue {
    
    public init?<F: FixedWidthInteger>(i: F){
        self.init("\(i)")
    }
    
    public var description: String {
        return "'\(self)'"
    }
    
    public var toString : String {
        return "'\(self)'"
    }
}

extension Bool : HDUValue {
    
    public var description: String {
        return self ? "T" : "F"
    }
    
    public var toString : String {
        return self ? "T" : "F"
    }
    
    public init?<F: FixedWidthInteger>(i: F) {
        self.init(i == 1)
    }
}

extension Float : HDUValue {
    
    public var description: String {
        "\(self)"
    }
    
    public var toString : String {
        return "\(self)"
    }
    
    public init?<F: FixedWidthInteger>(i: F) {
        self.init(i)
    }
}

extension Int : HDUValue {
    
    public var description: String {
        "\(self)"
    }
    
    public var toString : String {
        return "\(self)"
    }
    
    public init?<F: FixedWidthInteger>(i: F) {
        self.init(i)
    }
}

extension FITSComplex : HDUValue {
    
    public var description: String {
        "\(self)"
    }
    
    public var toString : String {
        return "\(self)"
    }
    
    public init?<F: FixedWidthInteger>(i: F) {
        return nil
    }
}

extension BITPIX : HDUValue {
    
    public var description: String {
        "\(self.rawValue)"
    }
    
    public var toString : String {
        return "\(self)"
    }
    
    public init?<F: FixedWidthInteger>(i: F) {
        self.init(rawValue: Int(i))
    }
}

extension Date : HDUValue {
    
    public var description: String {
        "\(self)"
    }
    
    public var toString : String {
        return "\(self)"
    }
    
    public init<F: FixedWidthInteger>(i: F) {
        self.init(timeIntervalSinceNow: Double(i))
    }
}

extension BFORM : HDUValue {

    public var toString : String {
        return "'\(self)'"
    }
    
    public init?<F: FixedWidthInteger>(i: F) {
        return nil
    }
}

extension TFORM : HDUValue {
    
    public var toString : String {
        return "'\(self)'"
    }
    
    public init?<F: FixedWidthInteger>(i: F) {
        return nil
    }
}

extension BDISP : HDUValue {
    
    public var toString : String {
        return "'\(self)'"
    }
    
    public init?<F: FixedWidthInteger>(i: F) {
        return nil
    }
}

extension TDISP : HDUValue {
    
    public var toString : String {
        return "'\(self)'"
    }
    
    public init?<F: FixedWidthInteger>(i: F) {
        return nil
    }
}

extension Optional : HDUValue, CustomStringConvertible where Wrapped : HDUValue & Hashable {
    
    public var hashable: AnyHashable {
        if let val = self {
            return AnyHashable(val)
        } else {
            return AnyHashable(UUID())
        }
    }
    
    public var toString: String {
        if let val = self {
            return val.toString
        } else {
            return ""
        }
    }
    
    public var description: String {
        if let val = self {
            return val.description
        } else {
            return "NIL"
        }
    }
    
    public init?<F: FixedWidthInteger>(i: F) {
        self = Wrapped.init(i: i)
    }
}
