//
//  IdentificationPayload.swift
//  Helper
//
//  Created by Lukáš Schmelcer on 07/11/2023.
//

import Vapor
import JWT

/// Error options associated with ``TokenGenerator`` and ``TokenAuthenticator``
enum JWTErrors: Error {
    case noSigner
    case noPrivateSigner
}

/// `JWT` token generator
public struct TokenGenerator {
    /// Generates `JWT` token based on
    /// - Parameter app: Application reference
    /// - Returns: string representation of `JWT` token
    public static func generateToken(_ app: Application) throws -> String {
        var expDate = Date()
        expDate.addTimeInterval(JWTConstants.tokenExpiryInSeconds)
        let claim = expDate

        guard let signer = app.jwt.signers.get(kid: .private) else {
            throw JWTErrors.noPrivateSigner
        }
        return try signer.sign(IdentificationPayload(expiration: ExpirationClaim(value: claim), associatedId: .init()))
    }
}

internal struct IdentificationPayload: JWTPayload {
    var expiration: ExpirationClaim
    var associatedId: UUID

    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}

internal struct TokenAuthenticator {
    static func authenticate(token: String, for request: Request) throws {
        guard let signer = request.application.jwt.signers.get() else {
            throw JWTErrors.noSigner
        }
        _ = try signer.verify(token, as: IdentificationPayload.self)
    }
}

extension StringProtocol {
    var bytes: [UInt8] { .init(utf8) }
}

extension JWKIdentifier {
    static let `public` = JWKIdentifier(string: "public")
    static let `private` = JWKIdentifier(string: "private")
}
