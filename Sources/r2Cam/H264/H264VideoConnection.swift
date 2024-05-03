//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-03.
//

import Foundation
import AVFoundation

public class H264VideoConnection: H264DecoderDelegate, NetworkClientDelegate, VideoConnection {

    private let operationQueue = OperationQueue()
    //let parser = H264Parser(decoder: <#T##H264Decoder#>)
    private let parser: H264Parser
    private var decoder: H264Decodable
    private let client: NetworkClient
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
        try client.start()
    }

    public func stop() {
        client.stop()
    }
}
