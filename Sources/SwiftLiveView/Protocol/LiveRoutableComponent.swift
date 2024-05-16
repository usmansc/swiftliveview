//
//  LiveRoutableComponent.swift
//  Protocol
//
//  Created by Lukáš Schmelcer on 05/11/2023.
//
//  swiftlint:disable:next blanket_disable_command
//  swiftlint:disable identifier_name
//

import Foundation
import Vapor

/// Represents component - website page
public protocol LiveRoutableComponent: Sendable, Identifiable where ID == String {
    associatedtype Context: Codable
    /// Provides context of component
    /// which can be any data that we want to manipulate
    /// - Returns: context of page
    func contextSnapshot() -> Context?
    /// Sets context of page
    /// can change internal state of component
    /// - Parameter context: context to set
    func loadFromContext(_ context: Context)

    var app: Application { get }
    /// path which this component represents
    var path: String { get }
    var webSocket: WebSocket? { get async }
    /// Base template of component
    /// - Returns: template which this component renders first
    func baseTemplate() async throws -> String

    /// Sets up query parameters from url
    /// - Parameters:
    ///   - parameters: parameters
    ///   - id: id of router that calls this action
    func setQueryParameters(_ parameters: [String: String], for id: UUID)
    /// Clean method to clean any data on
    /// page change
    /// - Parameter id: id of router
    func cleanUp(for id: UUID)
    /// Sends update message via webSocket
    /// - Parameters:
    ///   - ws: webSocket
    ///   - content: data to be sent
    func sendUpdate(via ws: WebSocket, content: Data)
    /// Accepts message from webSocket
    /// - Parameters:
    ///   - ws: webSocket
    ///   - message: message to react to
    func receiveMessage<ClientMessage: ClientMessageDecodable>(from ws: WebSocket, message: ClientMessage) async throws
    /// Broadcast message to all connected clients of app
    /// - Parameters:
    ///   - connections: array of webSocket connections
    ///   - content: content to be sent
    func broadCast<Content: Encodable>(to connections: [WebSocket], content: Content)
    /// Allow to set webSocket
    func webSocket(_ ws: WebSocket?)

}

public extension LiveRoutableComponent {
    var id: String {
        path
    }

    func setQueryParameters(_ parameters: [String: String], for id: UUID) { }

    func cleanUp(for id: UUID) { }

    func broadCast<Content: Encodable>(to connections: [WebSocket], content: Content) {
        connections.forEach { ws in
            self.sendUpdate(via: ws, content: content)
        }
    }

    func sendUpdate<Content: Encodable>(via ws: WebSocket, content: Content) {
        if let jsonResult = try? JSONEncoder().encode(content),
           let json = String(data: jsonResult, encoding: .utf8) {
            guard !ws.isClosed else {
                print("Could not send message, websocket is already closed")
                return
            }
            ws.send(json)
        }
    }
}
