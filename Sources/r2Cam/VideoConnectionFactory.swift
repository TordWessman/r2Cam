//
//  VideoConnectionFactory.swift
//  
//
//  Created by Tord Wessman on 2024-05-03.
//

import Foundation

@available(iOS 13.0, macOS 10.15, *)
public class VideoConnectionFactory {

    public static let shared = VideoConnectionFactory()

    public enum StreamType {
        case jpeg(host: String, port: UInt16)
        case h264(host: String, port: UInt16)
    }

    public enum ConnectionType {
        case tcp
    }

    public func create(_ type: StreamType, connectionType: ConnectionType = .tcp) -> VideoConnection {

        switch (type) {
        case .jpeg(let host, let port):
            let client = TCPClient(host: host, port: port)
            return JPEGVideoConnection(client: client)
        case .h264(let host, let port):
            let client = TCPClient(host: host, port: port)
            return H264VideoConnection(client: client)
        }
    }
}
