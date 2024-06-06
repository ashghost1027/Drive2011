//
//  User.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 07/05/24.
//

import Foundation
import GoogleSignIn

struct User {
    let name: String
    let email: String
    let imageURL: URL?
    let accessToken: GIDToken
}


