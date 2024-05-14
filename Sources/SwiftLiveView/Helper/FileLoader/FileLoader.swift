//
//  FileLoader.swift
//  Helper
//
//  Created by Lukáš Schmelcer on 31/10/2023.
//

import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Handles loading of javaScript files for ``JavascriptLoader``
internal struct FileLoader {
    private let manager: FileManager = .default
    private let primaryFilePath: String?

    /// Creates loader with primary path
    /// - Parameter primaryFilePath: primary file path
    public init(primaryFilePath: String) {
        self.primaryFilePath = primaryFilePath
    }

    /// Creates loader without primary path
    public init() {
        self.init(primaryFilePath: "")
    }

    /// Tries to read contents of specified file starting from primary file path
    /// - Parameter fileName: file name
    /// - Returns: string file content
    public func contentsOf(file fileName: String) throws -> String {
        guard let primaryFilePath else { throw FileLoaderError.noFilePath }
        return try _contentsOf(file: fileName, at: primaryFilePath)
    }

    /// Tries to read contents of file at specified path
    /// - Parameters:
    ///   - fileName: file name
    ///   - path: initial path
    /// - Returns: string file content
    public func contentsOf(file fileName: String, at path: String) throws -> String {
        try _contentsOf(file: fileName, at: path)
    }

    /// Tries to read contents of file at path
    /// - Parameter path: file path
    /// - Returns: string file content
    public func contentsOf(fileAtPath path: String) throws -> String {
        guard manager.fileExists(atPath: path) else { throw FileLoaderError.doesNotExists }
        guard manager.isReadableFile(atPath: path) else { throw FileLoaderError.notReadable }

        // Check if the file is javascript file
#if canImport(UniformTypeIdentifiers)
        guard let ext = NSURL(fileURLWithPath: path).pathExtension else { throw FileLoaderError.invalidPath }
        guard let utiType = UTType(filenameExtension: ext) else { throw FileLoaderError.invalidUti }
        guard utiType.conforms(to: .javaScript) else { throw FileLoaderError.fileIsNotJS }
#endif
        // Load the contents
        guard let fileData = manager.contents(atPath: path) else { throw FileLoaderError.failedToReadCotnents }
        guard let fileContent = String(data: fileData, encoding: .utf8) else {
            throw FileLoaderError.failedParseFileContent
        }
        return fileContent
    }

    /// Tries to read contents of file name at path
    /// - Parameters:
    ///   - fileName: file name
    ///   - path: path
    /// - Returns: string file content
    private func _contentsOf(file fileName: String, at path: String) throws -> String {
        guard isDirectory(path: path) else { throw FileLoaderError.pathNotDirectory }
        let path = constructPath(path: path, fileName: fileName)
        return try contentsOf(fileAtPath: path)
    }

    /// Checks if path is directory
    /// - Parameter path: path to verify
    /// - Returns: true if path is directory
    private func isDirectory(path: String) -> Bool {
        var isDir: ObjCBool = false
        return manager.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    /// Constructs full file path from path and file name
    /// - Parameters:
    ///   - path: path
    ///   - fileName: filename
    /// - Returns: file path
    private func constructPath(path: String, fileName: String) -> String {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        let fileURL = url.appendingPathComponent(fileName)
        return fileURL.path
    }
}
