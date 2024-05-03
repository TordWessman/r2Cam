//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-02.
//

import Foundation

class JPEGParser: FrameParser {

    private var buffer = Data()
    let maxBufferSize: Int

    enum Error: Swift.Error {

        /** Indicates that no JPEG data was found */
        case maxBufferSizeReached
    }

    init(_ maxBufferSize: Int = 100_000) {
        self.maxBufferSize = maxBufferSize
    }

    func addBuffer(_ rawData: [UInt8]) throws {
        buffer.append(Data(rawData))

        if buffer.count > maxBufferSize {
            buffer.removeAll()
            throw Error.maxBufferSizeReached
        }
    }

    func parse() throws -> [UInt8]? {

        guard let soiRange = buffer.range(of: Data([0xFF, 0xD8])) else {
            buffer.removeAll()
            return nil
        }

        if soiRange.upperBound > buffer.endIndex {
            return nil
        }
        let eoiSearchRange = soiRange.upperBound..<buffer.endIndex

        guard let eoiRange = buffer.range(of: Data([0xFF, 0xD9]), in: eoiSearchRange) else {
            return nil
        }

        let frameData = buffer[soiRange.lowerBound..<eoiRange.upperBound]
        buffer.removeSubrange(..<eoiRange.upperBound)
        return [UInt8](frameData)
    }
}
