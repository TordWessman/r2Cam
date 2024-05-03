//
//  H264Parser.swift
//  
//
//  Created by Tord Wessman on 2024-05-03.
//

import Foundation

class H264Parser {

    private var nal: [UInt8]  = [UInt8]()

    private var numZeros: Int = 0
    private var gotHeader: Bool = false
    private var decoder: H264Decodable

    public var running: Bool = true { didSet {
        decoder.running = running
    }}

    init(decoder: H264Decodable) {
        self.decoder = decoder
    }

    public func parse(buffer: [UInt8]) throws {

        let zeroCount = 2

        for i in 0..<buffer.count {

            let b = buffer[Int(i)]
            if !running { break }

            if b == 0 { numZeros += 1 }

            else {

                if b == 1 && numZeros >= zeroCount {

                    while numZeros > zeroCount {

                        nal.append(0)
                        numZeros -= 1
                    }

                    if gotHeader {

                        if !self.running { break }
                        //print("nal: \(m_nal.count)")
                        try decoder.process(nal)
                    }

                    nal = [0, 0, 0, 1]
                    gotHeader = true

                }  else {

                    while numZeros > 0 {

                        nal.append(0)
                        numZeros -= 1
                    }

                    nal.append(b)
                }
                numZeros = 0
            }
        }
    }
}
