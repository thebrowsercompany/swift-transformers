//
//  MLShapedArray+Utils.swift
//  
//
//  Created by Pedro Cuenca on 13/5/23.
//

import CoreML

public extension MLShapedArray<Float> {
    var floats: [Float] {
        guard self.strides.first == 1, self.strides.count == 1 else {
            // For some reason this path is slow.
            // If strides is not 1, we can write a Metal kernel to copy the values properly.
            return self.scalars
        }
        
        // Fast path: memcpy
        let mlArray = MLMultiArray(self)
        return mlArray.floats ?? self.scalars
    }
}

public extension MLShapedArraySlice<Float> {
    var floats: [Float] {
        guard self.strides.first == 1, self.strides.count == 1 else {
            // For some reason this path is slow.
            // If strides is not 1, we can write a Metal kernel to copy the values properly.
            return self.scalars
        }

        // Fast path: memcpy
        let mlArray = MLMultiArray(self)
        return mlArray.floats ?? self.scalars
    }
}

public extension MLMultiArray {
    var floats: [Float]? {
        guard self.dataType == .float32 else { return nil }
        
        var result = [Float](repeating: 0, count: self.count)
        
        if #available(macOS 12.3, *) {
            return self.withUnsafeBytes { ptr in
                guard let source = ptr.baseAddress else { return nil }
                result.withUnsafeMutableBytes { resultPtr in
                    let dest = resultPtr.baseAddress!
                    memcpy(dest, source, self.count * MemoryLayout<Float>.stride)
                }
                return result
            }
        } else {
            let bytes = self.dataPointer
            let floatBytes = bytes.bindMemory(to: Float.self, capacity: self.count)
            
            for i in 0..<self.count {
                result[i] = floatBytes[i]
            }
            
            return result
        }
    }
}
