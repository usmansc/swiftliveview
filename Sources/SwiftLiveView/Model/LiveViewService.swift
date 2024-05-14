//
//  LiveViewService.swift
//  Model
//
//  Created by Lukas Schmelcer on 02/11/2023.
//

import Vapor

private struct LiveViewKey<ClientMessage: ClientMessageDecodable>: StorageKey {
    typealias Value = LiveViewHandler<ClientMessage>
}

public extension Application {
    typealias ClientMessage = ClientMessageDecodable

    /// Provides live view handler associated with app
    /// - Returns: ``LiveViewHandler`` handler
    func liveViewHandler<ClientMessage: ClientMessageDecodable>() -> LiveViewHandler<ClientMessage> {
        return self.storage[LiveViewKey.self] ?? .init(
            configuration: LiveViewHandlerConfiguration<ClientMessage>(
                app: self,
                router: LiveRouter {_, _, _, _ in return },
                privateKeySecret: "",
                publicKeySecret: "",
                onCloseStrategy: .deleteConnection(after: .infinity)
            ) { [] }
        )
    }

    /// Associates ``LiveViewHandler`` with app
    /// - Parameter value: ``LiveViewHandler`` to associate with app
    func setLiveViewHandler<ClientMessage: ClientMessageDecodable>(_ value: LiveViewHandler<ClientMessage>) {
        self.storage[LiveViewKey<ClientMessage>.self] = value
    }
}
