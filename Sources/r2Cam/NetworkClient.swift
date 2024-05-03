//
//  File.swift
//  
//
//  Created by Tord Wessman on 2024-05-03.
//

import Foundation

public protocol NetworkClientDelegate: AnyObject {

    func networkClient(received data: [UInt8])
    func networkClient(received error: Error)
}

extension NetworkClientDelegate {
    public func networkClient(received error: Error) {
        print("     ** NETWORK ERROR **\n\(error)")
    }
}

public protocol NetworkClient: AnyObject {

    var delegate: NetworkClientDelegate? { get set }
    func start() throws
    func stop()
}

public extension NetworkClient {

    func triggerNetworkAuthorizationDialog() {
        DispatchQueue.main.async {
            print("\(ProcessInfo.processInfo.hostName)")
        }
    }
}
