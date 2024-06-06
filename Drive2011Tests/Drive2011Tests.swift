//
//  Drive2011Tests.swift
//  Drive2011Tests
//
//  Created by aswin-zstch1323 on 07/05/24.
//

import XCTest
@testable import Drive2011

final class Drive2011Tests: XCTestCase {

    var sut: DriveManager?
    var fileID: String?
    
    override func setUpWithError() throws {
        sut = DriveManager.shared
    }
    
    override func tearDownWithError() throws {
        sut = nil
        fileID = nil
    }
    
    func testUpload() throws {
       
        let expectation = XCTestExpectation(description: "Upload file expectation")
        
        guard let url = URL(string: "file:///Users/aswin-zstch1323/Downloads/Death_and_its_aftermath.docx") else { return }
        
        sut?.uploadFile("Drive2011", filePath: url, MIMEType: "application/msword", progressHandler: nil) { fileID, error in
            XCTAssertNil(error)
            XCTAssertNotNil(fileID)
            self.fileID = fileID
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testDownload() throws {
        let uploadExpectation = XCTestExpectation(description: "Upload file expectation")
        let downloadExpectation = XCTestExpectation(description: "Download file expectation")
        
        
        guard let url = URL(string: "file:///Users/aswin-zstch1323/Downloads/Death_and_its_aftermath.docx") else { return }
        
        sut?.uploadFile("Drive2011", filePath: url, MIMEType: "application/msword", progressHandler: nil) { fileID, error in
            XCTAssertNil(error)
            XCTAssertNotNil(fileID)
            self.fileID = fileID
            uploadExpectation.fulfill()
        }
        
        wait(for: [uploadExpectation], timeout: 10)
        
        guard let fileID = fileID else { return }
        sut?.download(fileID, progressHandler: nil) { data, error in
            XCTAssertNil(error, "An error occurred during download")
            XCTAssertNotNil(data, "Data was not retrieved from download.")
            downloadExpectation.fulfill()
        }
        
        wait(for: [downloadExpectation], timeout: 10)
    }
    
    func testIfFileConvertibleToViewModel() {
        
        let expectation = XCTestExpectation(description: "File conversion expectation")
        
        sut?.listFilesInFolder("Drive2011") { fileList, error in
            XCTAssertNil(error, "Could not list the files due to error")
            XCTAssertNotNil(fileList, "FileList was nil")
            
            guard let fileList = fileList, let files = fileList.files else { return }
            
            let existingFilesOnDrive = files.map {
                let loadFileModel = LoadFileViewModel(filePath: nil, date: $0.viewedByMeTime?.date.description ?? Date().description, mimeType: $0.mimeType!, fileId: $0.identifier!, nameOfFile: $0.name!, fileSize: UInt64(truncating: $0.size!))
                return loadFileModel
            }
            
            XCTAssert(existingFilesOnDrive.count > 0, "Nothing is there in uploads.")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testSearch() {
        let expectation = XCTestExpectation(description: "Search file expectation")
        
        sut?.search(for: "Death_and_its_aftermath.docx") { fileID, error in
            XCTAssertNil(error, "An error occurred when searching for the file.")
            XCTAssertNotNil(fileID, "File was not found.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }
    
    func testFileData() {
        let expectation = XCTestExpectation(description: "Get FileData expectation")
        let uploadExpectation = XCTestExpectation(description: "Upload file expectation")
        
        guard let url = URL(string: "file:///Users/aswin-zstch1323/Downloads/Death_and_its_aftermath.docx") else { return }
        
        sut?.uploadFile("Drive2011", filePath: url, MIMEType: "application/msword", progressHandler: nil) { fileID, error in
            XCTAssertNil(error)
            XCTAssertNotNil(fileID)
            self.fileID = fileID
            uploadExpectation.fulfill()
        }
        
        wait(for: [uploadExpectation], timeout: 10)
        guard let fileID = fileID else { return }
        sut?.getFileData(of: fileID, completion: { fileData, error in
            XCTAssertNil(error)
            XCTAssertNotNil(fileData)
            XCTAssertEqual(fileData?.contentType, "application/msword")
        })
    }
}
