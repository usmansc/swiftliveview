//
//  JavascriptLoader.swift
//  Helper
//
//  Created by Lukáš Schmelcer on 01/11/2023.
//
//  swiftlint:disable file_length
//  swiftlint:disable:next blanket_disable_command
//  swiftlint:disable identifier_name
//

import Foundation
#if canImport(JavaScriptCore)
import JavaScriptCore
#endif

public enum JavaScriptLoaderError: Error {
    case resourceFileNotFound
    case invalidJavaScriptLoaded
}

/// Loader of client side javaScript
public struct JavaScriptLoader {
#if canImport(JavaScriptCore)
    private let context: JSContext
#endif
    private let fileLoader: FileLoader
    private var clientMessage = "ClientMessageBase"
    private var serverMessage = "ServerMessageBase"
    private var listener = "ListenerBase"
    private var evaluator = "EvaluatorBase"
    private var _content: String = ""
    private(set) var content: String {
        get {
            initJsCode()
        } set {
            _content = newValue
        }
    }
    private var _registering: String = ""
    private var _localContextClientMessageActions: String = ""
    private var _localContextClientMessageBaseActions: String = ""
    private var _localContextCommunicationHubInterfaceActions: String = ""
    private var _localContextEvaluatorBaseActions: String = ""
    private var _localContextListenerBaseActions: String = ""
    private var _localContextServerMessageBaseActions: String = ""
    private var _localContextClientMessageBase = ""
    private var _localContextCommunicationHubInterface = ""
    private var _localContextEvaluatorBase = ""
    private var _localContextListenerBase = ""
    private var _localContextServerMessageBase = ""
    private var _baseTypes: String = ""
    private var _evaluatorBase: String = ""
    private var _serverMessageBase: String = ""
    private var _clientMessageBase: String = ""
    private var overridenServerMessageBaseActions: String?
    private var overridenClientMessageActions: String?
    private var _isEvaluatorProperlyImplemented: (Bool, Bool) = (false, false)

    /// Formats extended code
    /// - Parameter content: extended code
    /// - Returns: formated extended code
    private func formatExtendedEnumeration(_ content: String) -> String {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return ""}
        return content.contains("}") ? content : content + "}"
    }

    /// Puts together javaScript code that will be sent
    /// to client
    /// - Returns: final javaScript code
    private func initJsCode() -> String {
    """
        \(_baseTypes);
        \(formatExtendedEnumeration(_localContextClientMessageActions))
        \(formatExtendedEnumeration(_localContextClientMessageBaseActions))
        \(formatExtendedEnumeration(_localContextCommunicationHubInterfaceActions))
        \(formatExtendedEnumeration(_localContextEvaluatorBaseActions))
        \(formatExtendedEnumeration(_localContextListenerBaseActions))
        \(formatExtendedEnumeration(_localContextServerMessageBaseActions))

        \(_localContextClientMessageBase)
        \(_localContextCommunicationHubInterface)
        \(_localContextServerMessageBase)
        \(_localContextListenerBase)
        \(_localContextEvaluatorBase)


        const listener = new \(listener)('/api/issue-token', '/websocket');
        const serverMessage = new \(serverMessage)();
        const evaluator = new \(evaluator)();
        const clientMessage = new \(clientMessage)(false);
        \(_registering);
        const communicationManager = new CommunicationHub(listener, evaluator, serverMessage, clientMessage);
    """
    }

    /// Created ``JavascriptLoader`` with default source file foled path
    /// - Parameter sourceFileFolderPath: optional folder path
    public init(sourceFileFolderPath: String? = nil) throws {
#if canImport(JavaScriptCore)
        guard let ctx = JSContext() else {
            fatalError()
        }
        context = ctx
#endif
        if let sourceFileFolderPath {
            fileLoader = .init(primaryFilePath: sourceFileFolderPath)
        } else {
            fileLoader = .init()
        }

        let module = Bundle.module
        guard
            let clientMessageActionsURL = module.url(forResource: "ClientMessageActions", withExtension: "js"),
            let clientMessageBaseActionsURL = module.url(forResource: "ClientMessageBaseActions", withExtension: "js"),
            let communicationHubInterfaceActionsURL = module.url(forResource: "CommunicationHubInterfaceActions",
                                                                 withExtension: "js"),
            let evaluatorBaseActionsURL = module.url(forResource: "EvaluatorBaseActions", withExtension: "js"),
            let listenerBaseActionsURL = module.url(forResource: "ListenerBaseActions", withExtension: "js"),
            let serverMessageBaseAcitonsURL = module.url(forResource: "ServerMessageBaseActions", withExtension: "js"),
            let clientMessageBaseURL = module.url(forResource: "ClientMessageBase", withExtension: "js"),
            let communicationHubURL = module.url(forResource: "CommunicationHub", withExtension: "js"),
            let evaluatorBaseURL = module.url(forResource: "EvaluatorBase", withExtension: "js"),
            let listenerBaseURL = module.url(forResource: "ListenerBase", withExtension: "js"),
            let serverMessageBaseURL = module.url(forResource: "ServerMessageBase", withExtension: "js"),
            let baseTypesURL = module.url(forResource: "baseTypes", withExtension: "js")
        else {
            throw JavaScriptLoaderError.resourceFileNotFound
        }
        do {
            // Load all necessary javascript content
            _localContextClientMessageActions = try String(contentsOf: clientMessageActionsURL)
            _localContextClientMessageBaseActions = try String(contentsOf: clientMessageBaseActionsURL)
            _localContextCommunicationHubInterfaceActions = try String(contentsOf: communicationHubInterfaceActionsURL)
            _localContextEvaluatorBaseActions = try String(contentsOf: evaluatorBaseActionsURL)
            _localContextListenerBaseActions = try String(contentsOf: listenerBaseActionsURL)
            _localContextServerMessageBaseActions = try String(contentsOf: serverMessageBaseAcitonsURL)
            _localContextClientMessageBase = try String(contentsOf: clientMessageBaseURL)
            _localContextCommunicationHubInterface = try String(contentsOf: communicationHubURL)
            _localContextEvaluatorBase = try String(contentsOf: evaluatorBaseURL)
            _localContextListenerBase = try String(contentsOf: listenerBaseURL)
            _localContextServerMessageBase = try String(contentsOf: serverMessageBaseURL)
            _baseTypes = try String(contentsOf: baseTypesURL)
        } catch {
            throw JavaScriptLoaderError.resourceFileNotFound
        }
    }

    /// Replace base class with child class that extends `ServerMessageBase` class
    /// with contents of given file. File name should be relative path to the base path
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the file
    ///   - withContentsOfFileNamed: name of file(relative path to base path to file loader)
    ///   that contains javascript code which extends base class
    public mutating func subclassBaseServerMessage(
        usingClassNamed className: String,
        withContentsOfFileNamed file: String) throws {
            guard let content = try? fileLoader.contentsOf(file: file) else { return }
            try self.subclassBaseServerMessage(usingClassNamed: className, with: content)
        }

    /// Replace base class with child class that extends `ServerMessageBase` class
    /// with contents of file at specified file `URL`
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the file
    ///   - withContentsOfFileAtURL: `URL` of file that contains javascript code which extends base class
    public mutating func subclassBaseServerMessage(
        usingClassNamed className: String,
        withContentsOfFileAtURL file: URL) throws {
            guard let content = try? fileLoader.contentsOf(fileAtPath: file.absoluteString) else { return }
            try self.subclassBaseServerMessage(usingClassNamed: className, with: content)
        }

    /// Replace base class with child class that extends `ServerMessageBase` class
    /// with the contents of given string
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the given string
    ///   - with: javascript content
    public mutating func subclassBaseServerMessage(
        usingClassNamed className: String, with content: String) throws {
            guard evaluateContent(content: content) == nil else { throw JavaScriptLoaderError.invalidJavaScriptLoaded }
            _localContextServerMessageBase.append(content)
            self.serverMessage = className
            guard evaluateWholeContent() == nil else { throw JavaScriptLoaderError.invalidJavaScriptLoaded }
        }

    /// Replace base class with child class that extends `ClientMessageBase` class
    /// with contents of given file. File name should be relative path to the base path
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the file
    ///   - withContentsOfFileNamed: name of file(relative path to base path to file loader)
    ///   that contains javascript code which extends base class
    public mutating func subclassBaseClientMessage(
        usingClassNamed className: String,
        withContentsOfFileNamed file: String) throws {
            guard let content = try? fileLoader.contentsOf(file: file) else { return }
            try self.subclassBaseClientMessage(usingClassNamed: className, with: content)
        }

    /// Replace base class with child class that extends `ClientMessageBase` class
    /// with contents of file at specified file `URL`
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the file
    ///   - withContentsOfFileAtURL: `URL` of file that contains javascript code which extends base class
    public mutating func subclassBaseClientMessage(
        usingClassNamed className: String,
        withContentsOfFileAtURL file: URL) throws {
            guard let content = try? fileLoader.contentsOf(fileAtPath: file.absoluteString) else { return }
            try self.subclassBaseClientMessage(usingClassNamed: className, with: content)
        }

    /// Replace base class with child class that extends `ClientMessageBase` class
    /// with the contents of given string
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the given string
    ///   - with: javascript content
    public mutating func subclassBaseClientMessage(
        usingClassNamed className: String,
        with content: String) throws {
            guard evaluateContent(content: content) == nil else { throw JavaScriptLoaderError.invalidJavaScriptLoaded }
            _localContextClientMessageBase.append(content)
            self.clientMessage = className
            guard evaluateWholeContent() == nil else { throw JavaScriptLoaderError.invalidJavaScriptLoaded }

        }

    /// Replace base class with child class that extends `ListenerBase` class
    /// with contents of given file. File name should be relative path to the base path
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the file
    ///   - withContentsOfFileNamed: name of file(relative path to base path to file loader)
    ///   that contains javascript code which extends base class
    public mutating func subclassBaseListener(
        usingClassNamed className: String,
        withContentsOfFileNamed file: String) throws {
            guard let content = try? fileLoader.contentsOf(file: file) else { return }
            try self.subclassBaseListener(usingClassNamed: className, with: content)
        }

    /// Replace base class with child class that extends `ListenerBase` class
    /// with contents of file at specified file `URL`
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the file
    ///   - withContentsOfFileAtURL: `URL` of file that contains javascript
    ///   code which extends base class
    public mutating func subclassBaseListener(
        usingClassNamed className: String,
        withContentsOfFileAtURL file: URL) throws {
            guard let content = try? fileLoader.contentsOf(fileAtPath: file.absoluteString) else { return }
            try self.subclassBaseListener(usingClassNamed: className, with: content)
        }

    /// Replace base class with child class that extends `ListenerBase` class
    /// with the contents of given string
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the given string
    ///   - with: javascript content
    public mutating func subclassBaseListener(
        usingClassNamed className: String,
        with content: String) throws {
            guard evaluateContent(content: content) == nil else { throw JavaScriptLoaderError.invalidJavaScriptLoaded }
            _localContextListenerBase.append(content)
            self.listener = className
            guard evaluateWholeContent() == nil else { throw JavaScriptLoaderError.invalidJavaScriptLoaded }
        }

    /// Replace base class with child class that extends `EvaluatorBase` class
    /// with contents of given file. File name should be relative
    /// path to the base path
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the file
    ///   - withContentsOfFileNamed: name of file(relative path to base path to file loader)
    ///   that contains javascript code which extends base class
    public mutating func subclassBaseEvaluator(
        usingClassNamed className: String,
        withContentsOfFileNamed file: String) throws {
            guard let content = try? fileLoader.contentsOf(file: file) else { return }
            try self.subclassBaseEvaluator(usingClassNamed: className, with: content)
        }

    /// Replace base class with child class that extends `EvaluatorBase` class
    /// with contents of file at specified file `URL`
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the file
    ///   - withContentsOfFileAtURL: `URL` of file that contains javascript
    ///   code which extends base class
    public mutating func subclassBaseEvaluator(
        usingClassNamed className: String,
        withContentsOfFileAtURL file: URL) throws {
            guard let content = try? fileLoader.contentsOf(fileAtPath: file.absoluteString) else { return }
            try self.subclassBaseEvaluator(usingClassNamed: className, with: content)
        }

    /// Replace base class with child class that extends `EvaluatorBase` class
    /// with the contents of given string
    /// - Parameters:
    ///   - usingClassNamed: name of the new child class in the given string
    ///   - with: javascript content
    public mutating func subclassBaseEvaluator(
        usingClassNamed className: String,
        with content: String) throws {
            guard evaluateContent(content: content) == nil else { throw JavaScriptLoaderError.invalidJavaScriptLoaded }
            _localContextEvaluatorBase.append(content)
            self.evaluator = className
            guard evaluateWholeContent() == nil else { throw JavaScriptLoaderError.invalidJavaScriptLoaded }
        }

    // MARK: Action registering methods
    // These methods are non throwing
    // If there is an invalid javaScript code passed
    // Execution will end with with fatal error

    /// Register client message action which is contained
    /// in file at relative path to file loader initial path
    /// - Warning: Only method must be in the file
    /// Example usage:
    /// (context, action, object) => {
    ///     // where - `context` is `ClientMessageActionBase` context
    ///     //       - `action` is `ClientMessageAction`
    ///     //       - `object`
    /// };
    /// - Parameters:
    ///    - liveSelector: custom selector attached to element
    ///    - withContentsOfFileWithRelativePath: relative file path
    ///    to initial loader file path
    public mutating func registerClientMessageAction(
        liveSelector: String,
        withContentsOfFileWithRelativePath file: String) {
            guard let action = try? fileLoader.contentsOf(file: file) else { return }
            self.registerClientMessageAction(liveSelector: liveSelector, withContents: action)
        }

    /// Register client message action which is contained
    /// in file at given `URL`
    /// - Warning: Only method must be in the file
    /// Example usage:
    /// (context, action, object) => {
    ///     // where - `context` is `ClientMessageActionBase` context
    ///     //       - `action` is `ClientMessageAction`
    ///     //       - `object`
    /// };
    /// - Parameters:
    ///    - liveSelector: custom selector attached to element
    ///    - withContentsOfFileWithRelativePath: relative file path
    ///    to initial loader file path
    public mutating func registerClientMessageAction(
        liveSelector: String,
        withContentsOfFileAtURL file: URL) {
            guard let action = try? fileLoader.contentsOf(fileAtPath: file.absoluteString) else { return }
            self.registerClientMessageAction(liveSelector: liveSelector, withContents: action)
        }

    /// Register client message action with string
    /// - Warning: Only method must be in the file
    /// Example usage:
    /// (context, action, object) => {
    ///     // where - `context` is `ClientMessageActionBase` context
    ///     //       - `action` is `ClientMessageAction`
    ///     //       - `object`
    /// };
    /// - Parameters:
    ///    - liveSelector: custom selector attached to element
    ///    - withContents: string with javascript method
    public mutating func registerClientMessageAction(
        liveSelector: String,
        withContents action: String) {
            _registering += """
        clientMessage.register(
        new ClientMessageAction('[\(liveSelector)]','\(liveSelector)', '\(liveSelector)',\(action))
        );\n
        """
        }

    /// Register server message action which is contained
    /// in file at relative path to file loader initial path
    /// - Warning: Only method must be in the file
    /// - Warning: Before regisering server message actions make sure to extend
    /// the context for the required enums
    /// Example usage:
    /// (context, action, object) => {
    ///     // where - `context` is `ClientMessageActionBase` context
    ///     //       - `action` is `ClientMessageAction`
    ///     //       - `object`
    /// };
    /// - Parameters:
    ///    - forKey: custom selector attached to element
    ///    - withContentsOfFileWithRelativePath: relative file path to initial loader file path
    public mutating func registerServerMessageAction(
        forKey: String,
        withContentsOfFileWithRelativePath file: String) {
            guard let content = try? fileLoader.contentsOf(file: file) else { return }
            self.registerServerMessageAction(forKey: forKey, withContents: content)

        }

    /// Register server message action which is contained
    /// in file at given `URL`
    /// - Warning: Only method must be in the file
    /// - Warning: Before regisering server message actions make sure to extend
    /// the context for the required enums
    /// Example usage:
    /// (context, action, object) => {
    ///     // where - `context` is `ClientMessageActionBase` context
    ///     //       - `action` is `ClientMessageAction`
    ///     //       - `object`
    /// };
    /// - Parameters:
    ///    - forKey: custom selector attached to element
    ///    - withContentsOfFileWithRelativePath: relative file path to initial loader file path
    public mutating func registerServerMessageAction(forKey: String, withContentsOfFileAtURL file: URL) {
        guard let content = try? fileLoader.contentsOf(file: file.absoluteString) else { return }
        self.registerServerMessageAction(forKey: forKey, withContents: content)
    }

    /// Register server message action with string
    /// - Warning:  Only method must be in the file
    /// - Warning: Before registering server message actions make sure to extend
    /// the context for the required enums
    /// Example usage:
    /// (context, action, object) => {
    ///     // where - `context` is `ClientMessageActionBase` context
    ///     //       - `action` is `ClientMessageAction`
    ///     //       - `object`
    /// };
    /// - Parameters:
    ///    - forKey: custom selector attached to element
    ///    - withContents: string with javascript method
    public mutating func registerServerMessageAction(forKey: String, withContents action: String) {
        _registering += "serverMessage.register('\(forKey)', \(action));\n"
    }
}

// MARK: Method implementations
extension JavaScriptLoader {
    /// Implements encode message method of `ClientMessageBase`
    /// Method expects implementation of encode with signature
    /// `encode(elementID, action, value, authToken)`
    /// return value of encode should be stringified JSON
    /// `return JSON.stringify(...)`
    public mutating func encodeMessageForServer(encodeMethodImplementation: String) {
        guard encodeMethodImplementation.contains(
            "encode(elementID, action, value, authToken)"
        ) else {
            fatalError("Encode method does not have proper signature")
        }
        let extensionName = "ClientMessageBase\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let extensionImplementation = """
            \(extensionName) extends EvaluatorBase {
            \(encodeMethodImplementation)
        }
        """
        _clientMessageBase = extensionImplementation
        clientMessage = extensionName
    }

    /// Implements parse message method of `EvaluatorBase`
    /// Method expects implementation of parse with signature
    /// `parse(action)` and receives `CommunicationHubTargetAction` as input parameter
    /// it should forward the parsed message to `evaluate` method
    public mutating func parseMessageFromServer(parseMethodImplementation: String) {
        guard parseMethodImplementation.contains(
            "parse(action)"
        ) else {
            fatalError("Parse method does not have proper signature")
        }
        if _isEvaluatorProperlyImplemented.1 {
            _evaluatorBase += """
                \(parseMethodImplementation)
            }
            """
        } else {
            let extensionName = "EvaluatorBase\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
            let extensionImplementation = """
                \(extensionName) extends EvaluatorBase {
                \(parseMethodImplementation)
            }
            """
            _evaluatorBase = extensionImplementation
            evaluator = extensionName
        }

        _isEvaluatorProperlyImplemented = (true, _isEvaluatorProperlyImplemented.1)
    }

    /// Implements parse message method of `EvaluatorBase`
    /// Method expects implementation of parse with signature
    /// `evaluate(message)` and receives object parsed by `parse` method
    /// it should forward the parsed message to `evaluate` method
    /// as result this method should emit message for `ServerMessageBase`
    /// forwarding evaluated server message to dedicated handlers
    public mutating func evaluateMessageFromServer(evaluateMethodImplementation: String) {
        if _isEvaluatorProperlyImplemented.0 {
            _evaluatorBase += """
                \(evaluateMethodImplementation)
            }
            """
        } else {
            let extensionName = "EvaluatorBase\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
            let extensionImplementation = """
                \(extensionName) extends EvaluatorBase {
                \(evaluateMethodImplementation)
            }
            """
            _evaluatorBase = extensionImplementation
            evaluator = extensionName
        }
        _isEvaluatorProperlyImplemented = (_isEvaluatorProperlyImplemented.0, true)
    }

    /// Implements `parseValueToActionAndMetadata` method of `ServerMessageBase`
    /// Method expects implementation of `parseValueToActionAndMetadata` with signature
    /// `parseValueToActionAndMetadata(action)` where `action` is object forwarded by
    /// `evaluate` method previously implemented
    /// method should return `{action: , object: }` object which will be used in further
    /// handler actions
    public mutating func parseValuesFromServerMessage(parseValueToActionAndMetadataMethodImplementation: String) {
        guard parseValueToActionAndMetadataMethodImplementation.contains(
            "parseValueToActionAndMetadata(action)"
        ) else {
            fatalError("Parse method does not have proper signature")
        }
        let extensionName = "ServerMessageBase\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let extensionImplementation = """
            \(extensionName) extends ServerMessageBase {
            \(parseValueToActionAndMetadataMethodImplementation)
        }
        """
        _serverMessageBase = extensionImplementation
        serverMessage = extensionName
    }
}

// MARK: Enumeration extensions
extension JavaScriptLoader {
    /// Extends one of existing enumeration in JS context
    /// - Parameters:
    ///   - targetEnum: target enum for extension
    ///   - content: option for extension, i.e `static A = "myExtendedValue";`
    /// - Warning: Pay attention to proper JS syntax
    public mutating func extendEnumeration(which targetEnum: JavaScriptEnumOptions, with content: String) {
        var currentContext: String?
        switch targetEnum {
        case .clientMessageActions:
            currentContext = _localContextClientMessageActions
        case .serverMessageBaseActions:
            currentContext = _localContextServerMessageBaseActions
        case .clientMessageBaseActions:
            currentContext = _localContextClientMessageBaseActions
        case .communicationHubInterfaceActions:
            currentContext = _localContextCommunicationHubInterfaceActions
        case .listenerBaseActions:
            currentContext = _localContextListenerBaseActions
        }
        if let currentContext {
            evaluateEnumExtension(with: content, enumContent: currentContext)
            extendEnumeration(targetEnum: targetEnum, with: content)
        }
    }

    private mutating func extendEnumeration(targetEnum: JavaScriptEnumOptions, with content: String) {
        switch targetEnum {
        case .clientMessageActions:
            _localContextClientMessageActions += content
        case .serverMessageBaseActions:
            _localContextServerMessageBaseActions += content
        case .clientMessageBaseActions:
            _localContextClientMessageBaseActions += content
        case .communicationHubInterfaceActions:
            _localContextCommunicationHubInterfaceActions += content
        case .listenerBaseActions:
            _localContextListenerBaseActions += content
        }
    }

    private func evaluateEnumExtension(with option: String, enumContent: String) {
#if canImport(JavaScriptCore)
        guard let ctx = JSContext() else {
            fatalError("Failed to create javascript context")
        }
        ctx.exceptionHandler = { _, exception in
            if let exc = exception {
                fatalError("JavaScript Error: \(exc)")
            }
        }
        ctx.evaluateScript(_baseTypes)
        let script = enumContent + option + "}"
        ctx.evaluateScript(script)
#endif
    }

    private func evaluateContent(content: String) -> JSValue? {
#if canImport(JavaScriptCore)
        guard let ctx = JSContext() else {
            fatalError("Failed to create javascript context")
        }
        ctx.evaluateScript("""
                \(_baseTypes)
                \(_localContextClientMessageBase)
                \(_localContextCommunicationHubInterface)
                \(_localContextServerMessageBase)
                \(_localContextListenerBase)
                \(_localContextEvaluatorBase)
        """)
        let value = ctx.evaluateScript(content)
        return value?.context.exception
#endif
    }

    private func evaluateWholeContent() -> JSValue? {
#if canImport(JavaScriptCore)
        guard let wholeContext = JSContext() else {
            fatalError("Failed to create javascript context")
        }
        let wholeContent = wholeContext.evaluateScript(self.content)
        if let exception = wholeContent?.context.exception {
            // Supress this this type of exception since ``JSContext`` does not
            // have window object
            if exception.toString().contains("Can't find variable: window") {
                return nil
            }
            return exception
        }
        return nil
#endif
    }
}

// MARK: Enum overrides
extension JavaScriptLoader {
    /// Overrides cases in the `ClientMessageActions` enum
    /// - Parameters:
    ///   - with: dictionary of valeus to override
    public mutating func overrideClientMessageActions(with: [ClientMessageActions.AllCases.Element: String]) {
        guard Set(with.keys).isSuperset(of: ClientMessageActions.allCases) else {
            fatalError("You do not properly override all required ClientMessageActions cases")
        }
        var content = "class ClientMessageActions extends EnumBase {\n"
        for value in with {
            content += "STATIC \(value.key.rawValue) = \"\(value.value)\";\n"
        }
        content += "}"
        overridenClientMessageActions = content
    }

    /// Overrides cases in the `ServerMessageBaseActions` enum
    /// - Parameters:
    ///   - with: dictionary of valeus to override
    public mutating func overrideServerMessageBaseActions(with: [ServerMessageBaseActions.AllCases.Element: String]) {
        guard Set(with.keys).isSuperset(of: ServerMessageBaseActions.allCases) else {
            fatalError("You do not properly override all required ServerMessageBaseActions cases")
        }
        var content = "class ServerMessageBaseActions extends EnumBase {\n"
        for value in with {
            content += "STATIC \(value.key.rawValue) = \"\(value.value)\";\n"
        }
        content += "}"
        overridenServerMessageBaseActions = content
    }
}

// MARK: options for extending javaScript code
public enum ClientMessageActions: String, CaseIterable {
    case liveHref = "LIVE_HREF"
    case liveAction = "LIVE_ACTION"
    case liveLoad = "LIVE_LOAD"
    case liveInput = "LIVE_INPUT"
}

public enum ServerMessageBaseActions: String, CaseIterable {
    case insertNode = "INSERT_NODE"
    case replaceBody = "REPLACE_BODY"
    case appendNode = "APPEND_NODE"
    case removeAttribute = "REMOVE_ATTRIBUTE"
    case addAttribute = "ADD_ATTRIBUTE"
    case updateAttribute = "UPDATE_ATTRIBUTE"
    case updateNodeValue = "UPDATE_NODE_VALUE"
    case setInput = "SET_INPUT"
    case addStyleTo = "ADD_STYLE_TO"
    case remove = "REMOVE"
    case removeStyle = "REMOVE_STYLE"
}
