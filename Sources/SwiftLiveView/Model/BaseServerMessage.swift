//
//  BaseServerMessage.swift
//  Model
//
//  Created by Lukáš Schmelcer on 03/04/2024.
//

import Foundation

// Response from the server
public struct BaseServerMessage: Encodable {
    public var value: String
    private let action: Action

    public enum Action: Encodable {
        case remove(selector: String)
        case setTitle(title: String)
        case insertNode(target: String)
        case replaceBody
        case appendNode(target: String)
        case addAttribute(target: String, attributes: [NodeAttribute])
        case removeAttribute(target: String, attributes: [NodeAttribute])
        case addStyle
        case addStyleTo(target: String)
        case removeStyle(target: String)
        case setInput(target: String)
        case updateNodeValue(target: String)
    }

    public init(value: String, action: Action) {
        self.value = value
        self.action = action
    }
}

public struct NodeAttribute: Encodable {
    let name: String
    let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
