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

extension FitsFile {
    
    
    public static func read(contentsOf url: URL, options: Data.ReadingOptions = []) throws -> FitsFile? {
        
        let data = try Data(contentsOf: url, options: options)
        return self.read(data)
        
    }
    
    public static func read(_ data: Data) -> FitsFile? {
        
        var context = ReaderContext(dataLenght: data.count, offset: 0, primaryHeader: nil, currentHDU: nil, msg: [])
        
        defer {
            context.currentHDU = nil
            context.currentHeader = nil
            context.primaryHeader = nil
        }
        
        return data.withUnsafeBytes { bytes in
            FitsFile.read(bytes, context: &context)
        }
        
    }
    
}


extension FitsFile : FITSReader {
    
    static func read(_ data: UnsafeRawBufferPointer, context: inout ReaderContext) -> FitsFile? {
        
        guard let prime = PrimaryHDU.read(data, context: &context) else {
            print("Reading primary HDU failed!")
            return nil
        }
        
        let new = FitsFile(prime: prime)
        context.primaryHeader = prime.headerUnit
        
        while context.offset < context.dataLenght {
        
            // continue reading the data as header
            guard let card = HeaderBlock.read(data, context: &context) else {
                context.msg.append("Malformatted HDU found at offset \(context.offset)")
                return new
            }
            
            var newHDU : AnyHDU?
            if !card.isXtension {
                // also not supposed to happen
                print("Missing extension keyword")
                print(card)
                return new
                // throw FitsFail.malformattedHDU
            }
            
            if card.value?.description.contains("IMAGE   ") ?? false {
                newHDU = ImageHDU.read(data, context: &context)
            } else if card.value?.description.contains("TABLE   ") ?? false {
                if let new = TableHDU.read(data, context: &context) {
                    
                    //new.readTable()
                    
                    // move back the cursor to read the dataUnit as table
                    context.offset -= context.currentHeader?.paddeddataSize ?? 0
                    new.readTable(data, context: &context)
                    context.offset += context.currentHeader?.paddeddataSize ?? 0
                    newHDU = new
                }
            } else if card.value?.description.contains("BINTABLE") ?? false {
                if let new = BintableHDU.read(data, context: &context) {
                    
                    //new.buildTable()
                    
                    // move back the cursor to read the dataUnit as table
                    context.offset -= context.currentHeader?.paddeddataSize ?? 0
                    new.readTable(data, context: &context)
                    context.offset += context.currentHeader?.paddeddataSize ?? 0
                    newHDU = new
                }
            } else {
                newHDU = AnyHDU.read(data, context: &context)
            }
            
            //print(newHDU.debugDescription)
            if let hdu = newHDU {
                new.HDUs.append(hdu)
            }
        
        }
            
        return new
        
    }
    
}
