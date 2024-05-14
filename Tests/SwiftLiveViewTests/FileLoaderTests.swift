import XCTest
@testable import SwiftLiveView

final class FileLoaderTests: XCTestCase {
    func testInvalidContent() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/FileLoader", ofType: nil) {
            let loader = FileLoader(primaryFilePath: directoryPath)
            XCTAssertThrowsError(try loader.contentsOf(file: "picture.js")) { error in
                XCTAssertEqual(error as? FileLoaderError, .failedParseFileContent)
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testEmptyFolder() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/FileLoader/EmptyFolder", ofType: nil) {
            let loader = FileLoader(primaryFilePath: directoryPath)
            XCTAssertThrowsError(try loader.contentsOf(file: "valid.js")) { error in
                XCTAssertEqual(error as? FileLoaderError, .doesNotExists)
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testNotDirectory() {
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/FileLoader/valid.js", ofType: nil) {
            let loader = FileLoader(primaryFilePath: directoryPath)
            XCTAssertThrowsError(try loader.contentsOf(file: "valid.js")) { error in
                XCTAssertEqual(error as? FileLoaderError, .pathNotDirectory)
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testFileWithoutExtension() {
        let fileName = "noExtensionFile"
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/FileLoader", ofType: nil) {
            let loader = FileLoader(primaryFilePath: directoryPath)
            XCTAssertThrowsError(try loader.contentsOf(file: fileName)) { error in
                XCTAssertEqual(error as? FileLoaderError, .invalidUti)
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testFileWrongExtension() {
        let fileName = "invalid.txt"
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/FileLoader", ofType: nil) {
            let loader = FileLoader(primaryFilePath: directoryPath)
            XCTAssertThrowsError(try loader.contentsOf(file: fileName)) { error in
                XCTAssertEqual(error as? FileLoaderError, .fileIsNotJS)
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testSpaceFilename() {
        let fileName = " .js"
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/FileLoader", ofType: nil) {
            let loader = FileLoader(primaryFilePath: directoryPath)
            do {
                let content = try loader.contentsOf(file: fileName)
                XCTAssertEqual("<script>let test;</script>", content.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                XCTFail("Could not read valid file content")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testEmptyFileContent() {
        let fileName = "valid-empty.js"
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/FileLoader", ofType: nil) {
            let loader = FileLoader(primaryFilePath: directoryPath)
            do {
                let content = try loader.contentsOf(file: fileName)
                XCTAssertEqual("", content.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                XCTFail("Could not read valid file content")
            }
        } else { XCTFail("Could not init the directory path") }
    }

    func testFileContent() {
        let fileName = "valid.js"
        if let directoryPath = Bundle.module.path(forResource: "TestFiles/FileLoader", ofType: nil) {
            let loader = FileLoader(primaryFilePath: directoryPath)
            do {
                let content = try loader.contentsOf(file: fileName)
                XCTAssertEqual("<script>let test;</script>", content.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                XCTFail("Could not read valid file content")
            }
        } else { XCTFail("Could not init the directory path") }
    }
}
