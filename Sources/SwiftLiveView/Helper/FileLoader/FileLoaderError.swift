//
//  FileLoaderError.swift
//  Helper
//
//  Created by Lukáš Schmelcer on 31/10/2023.
//

import Foundation

/// Error representation for ``FileLoader``
enum FileLoaderError: Error {
    case pathNotDirectory
    case invalidPath
    case invalidFileName
    case doesNotExists
    case notReadable
    case fileIsNotJS
    case invalidUti
    case failedToReadCotnents
    case failedParseFileContent
    case noFilePath
}
