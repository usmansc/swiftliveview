//
//  JavaScriptEnumOptions.swift
//  Helper
//
//  Created by Lukáš Schmelcer on 19/01/2024.
//

import Foundation

/// Options for extending javaScript code via ``JavascriptLoader``
public enum JavaScriptEnumOptions {
    case clientMessageActions
    case serverMessageBaseActions
    case clientMessageBaseActions
    case communicationHubInterfaceActions
    case listenerBaseActions
}
