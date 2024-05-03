//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-02.
//

import CoreMedia

protocol FrameDecoder {

    func decode(frame: [UInt8]) throws -> CMSampleBuffer?
}
