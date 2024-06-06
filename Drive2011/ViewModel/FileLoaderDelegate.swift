//
//  FileLoaderDelegate.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 22/05/24.
//

import Foundation

protocol FileLoaderDelegate: AnyObject {
    func addToDictionary(data: Data)
    func getFileData() -> Data?
}
