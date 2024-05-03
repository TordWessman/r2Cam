//
//  NetworkClient.swift
//  
//
//  Created by Tord Wessman on 2024-05-03.
//

import Foundation

public protocol NetworkClient: AnyObject {

    /** Required for receiving data callback information. Required by connections, so don't set manually. */
    var delegate: NetworkClientDelegate? { get set }

    /** Connect to server. */
    func start() throws

    /** Disconnect from server. */
    func stop()
}

/** Callback for network client */
public protocol NetworkClientDelegate: AnyObject {

    /** A chunk of data was received. */
    func networkClient(received data: [UInt8])

    /** A network error was detected. */
    func networkClient(received error: Error)
}

extension NetworkClientDelegate {
    public func networkClient(received error: Error) {
        print("     ** NETWORK ERROR **\n\(error)")
    }
}

/** Not sure why this works, but it should be called as early as possible in an applications life cycle to display the networking dialog. */
public func triggerNetworkAuthorizationDialog() {
    DispatchQueue.main.async {
        print("\(ProcessInfo.processInfo.hostName)")
    }
}

