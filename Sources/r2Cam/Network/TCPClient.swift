//
//  TCPClient.swift
//  
//
//  Created by Tord Wessman on 2024-05-02.
//

import Foundation
import Network

@available(iOS 13.0, macOS 10.15, *)
class TCPClient: NetworkClient {

    private let networkQueue: DispatchQueue
    private let connection: NWConnection
    weak var delegate: NetworkClientDelegate?

    private static func createParams() -> NWParameters {
        let parames = NWParameters(tls: nil, tcp: Self.tcpOptions)
        if let isOption = parames.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            isOption.version = .v4
        }
        parames.preferNoProxies = true
        parames.expiredDNSBehavior = .allow
        parames.multipathServiceType = .interactive
        parames.serviceClass = .interactiveVideo
        return parames
    }

    private static var tcpOptions: NWProtocolTCP.Options = {
        let options = NWProtocolTCP.Options()
        options.enableFastOpen = true
        options.connectionTimeout = 10
        return options
    }()

    init(host: String, port: UInt16, networkQueue: DispatchQueue? = nil) {
        let host = NWEndpoint.Host(host)
        let port = NWEndpoint.Port(integerLiteral: port)

        self.networkQueue = networkQueue ?? DispatchQueue(label: "tcp_queue_\(host)", qos: .userInitiated)
        self.connection = NWConnection(host: host, port: port, using: Self.createParams())

        connection.stateUpdateHandler = { [weak self] newState in
            guard let self else { return }

            switch newState {
            case .ready:
                self.receiveData()
            case .failed(let error):
                self.delegate?.networkClient(received: error)
            case .waiting(let error):
                self.delegate?.networkClient(received: error)
            default:
                break
            }
        }
    }

    func start() {
        connection.start(queue: networkQueue)
    }

    func stop() {
        connection.cancel()
    }

    func send(_ data: Data) async throws {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            self.connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
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
                self.delegate?.networkClient(received: error)
            }
            if error == nil {
                self.receiveData()
            }
        }
    }
}
