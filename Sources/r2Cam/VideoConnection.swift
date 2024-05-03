//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-02.
//

import Foundation
import CoreMedia
import AVFoundation

public protocol VideoConnection: AnyObject {

    func start() throws
    func stop()
    var displayLayer: AVSampleBufferDisplayLayer? { get set }
}

public protocol VideoConnectionDelegate: AnyObject {

    func videoConnection(error: Error)
    func videoConnection(received sampleBuffer: CMSampleBuffer)
}

public extension VideoConnectionDelegate {

    func videoConnection(error: Error) {
        print("    ** VIDEO CONNECTION ERROR **\n\(error)")
    }
    func videoConnection(received sampleBuffer: CMSampleBuffer) { }
    
}
