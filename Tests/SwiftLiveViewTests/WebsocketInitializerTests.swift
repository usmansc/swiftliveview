//
//  WebsocketInitializerTests.swift
//  
//
//  Created by Lukáš Schmelcer on 02/11/2023.
//

import XCTest
@testable import SwiftLiveView

final class WebsocketInitializerTests: XCTestCase {
    let initializer = WebsocketInitializer()
    let toInsert = """
    <script>This is inserted javascript</script>
    """
    
    func testHead() throws {
        let inData = """
        <html><head></head></html>
        """
        let expectedOutput = """
        <html><head><script>This is inserted javascript</script></head></html>
        """
        let output = initializer.inject(javascript: toInsert, to: inData)
        XCTAssertEqual(expectedOutput, output)
    }

    func testNoHeadBody() throws {
        let inData = """
        <html><body>No head</body></html>
        """
        let expectedOutput = """
        <html><body>No head<script>This is inserted javascript</script></body></html>
        """
        let output = initializer.inject(javascript: toInsert, to: inData)
        XCTAssertEqual(expectedOutput, output)
    }

    func testNoBodyHead() throws {
        let inData = """
        <html>No head</html>
        """
        let expectedOutput = """
        <script>This is inserted javascript</script><html>No head</html>
        """
        let output = initializer.inject(javascript: toInsert, to: inData)
        XCTAssertEqual(expectedOutput, output)
    }

    func testEmptyFile() throws {
        let inData = """
        """
        let expectedOutput = """
        <script>This is inserted javascript</script>
        """
        let output = initializer.inject(javascript: toInsert, to: inData)
        XCTAssertEqual(expectedOutput, output)
    }

    func testNotHTML() throws {
        let inData = """
        Just text
        """
        let expectedOutput = """
        <script>This is inserted javascript</script>\(inData)
        """
        let output = initializer.inject(javascript: toInsert, to: inData)
        XCTAssertEqual(expectedOutput, output)
    }
}
