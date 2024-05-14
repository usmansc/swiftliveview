//
//  WebsocketInitializer.swift
//  Middleware
//
//  Created by Lukáš Schmelcer on 02/11/2023.
//

import Vapor

/// Middleware that provides client side javaScript code
public struct WebsocketInitializer: Middleware {
    let clientSideJavascript: String

    /// Creates middleware
    /// - Parameter javascriptLoader: ``JavascriptLoader`` that will be used to load client side code
    public init(javascriptLoader: JavaScriptLoader? = nil) {
        var loader: JavaScriptLoader
        if let javascriptLoader {
            loader = javascriptLoader
        } else {
            do {
                loader = try .init()
            } catch {
                fatalError("Fatal error occured during initialisation of loader \(error.localizedDescription)")
            }
        }

        clientSideJavascript = """
        <script>
            \(loader.content)
        </script>
        """
    }

    /// Responses to request
    /// - Parameters:
    ///   - request: request
    ///   - next: next responder
    /// - Returns: response
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).map { response in
            if let data = response.body.string, request.content.contentType == .html || data.contains("html") {
                response.body = .init(string: inject(javascript: clientSideJavascript, to: data))
                return response
            } else {
                return response
            }
        }
    }

    /// Use this function to inject javascript code into html string
    /// - Parameter javascript: javascript code to be inserted wrapped in <script></script>
    /// - Parameter data: html string data
    internal func inject(javascript: String, to data: String) -> String {
        var data = data
        if let headRange = data.range(of: "</head>") {
            data.insert(contentsOf: javascript, at: headRange.lowerBound)
        } else if let bodyEndRange = data.range(of: "</body>", options: .caseInsensitive) {
            data.insert(contentsOf: javascript, at: bodyEndRange.lowerBound)
        } else {
            data.insert(contentsOf: javascript, at: data.startIndex)
        }
        return data
    }
}
