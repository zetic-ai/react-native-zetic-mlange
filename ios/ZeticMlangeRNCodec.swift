class ZeticMlangeRNCodec {
    enum CodecError: Error {
        case invalidInputType
        case conversionFailed
        case unexpectedSize(expected: Int, actual: Int)
    }
    
    static func encode(input: [Any]) throws -> [Data] {
        guard let arrays = input as? [[Any]] else {
            throw CodecError.invalidInputType
        }
        
        return try arrays.map { array -> Data in
            try encodeArray(array)
        }
    }
    
    static func decode(input: [Data]) throws -> [[Any]] {
        return try input.map { data -> [Any] in
            try decodeData(data)
        }
    }
    
    private static func encodeArray(_ array: [Any]) throws -> Data {
        // For numeric arrays (integers)
        if let intArray = array as? [NSNumber] {
            var bytes = intArray.map { UInt8(truncatingIfNeeded: $0.intValue) }
            return Data(bytes: &bytes, count: bytes.count)
        }
        
        // For floating point arrays
        if let floatArray = array as? [NSNumber] {
            var floats = floatArray.map { Float($0.doubleValue) }
            return Data(bytes: &floats, count: floats.count * MemoryLayout<Float>.size)
        }
        
        // Fallback to JSON serialization for other types
        // This is less efficient but handles mixed content
        if JSONSerialization.isValidJSONObject(array) {
            return try JSONSerialization.data(withJSONObject: array)
        }
        
        throw CodecError.conversionFailed
    }
    
    private static func decodeData(_ data: Data) throws -> [Any] {
        // Try to decode as JSON first
        do {
            if let result = try JSONSerialization.jsonObject(with: data) as? [Any] {
                return result
            }
        } catch {
            // JSON decoding failed, try other methods
        }
        
        // Try to decode as raw bytes (UInt8 array)
        let byteArray = [UInt8](data)
        return byteArray.map { NSNumber(value: $0) }
        
        // Add more decoders as needed for your specific data types
    }
    
    // Utility: Verify expected size
    static func verifySize(data: Data, expectedSize: Int) throws {
        if data.count != expectedSize {
            throw CodecError.unexpectedSize(expected: expectedSize, actual: data.count)
        }
    }
}
