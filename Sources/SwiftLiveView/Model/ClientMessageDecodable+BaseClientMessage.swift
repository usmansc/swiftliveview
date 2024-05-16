//
//  ClientMessage.swift
//  Model
//
//  Created by Lukáš Schmelcer on 26/10/2023.
//

import Foundation

/// Protocol which client message representations should confrom to
public protocol ClientMessageDecodable: Decodable, Sendable {
    var authToken: String { get }
}

/// Base client message representation
/// Should correspond to messages that are sent from client
public struct BaseClientMessage<Action: Decodable & Sendable>: ClientMessageDecodable {
    public let id: String?
    public let value: String?

    public let action: Action
    public let authToken: String
    public let metadata: [String: String]?
}
