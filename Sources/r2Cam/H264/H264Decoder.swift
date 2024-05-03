//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-03.
//

import Foundation
import AVFoundation
import VideoToolbox
import Photos

protocol H264Decodable {

    func decode(_ nal: [UInt8]) throws
    func process(_ nal: [UInt8]) throws
    var displayLayer: AVSampleBufferDisplayLayer? { get set }
    var running: Bool { get set }

}

protocol H264DecoderDelegate: AnyObject {
    func h264Decoder(emitted sampleBuffer: CMSampleBuffer)
}

class H264Decoder: NSObject, H264Decodable {

    private var formatDescription: CMVideoFormatDescription?
    private var fullsps: [UInt8]?
    private var fullpps: [UInt8]?
    private var sps: [UInt8]?
    private var pps: [UInt8]?
    private var queue: OperationQueue

    var running: Bool = true
    weak var displayLayer: AVSampleBufferDisplayLayer?
    weak var delegate: H264DecoderDelegate?

    enum Error: Swift.Error {
        case pointerAddressError
        case spsAndppsNotSet
        case blockBufferCreateWithMemoryBlock(status: OSStatus)
        case CMSampleBufferCreateError(status: OSStatus)
        case unableToRetrieveFormatDescriptor(status: OSStatus)
    }

    public override init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        super.init()
    }

    private func reset() {
        sps = nil
        pps = nil
        formatDescription = nil
    }

    private func create() throws {

        guard let sps, let pps else {
            throw Error.spsAndppsNotSet
        }

        formatDescription = nil
        let sizes = [pps.count, sps.count]
        try sizes.withUnsafeBufferPointer { sizes in
            try pps.withUnsafeBufferPointer { pps in
                try sps.withUnsafeBufferPointer { sps in
                    guard let ppsPointer = pps.baseAddress, let spsPointer = sps.baseAddress else {
                        throw Error.pointerAddressError
                    }
                    let parameters = [ppsPointer, spsPointer]

                    try parameters.withUnsafeBufferPointer { parameters in
                        guard let parametersPointer = parameters.baseAddress, let sizesPointer = sizes.baseAddress else {
                            throw Error.pointerAddressError
                        }
                        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault, parameterSetCount: 2, parameterSetPointers: parametersPointer, parameterSetSizes: sizesPointer, nalUnitHeaderLength: 4, formatDescriptionOut: &formatDescription)

                        if status != noErr  {
                            throw Error.unableToRetrieveFormatDescriptor(status: status)
                        }
                    }
                }
            }
        }
//        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription!)
//
//        // create the decoder parameters
//        let decoderParameters = NSMutableDictionary()
//        let destinationPixelBufferAttributes = NSMutableDictionary()
//        destinationPixelBufferAttributes.setValue(NSNumber(value: kCVPixelFormatType_32BGRA), forKey: kCVPixelBufferPixelFormatTypeKey as String)
    }
    public func process(_ nal: [UInt8]) throws
    {
        var nal = nal
        // replace the start code with the NAL size
        let len = nal.count - 4
        var lenBig = CFSwapInt32HostToBig(UInt32(len))
        memcpy(&nal, &lenBig, 4)

        let nalType = nal[4] & 0x1F

        if nalType == 7 {
            fullsps = nal
        } else if nalType == 8 {
            fullpps = nal
        }

        if fullsps != nil && fullpps != nil {
            reset()
            sps = Array(fullsps![4...])
            pps = Array(fullpps![4...])

            try create()
            sps = nil
            pps = nil

            fullsps = nil
            fullpps = nil
        }

        if  formatDescription != nil
            && (nalType == 1 || nalType == 5) {
            try decode(nal)
        }
    }

    public func decode(_ nal: [UInt8]) throws {

        var blockBuffer: CMBlockBuffer? = nil
        var nal = nal
        try nal.withUnsafeMutableBufferPointer { nal in
            guard let nalPointer = nal.baseAddress else {
                throw Error.pointerAddressError
            }

            var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nalPointer, blockLength: nal.count, blockAllocator: kCFAllocatorNull, customBlockSource: nil, offsetToData: 0, dataLength: nal.count, flags: 0, blockBufferOut: &blockBuffer)

            if status != kCMBlockBufferNoErr {
                throw Error.blockBufferCreateWithMemoryBlock(status: status)
            }

            var sampleBuffer: CMSampleBuffer?
            let sampleSizeArray = [nal.count]
            status = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer, formatDescription: formatDescription, sampleCount: 1, sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: 1, sampleSizeArray: sampleSizeArray, sampleBufferOut: &sampleBuffer)

            if status != noErr  {
                throw Error.CMSampleBufferCreateError(status: status)
            }

            if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer!, createIfNecessary: true) {

                let dictionary = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
                CFDictionarySetValue(dictionary, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                     Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())

            }

            if let buffer = sampleBuffer, CMSampleBufferGetNumSamples(buffer) > 0 {
                if let displayLayer {
                    if displayLayer.isReadyForMoreMediaData == true {
                        displayLayer.enqueue(buffer)
                        displayLayer.setNeedsDisplay()
                    } else {
                        print("not ready")
                    }
                }

                if let delegate {
                    delegate.h264Decoder(emitted: buffer)
                }
            }
        }
    }
}
