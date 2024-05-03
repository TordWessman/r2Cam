//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-02.
//

import Foundation
import AVFoundation

@available(iOS 13.0, macOS 10.15, *)
public class JPEGVideoConnection: NetworkClientDelegate, VideoConnection {

    private let parser: FrameParser
    private let decoder: FrameDecoder
    private let client: NetworkClient
    public weak var delegate: VideoConnectionDelegate?
    public weak var displayLayer: AVSampleBufferDisplayLayer?

    private let operationQueue = OperationQueue()

    enum Error: Swift.Error {
        case displayLayerIDeallocated
    }
    public convenience init(host: String, port: UInt16) {
        self.init(client: TCPClient(host: host, port: port))
    }

    public init(client: NetworkClient) {
        self.client = client
        self.parser = JPEGParser()
        self.decoder = JPEGDecoder()
        self.client.delegate = self
        self.operationQueue.maxConcurrentOperationCount = 1
    }

    private func equeueFrame(sampleBuffer: CMSampleBuffer) throws {
        guard let displayLayer else { throw Error.displayLayerIDeallocated }
        
        if displayLayer.isReadyForMoreMediaData {
            displayLayer.enqueue(sampleBuffer)
            displayLayer.setNeedsDisplay()
        }
        //delegate?.videoConnection(received: sampleBuffer)

        //Task { @MainActor [weak self] in
         //   self?.config.delegate.videoConnection(received: sampleBuffer)
        //}
    }

    private func decode(frame: [UInt8]) throws -> CMSampleBuffer? {
        var buffer: CMSampleBuffer?
        try DispatchQueue.main.sync {
            buffer = try self.decoder.decode(frame: frame)
        }
        return buffer
//        let decodeTask = Task { @MainActor [weak self] () -> CMSampleBuffer? in
//            guard let self else { return nil }
//            return try await self.config.decoder.decode(frame: frame)
//        }
//        let result = await decodeTask.result
//        return try result.get()
    }

    public func networkClient(received data: [UInt8]) {
        operationQueue.addOperation {
            Task { [weak self] in
                guard let self else { return }
                do {
                    try self.parser.addBuffer(data)
                    while let frame = try self.parser.parse() {
                        if let sampleBuffer = try self.decode(frame: frame) {

                            try self.equeueFrame(sampleBuffer: sampleBuffer)
                        }
                    }
                } catch {
                    print(error)
                    delegate?.videoConnection(error: error)
                }
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
