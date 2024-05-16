//
//  LiveRouter.swift
//  Model
//
//  Created by Lukáš Schmelcer on 15/11/2023.
//
//  swiftlint:disable:next blanket_disable_command
//  swiftlint:disable identifier_name
//

import Foundation
import Vapor

/// Errors associated with ``LiveRouter``
public enum LiveRouterErrors: Error {
    case noPath
    case noInvalidPathTemplateSpecified
}

fileprivate final class ProtectedValue<T: Sendable>: @unchecked Sendable {
    private let queue = DispatchQueue(label: "LiveRouterValue")
    private var value: T

    init(_ value: T) {
        self.value = value
    }

    func withValue<U>(do block: (inout T) throws -> U) rethrows -> U {
        return try queue.sync {
            try block(&self.value)
        }
    }
}

/// Router that manages components for client
public final class LiveRouter<ComponentID: Hashable, ClientMessage: ClientMessageDecodable>: @unchecked Sendable {
    private struct State: Sendable {
        var webSocket: WebSocket?
        var currentComponent: (any LiveRoutableComponent)?
        var paths: [(any LiveRoutableComponent)]
        var task: Task<Void, Never>?
    }
    let id: UUID
    private var state: ProtectedValue<State>
    var currentComponent: (any LiveRoutableComponent)? {
        get {
            state.withValue(do: \.currentComponent)
        }
        set {
            state.withValue { router in
                router.currentComponent = newValue
            }
        }
    }
    var paths: [(any LiveRoutableComponent)] {
        get {
            state.withValue(do: \.paths)
        }
        set {
            state.withValue { router in
                router.paths = newValue
            }
        }
    }
    var webSocket: WebSocket? {
        get {
            state.withValue(do: \.webSocket)
        }
        set {
            state.withValue { router in
                router.webSocket = newValue
            }
        }
    }
    private let _handleMessage: (LiveRouter, Request, ClientMessage, WebSocket) async -> Void
    private let invalidPathTemplate: (() -> String)?

    /// Creates ``LiveRouter``
    /// - Parameters:
    ///   - invalidPathTemplate: template to render when there is invalid
    ///   path request
    ///   - handleMessage: closure which decides how to handle message from client
    public init(invalidPathTemplate: (() -> String)? = nil,
                handleMessage: @escaping (LiveRouter, Request, ClientMessage, WebSocket) async -> Void) {
        self.id = .init()
        self.invalidPathTemplate = invalidPathTemplate
        self.state = ProtectedValue(State(webSocket: nil, currentComponent: nil, paths: [], task: nil))
        _handleMessage = handleMessage
    }

    /// Passes message to currently selected component
    /// - Parameters:
    ///   - message: message
    ///   - socket: webSocket connection
    public func passMessageToCurrentComponent(_ message: ClientMessage, from socket: WebSocket) async {
        try? await self.currentComponent?.receiveMessage(from: socket, message: message)
    }

    /// Changes URL
    /// - Parameters:
    ///   - req: request
    ///   - ws: webSocket
    ///   - url: requested URL
    ///   - token: `JWT` token of client
    public func changeURL(_ req: Request,
                          _ ws: WebSocket,
                          to url: String,
                          for token: String) async throws {
        if !self.setActive(url: url) {
            guard let invalidPathTemplate else {
                throw LiveRouterErrors.noInvalidPathTemplateSpecified
            }
            let value = invalidPathTemplate()
            if let jsonResult = try? JSONEncoder().encode(URLChangeEncodable(.replaceBody(with: value))),
               let json = String(data: jsonResult, encoding: .utf8) {
                try await ws.send(json)
            }
            return
        }
        if let jsonResult = try? await JSONEncoder().encode(URLChangeEncodable(.replaceBody(with: render()))),
           let json = String(data: jsonResult, encoding: .utf8) {
            try await ws.send(json)
        }
    }

    /// Handles message from client
    /// - Parameters:
    ///   - message: message
    ///   - webSocket: webSocket connection
    ///   - request: request
    ///   - inactiveInterval: intrval of inactivity after we want to perform `onCloseStrategy`
    ///   - onCloseStrategy: steps to perform when connection becomes inactive for certain period
    ///   of time
    internal func handleMessage(message: ClientMessage,
                                from webSocket: WebSocket,
                                request: Request,
                                inactiveInterval: TimeInterval,
                                onCloseStrategy: @escaping (Any?, Any?) -> Void) async {
        state.withValue { router in
            router.task?.cancel()
            router.task = Task {
                do {
                    try await Task.sleep(nanoseconds: UInt64(inactiveInterval * 1_000_000_000))
                    onCloseStrategy(message, currentComponent)
                } catch {
                    print("Failed to perform onCloseStrategy due to tak failure or cancellation")
                }
            }
        }

        await _handleMessage(self, request, message, webSocket)
    }

    /// Parses query parameters from URL
    /// - Parameter urlString: url string
    /// - Returns: tupel of parameters and path without query parameters
    private func parseQueryParameters(from urlString: String) -> ([String: String]?, String?) {
        let urlStringWithBase = "https://example.com" + urlString // prepend placeholder
        guard let url = URL(string: urlStringWithBase) else {
            return (nil, nil)
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return (nil, urlString)
        }
        var parameters = [String: String]()
        for queryItem in queryItems {
            if let value = queryItem.value {
                parameters[queryItem.name] = value
            }
        }
        let pathWithoutQuery = components.path
        return (parameters, pathWithoutQuery)
    }

    /// Renders component base template
    /// - Returns: component base template
    private func render() async throws -> String {
        if let currentComponent = currentComponent {
            try await currentComponent.baseTemplate()
        } else {
            throw LiveRouterErrors.noPath
        }
    }

    /// Sets active url
    /// - Parameter url: url
    /// - Returns: true if url change was successful
    private func setActive(url: String) -> Bool {
        let queryParameters = parseQueryParameters(from: url)
        let id = self.id
        if let currentComponent {
            currentComponent.cleanUp(for: id) // Run to clean any mess from the component
            if let indexOfActiveComponent = paths.firstIndex(where: { component in
                component.id == currentComponent.id
            }) {
                paths[indexOfActiveComponent] = currentComponent
            }
        }
        guard let url = queryParameters.1 else { return false }
        guard let component = paths.first(where: { component in
            component.path == url
        }) else { return false }

        component.setQueryParameters(queryParameters.0 ?? [:], for: id)
        currentComponent = component
        return true
    }

    /// Copies router
    /// - Returns: copy of router
    func copy() -> LiveRouter {
        return LiveRouter(invalidPathTemplate: invalidPathTemplate, handleMessage: _handleMessage)
    }
}

/// Default message to send when there is URL change
private struct URLChangeEncodable: Encodable {
    let action: Action
    init(_ action: Action) {
        self.action = action
    }
    public enum Action: Codable {
        case replaceBody(with: String)
    }
}
