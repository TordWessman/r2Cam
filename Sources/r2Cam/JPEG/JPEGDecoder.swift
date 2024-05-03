//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-02.
//

import CoreMedia
import UIKit

protocol JPEGDecoderDelegate: AnyObject {

    func jpegDecoder(detected mediaSize: CGSize)
}

class JPEGDecoder: FrameDecoder {

    enum Error: Swift.Error {
        case failedToCreateSampleBuffer(code: OSStatus)
        case failedToCreateImageFromData(dataSize: Int)
        case failedToCreatePixelBuffer
        case failedToCreateVideoFormatDescription
    }

    var defaultTimeScale: Int32 = 60

    private(set) var size: CGSize?

    weak var delegate: JPEGDecoderDelegate?

    func decode(frame: [UInt8]) throws -> CMSampleBuffer? {

        guard let image = UIImage(data: Data(frame)) else {
            throw Error.failedToCreateImageFromData(dataSize: frame.count)
        }

        if size != image.size {
            size = image.size
            delegate?.jpegDecoder(detected: image.size)
        }

        guard let pixelBuffer = image.pixelBuffer else {
            throw Error.failedToCreatePixelBuffer
        }

        var formatDesc: CMVideoFormatDescription?
        let status = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDesc)
        guard status == noErr, let formatDescription = formatDesc else {
            throw Error.failedToCreateVideoFormatDescription
        }

        let now = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: defaultTimeScale)
        let duration = CMTime(value: 1, timescale: defaultTimeScale)
        var timingInfo: CMSampleTimingInfo = CMSampleTimingInfo(duration: duration, presentationTimeStamp: now, decodeTimeStamp: .invalid)

        var sampleBuffer: CMSampleBuffer?

        let err = CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescription: formatDescription, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)

        if let sampleBuffer = sampleBuffer, err == noErr {
            return sampleBuffer
        } else {
            throw Error.failedToCreateSampleBuffer(code: err)
        }
    }
}
