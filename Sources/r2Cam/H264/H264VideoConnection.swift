//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-03.
//

import Foundation
import AVFoundation

public class H264VideoConnection: VideoConnection, H264DecoderDelegate, NetworkClientDelegate {

    private let operationQueue = OperationQueue()
    private let parser: H264Parser
    private var decoder: H264Decodable
    private let client: NetworkClient

    private(set) public var mediaSize: CGSize?

    public weak var delegate: VideoConnectionDelegate?
    public weak var displayLayer: AVSampleBufferDisplayLayer? {
        didSet {
            decoder.displayLayer = displayLayer
        }
    }

    public init(client: NetworkClient) {
        self.client = client
        let decoder = H264Decoder()
        self.decoder = decoder
        self.parser = H264Parser(decoder: decoder)
        self.operationQueue.maxConcurrentOperationCount = 1
        client.delegate = self
        decoder.delegate = self
    }

    func h264Decoder(emitted sampleBuffer: CMSampleBuffer) {
        delegate?.videoConnection(received: sampleBuffer)
    }

    func h264Decoder(detected mediaSize: CGSize) {
        self.mediaSize = mediaSize
        delegate?.videoConnection(detected: mediaSize)
    }

    public func networkClient(received data: [UInt8]) {
        operationQueue.addOperation { [weak self] in
            guard let self else { return }

            do {
                try self.parser.parse(buffer: data)
            } catch {
                delegate?.videoConnection(error: error)
            }
        }
    }

    public func start() throws {
        parser.running = true
        try client.start()
    }

    public func stop() {
        parser.running = false
        client.stop()
    }
}
