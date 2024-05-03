//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-02.
//

import Foundation
import Network

@available(iOS 13.0, macOS 10.15, *)
public class TCPClient: NetworkClient {

    private let networkQueue: DispatchQueue
    private let connection: NWConnection
    public weak var delegate: NetworkClientDelegate?

    public init(host: String, port: UInt16, networkQueue: DispatchQueue = DispatchQueue.global()) {
        let host = NWEndpoint.Host(host)
        let port = NWEndpoint.Port(integerLiteral: port)
        self.connection = NWConnection(host: host, port: port, using: .tcp)
        print("\(self.connection)")
        self.networkQueue = networkQueue
        connection.stateUpdateHandler = { [weak self] newState in
            guard let self else { return }

            switch newState {
            case .ready:
                print("Connected to server")
                self.receiveData()
            case .failed(let error):
                print("Connection failed: \(error)")
                self.delegate?.networkClient(received: error)
            case .cancelled:
                print("Connection cancelled")
            case .preparing:
                print("Connection is preparing")
            case .setup:
                print("Connection setup")
            case .waiting(let error):
                print("Connection waiting: \(error)")
            @unknown default:
                print("Got weird state: \(newState)")
            }
        }
    }

    public func start() {
        connection.start(queue: networkQueue)
    }

    public func stop() {
        connection.cancel()
    }

    public func send(_ data: Data) async throws {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            self.connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("Error sending data: \(error)")
                    return continuation.resume(throwing: error)
                }
                continuation.resume()
            })
        }
    }

    private func receiveData() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, _, isDone, error) in
            guard let self else { return }

            if let data = data {
                self.delegate?.networkClient(received: [UInt8](data))
            } else if let error = error {
                print("Error receiving data: \(error)")
                self.delegate?.networkClient(received: error)
            }
            self.receiveData()
        }
    }
}
