//
//  IncidentAuthorizationService.swift
//  hydrant
//
//  Created by Yeba Teo on 26/08/26.
//

import Foundation

struct IncidentAuthorizationService {
    // Prototype only.
    // Replace with server-backed authorization, code rotation, audit logging,
    // rate limiting, and secure transport before production.
    private let validCode = "1234"

    func validate(code: String) -> Bool {
        code == validCode
    }
}
