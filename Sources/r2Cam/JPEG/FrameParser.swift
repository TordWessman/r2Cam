//
//  FrameParser.swift
//  
//
//  Created by Tord Wessman on 2024-05-02.
//

import Foundation

protocol FrameParser {
    func addBuffer(_ rawData: [UInt8]) throws
    func parse() throws -> [UInt8]?
}
