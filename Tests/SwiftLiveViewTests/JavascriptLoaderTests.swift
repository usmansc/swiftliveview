//
//  JavascriptLoaderTests.swift
//  
//
//  Created by Lukáš Schmelcer on 01/11/2023.
//

import XCTest
@testable import SwiftLiveView

final class JavascriptLoaderTests: XCTestCase {

    func testInitLoaderWithFolderPath() throws {
        XCTAssertNoThrow(try JavaScriptLoader())
    }

    func testInitLoaderWithoutFolderPath() throws {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            XCTAssertNoThrow(try JavaScriptLoader(sourceFileFolderPath: directoryPath))
        } else { XCTFail("Could not init the directory path") }
    }

    // MARK: Input validation test
    // These tests do also test if passed javaScript is valid
    // Same validation is performed in every subclassing method
    func testSubclassBaseServerMessageWithContentsOfFileNamed() {
        let extensionContent = """
        class TestBaseServerMessage extends ServerMessageBase {
            updateNodeValue(message) {
                const element = document.getElementById(message.targetElement);
                element.innerText = message.value;
            }
        }
        """
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                try loader.subclassBaseServerMessage(
                    usingClassNamed: "TestBaseServerMessage",
                    withContentsOfFileNamed: "testBaseServerMessageCorrect.js"
                )
                XCTAssertTrue(loader.content.contains(extensionContent))
                XCTAssertTrue(loader.content.contains("const serverMessage = new TestBaseServerMessage();"))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testSubclassBaseServerMessageMissingBracket() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                XCTAssertThrowsError(try loader.subclassBaseServerMessage(
                    usingClassNamed: "TestBaseServerMessage",
                    withContentsOfFileNamed: "testBaseServerMessageMissingBracket.js"
                ))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testSubclassBaseServerMessageWithContentsOfFileWrongClassName() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                XCTAssertThrowsError(try loader.subclassBaseServerMessage(
                    usingClassNamed: "TestBaseServerMessageWrongName",
                    withContentsOfFileNamed: "testBaseServerMessageCorrect.js"
                ))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    // MARK: Client message sublassing
    func testSubclassBaseClientMessageWithContentsOfFileNamed() {
        let extensionContent = """
        class TestBaseClientMessage extends ClientMessageBase { }
        """
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                try loader.subclassBaseClientMessage(
                    usingClassNamed: "TestBaseClientMessage",
                    withContentsOfFileNamed: "testBaseClientMessageCorrect.js"
                )
                XCTAssertTrue(loader.content.contains(extensionContent))
                XCTAssertTrue(loader.content.contains("const clientMessage = new TestBaseClientMessage(false);"))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testSubclassBaseClientMessageMissingBracket() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                XCTAssertThrowsError(try loader.subclassBaseClientMessage(
                    usingClassNamed: "TestBaseClientMessage",
                    withContentsOfFileNamed: "testBaseClientMessageMissingBracket.js"
                ))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testSubclassBaseClientMessageWithContentsOfFileWrongClassName() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                XCTAssertThrowsError(try loader.subclassBaseClientMessage(
                    usingClassNamed: "TestBaseClientMessageWrongName",
                    withContentsOfFileNamed: "testBaseClientMessageCorrect.js"
                ))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    // MARK: Listener sublassing
    func testSubclassListenerBaseWithContentsOfFileNamed() {
        let extensionContent = """
        class TestListenerBase extends ListenerBase {}
        """
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                try loader.subclassBaseListener(
                    usingClassNamed: "TestListenerBase",
                    withContentsOfFileNamed: "testListenerBaseCorrect.js"
                )
                XCTAssertTrue(loader.content.contains(extensionContent))
                XCTAssertTrue(loader.content.contains(
                    "const listener = new TestListenerBase"
                ))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testSubclassListenerBaseMissingBracket() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                XCTAssertThrowsError(try loader.subclassBaseListener(
                    usingClassNamed: "TestListenerBase",
                    withContentsOfFileNamed: "testListenerBaseMissingBracket.js"
                ))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testSubclassListenerBaseWithContentsOfFileWrongClassName() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                XCTAssertThrowsError(try loader.subclassBaseListener(
                    usingClassNamed: "ListenerBaseWrongName",
                    withContentsOfFileNamed: "testListenerBaseCorrect.js"
                ))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    // MARK: Evaluator sublassing
    func testSubclassEvaluatorBaseWithContentsOfFileNamed() {
        let extensionContent = """
        class TestEvaluatorBase extends EvaluatorBase {}
        """
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                try loader.subclassBaseEvaluator(
                    usingClassNamed: "TestEvaluatorBase",
                    withContentsOfFileNamed: "testEvaluatorBaseCorrect.js"
                )
                XCTAssertTrue(loader.content.contains(extensionContent))
                XCTAssertTrue(loader.content.contains(
                    "const evaluator = new TestEvaluatorBase"
                ))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testSubclassEvaluatorBaseMissingBracket() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                XCTAssertThrowsError(try loader.subclassBaseEvaluator(
                    usingClassNamed: "TestEvaluatorBase",
                    withContentsOfFileNamed: "testEvaluatorBaseMissingBracket.js"
                ))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testSubclassEvaluatorBaseWithContentsOfFileWrongClassName() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                XCTAssertThrowsError(try loader.subclassBaseEvaluator(
                    usingClassNamed: "TestEvaluatorBaseWrongName",
                    withContentsOfFileNamed: "testEvaluatorBaseCorrect.js"
                ))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testExtendEnumeration() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/JavaScriptLoader", ofType: nil) {
            do {
                var loader = try JavaScriptLoader(sourceFileFolderPath: directoryPath)
                loader.extendEnumeration(which: .serverMessageBaseActions, with: "static A = 'newStaticOptionA';")
                XCTAssertTrue(loader.content.contains("static A = 'newStaticOptionA';"))
            } catch {
                XCTFail("Could not init JavaScriptLoader with given path")
            }
        } else { XCTFail("Could not init the directory path") }
    }
}
