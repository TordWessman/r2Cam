//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-02.
//

import Foundation
import AVFoundation

@available(iOS 13.0, macOS 10.15, *)
public class JPEGVideoConnection: VideoConnection, NetworkClientDelegate, JPEGDecoderDelegate {

    private let parser: FrameParser
    private let decoder: FrameDecoder
    private let client: NetworkClient
    private let operationQueue = OperationQueue()

    private(set) public var mediaSize: CGSize?
    public weak var delegate: VideoConnectionDelegate?
    public weak var displayLayer: AVSampleBufferDisplayLayer?

    enum Error: Swift.Error {
        case displayLayerIDeallocated
    }

    public init(client: NetworkClient) {
        self.client = client
        self.parser = JPEGParser()
        let decoder = JPEGDecoder()
        self.decoder = decoder
        self.client.delegate = self
        decoder.delegate = self
        self.operationQueue.maxConcurrentOperationCount = 1
    }

    private func equeueFrame(sampleBuffer: CMSampleBuffer) throws {
        if let displayLayer, displayLayer.isReadyForMoreMediaData {
            displayLayer.enqueue(sampleBuffer)
            displayLayer.setNeedsDisplay()
        }
        if let delegate {
            delegate.videoConnection(received: sampleBuffer)
        }
    }

    private func decode(frame: [UInt8]) throws -> CMSampleBuffer? {
        var buffer: CMSampleBuffer?
        try DispatchQueue.main.sync {
            buffer = try self.decoder.decode(frame: frame)
        }
        return buffer
    }

    func jpegDecoder(detected mediaSize: CGSize) {
        delegate?.videoConnection(detected: mediaSize)
        self.mediaSize = mediaSize
    }

    public func networkClient(received data: [UInt8]) {
        operationQueue.addOperation { [weak self] in
            guard let self else { return }
            do {
                try self.parser.addBuffer(data)
                while let frame = try self.parser.parse() {
                    if let sampleBuffer = try self.decode(frame: frame) {
                        try self.equeueFrame(sampleBuffer: sampleBuffer)
                    }
                }
            } catch {
                delegate?.videoConnection(error: error)
            }
        }
    }

    public func start() throws {
        try client.start()
    }

    public func stop() {
        client.stop()
    }
}
