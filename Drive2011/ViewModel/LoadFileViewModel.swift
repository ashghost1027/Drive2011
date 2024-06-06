//
//  LoadFileViewModel.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 07/05/24.
//

import Foundation
import UIKit

struct LoadFileViewModel: Codable {
    
    let filePath: URL?
    let date: String
    let mimeType: String
    var fileId: String?
    let nameOfFile: String
    let fileSize: UInt64
    
}
