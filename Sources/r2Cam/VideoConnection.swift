//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-02.
//

import Foundation
import CoreMedia
import AVFoundation

/** Object capable of fetching raw image data, create sample buffers and enqueue to an `AVSampleBufferDisplayLayer`. */
public protocol VideoConnection: AnyObject {

    /** Instantiate the media server connection and start streaming. */
    func start() throws

    /** Cancels the media stream and the network connection. */
    func stop()

    /** Display layer receiving sample buffers. If one prefer to handle this manually, use  the delegate method `videoConnection(received sampleBuffer: CMSampleBuffer)` instead. */
    var displayLayer: AVSampleBufferDisplayLayer? { get set }

    /** `VideoConnectionDelegate` for receiving streaming updates. */
    var delegate: VideoConnectionDelegate? { get set }

    /** Size of the input media. Will be set once detected. */
    var mediaSize: CGSize? { get }
}

/** Callbacks for a `VideoConnection`. */
public protocol VideoConnectionDelegate: AnyObject {

    /** Optional method. Will be called if an error occurred during streaming. */
    func videoConnection(error: Error)

    /** Optional method. Will be called whenever a new frame is received.  */
    func videoConnection(received sampleBuffer: CMSampleBuffer)

    /** Optional method. Will be called whenever the media size has been detected. */
    func videoConnection(detected mediaSize: CGSize)
}

public extension VideoConnectionDelegate {

    func videoConnection(error: Error) {
        print("    ** VIDEO CONNECTION ERROR **\n\(error)")
    }

    func videoConnection(received sampleBuffer: CMSampleBuffer) { }

    func videoConnection(detected mediaSize: CGSize) { }
}
