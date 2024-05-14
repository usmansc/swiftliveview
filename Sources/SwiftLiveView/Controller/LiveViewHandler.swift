//
//  LiveViewHandler.swift
//  Controller
//
//  Created by Lukas Schmelcer on 10/11/2023.
//
//  swiftlint:disable:next blanket_disable_command
//  swiftlint:disable identifier_name
//

import Vapor
import JWT

/// Completion that is fired after certain
/// time interval of webSocket connection inactivity
public enum WebSocketCloseStrategy {
    case deleteConnection(after: TimeInterval)
    case moveToSwap(after: TimeInterval, completion: (Any?, Any?) -> Void)
}

/// Configuartion for ``LiveViewHandler``
public struct LiveViewHandlerConfiguration<ClientMessage: ClientMessageDecodable> {
    let app: Application
    let router: LiveRouter<String, ClientMessage>
    let privateKeySecret: String
    let publicKeySecret: String
    let componentFactory: () -> [(any LiveRoutableComponent)]
    let onConnectionCreated: ((LiveRouter<String, ClientMessage>?) -> Void)?
    let onCloseStrategy: WebSocketCloseStrategy

    /// Creates configuration for ``LiveViewHandler``
    /// - Parameters:
    ///   - app: Application reference
    ///   - router: Router for application
    ///   - privateKeySecret: private key to sign `JWT`
    ///   - publicKeySecret: public key for `JWT`
    ///   - onCloseStrategy: webSocket inactivity strategy
    ///   - componentFactory: factory method which returns all components for router
    ///   - onConnectionCreated: closure which gives user access to router after its initialisation
    public init(app: Application,
                router: LiveRouter<String, ClientMessage>,
                privateKeySecret: String,
                publicKeySecret: String,
                onCloseStrategy: WebSocketCloseStrategy,
                componentFactory: @escaping () -> [(any LiveRoutableComponent)],
                onConnectionCreated: ((LiveRouter<String, ClientMessage>?) -> Void)? = nil) {
        self.app = app
        self.router = router
        self.privateKeySecret = privateKeySecret
        self.publicKeySecret = publicKeySecret
        self.componentFactory = componentFactory
        self.onCloseStrategy = onCloseStrategy
        self.onConnectionCreated = onConnectionCreated
    }
}

/// Main handler for webSocket connections
public final actor LiveViewHandler<ClientMessage: ClientMessageDecodable> {
    public var routerConnection: [String: LiveRouter<String, ClientMessage>] = [:]
    private(set) var connections: [WebSocket] = []
    private let staticRouter: LiveRouter<String, ClientMessage>
    private let configuration: LiveViewHandlerConfiguration<ClientMessage>
    private let queue = DispatchQueue(label: "swift-live-score-close-queue")

    private let app: Application

    /// Creates new handler
    /// - Parameter configuration: handler configuration
    public init(configuration: LiveViewHandlerConfiguration<ClientMessage>) {
        app = configuration.app
        staticRouter = configuration.router
        self.configuration = configuration
        do {
            let privateSigner = try JWTSigner.rs256(key: .private(pem: configuration.privateKeySecret))
            let publicSigner = try JWTSigner.rs256(key: .public(pem: configuration.publicKeySecret))
            self.app.jwt.signers.use(privateSigner, kid: .private)
            self.app.jwt.signers.use(publicSigner, kid: .public, isDefault: true)
        } catch {
            print(error, " while estabilishing jwt keys and signers")
        }
    }

    /// Provides caller with all active webSocket connections
    /// for handler
    /// - Returns: array of webSocket connections
    public func connections() async -> [WebSocket] {
        connections
    }

    /// Incoming webSocket connection handler
    /// - Parameters:
    ///   - req: request
    ///   - ws: webSocket
    public func handleWebsocket(_ req: Request, _ ws: WebSocket) async {
        _ = ws.onClose.always { _ in
            if let index = self.connections.firstIndex(where: { $0 === ws }) {
                self.connections.remove(at: index)
            }
        }
        do {
            try await initializeComponentsFor(req, ws)
        } catch {
            try? await ws.close()
        }

        connections.append(ws)

        ws.onText { ws, text in
            guard let data = text.data(using: .utf8),
                  let message = try? JSONDecoder().decode(ClientMessage.self, from: data) else {
                try? await ws.close()
                return
            }
            do {
                try TokenAuthenticator.authenticate(token: message.authToken, for: req)
                switch self.configuration.onCloseStrategy {
                case .deleteConnection(after: let interval):
                    await self.routerConnection[message.authToken]?.handleMessage(message: message,
                                                                                  from: ws,
                                                                                  request: req,
                                                                                  inactiveInterval: interval,
                                                                                  onCloseStrategy: { _, _ in })
                case .moveToSwap(after: let interval, completion: let completion):
                    await self.routerConnection[message.authToken]?.handleMessage(message: message,
                                                                                  from: ws,
                                                                                  request: req,
                                                                                  inactiveInterval: interval,
                                                                                  onCloseStrategy: completion)
                }
            } catch {
                try? await ws.close()
            }
        }
    }

    /// Performs initialization of the components
    /// for the given connection
    /// - Parameters:
    ///   - req: request
    ///   - ws: webSocket
    private func initializeComponentsFor(_ req: Request, _ ws: WebSocket) async throws {
        let token = try req.query.get(String.self, at: "authToken")
        let initialURL = try req.query.get(String.self, at: "initialURL")
        try TokenAuthenticator.authenticate(token: token, for: req)

        if routerConnection[token] == nil {
            assignRouter(token: token, webSocket: ws)
        }
        for index in 0..<(routerConnection[token]?.paths.count ?? 0) {
            routerConnection[token]?.paths[index].webSocket = ws
        }
        routerConnection[token]?.webSocket = ws
        try await routerConnection[token]?.changeURL(req, ws, to: initialURL, for: token)
        guard let onConnectionCreated = configuration.onConnectionCreated else { return }
        onConnectionCreated(routerConnection[token])
    }

    /// Assigns router for client
    /// - Parameters:
    ///   - token: authentication token to identify client
    ///   - webSocket: webSocket connection
    private func assignRouter(token: String, webSocket: WebSocket) {
        routerConnection[token] = staticRouter.copy()
        routerConnection[token]?.paths = configuration.componentFactory()
        routerConnection[token]?.webSocket = webSocket
    }
}
