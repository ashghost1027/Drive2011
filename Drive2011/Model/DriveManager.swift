//
//  DriveManager.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 07/05/24.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST
import BackgroundTasks


class DriveManager {
    
    private let driveService = GTLRDriveService()
    public static let shared = DriveManager()
    
    private init() {
        setupDriveServiceAuth()
    }
    
    /// Sets up the authorizer of the drive service so that it can access the scopes the user has authorized.
    private func setupDriveServiceAuth() {
        driveService.authorizer = GIDSignIn.sharedInstance.currentUser?.fetcherAuthorizer
    }
    
    /// Uploads the file to drive to the specified folder if it exists or creates a new folder with the same name.
    /// - Parameters:
    ///   - folderName: Name of the Folder it should be uploaded to.
    ///   - filePath: The path of the file.
    ///   - MIMEType: The type of file.
    /// - Returns: The ID of the file if successfully uploaded. Else, returns nil.
    public func uploadFile(_ folderName: String, filePath: URL, MIMEType: String, progressHandler: ((Float) -> Void)?, completion: @escaping (String?, Error?) -> Void) {
        
        search(for: folderName) { [weak self] folderID, error in
            guard let self = self else { return }
            if let folderID = folderID {
                self.upload(folderID: folderID, path: filePath, MIMEType: MIMEType, progressHandler: progressHandler, completion: completion)
            } else {
                self.createFolder(folderName) { folderID, error in
                    if let folderID = folderID {
                        self.upload(folderID: folderID, path: filePath, MIMEType: MIMEType, progressHandler: progressHandler, completion: completion)
                    } else {
                        completion(nil, GoogleDriveError.folderCreationFailed)
                    }
                }
            }
        }

    }
    
    public func saveUploadState() {
        
    }
    
    /// Uploads the file to a specified folder with its ID to Google Drive.
    /// - Parameters:
    ///   - parentID: ID of the folder in Google Drive.
    ///   - path: Path of the file.
    ///   - MIMEType: Type of the file.
    /// - Returns: ID of the file if successful upload. Else, returns nil.
    private func upload(folderID: String, path: URL, MIMEType: String, progressHandler: ((Float) -> Void)?, completion: @escaping (String?, Error?) -> Void) {
        
        var data: Data? = nil
        
        do {
            data = try Data(contentsOf: path)
        } catch {
            data = nil
        }
        
        let file = GTLRDrive_File()
        file.name = path.description.components(separatedBy: "/").last
        file.parents = [folderID]
        
        guard let data = data else {
            completion(nil, GoogleDriveError.uploadFailed)
            return
        }
        
        let uploadParams = GTLRUploadParameters(data: data, mimeType: MIMEType)
        uploadParams.shouldUploadWithSingleRequest = false
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParams)
        query.fields = "id"
        
        
        
        driveService.executeQuery(query) { (ticket, file, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let file = file as? GTLRDrive_File else {
                completion(nil, GoogleDriveError.uploadFailed)
                return
            }
            
            
            if let fetcher = ticket.objectFetcher as? GTMSessionUploadFetcher {
                fetcher.sendProgressBlock = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
                    let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                    progressHandler?(progress)
                    print("Upload progress: \(progress)")
                    
                    
                    if fetcher.isPaused() {
                        UserDefaults.standard.setValue(path, forKey: "filePathToUpload")
                        UserDefaults.standard.setValue(MIMEType, forKey: "mimetypeOfFileToUpload")
                    }
                }
            }
            
            completion(file.identifier, nil)
        }
        
    }
    
    /// Downloads the specified file having the fileID.
    /// - Parameter fileID: the ID of the file to be downloaded.
    /// - Returns: The file in the form of Data if successful download. Else, returns nil.
    public func download(_ fileID: String, progressHandler: ((Float) -> Void)?, completion: @escaping (Data?, Error?) -> Void) {

        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        query.fields = "file(size)"
        
        driveService.executeQuery(query) { (ticket, file, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            
            guard let file = file as? GTLRDataObject else {
                completion(nil, GoogleDriveError.fileNotFound)
                return
            }
            
            if let fetcher = ticket.objectFetcher as? GTMSessionUploadFetcher {
                fetcher.sendProgressBlock = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
                    let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
                    progressHandler?(progress)
                    print(progress)
                    
                    if fetcher.isPaused() {
                        UserDefaults.standard.setValue(fileID, forKey: "fileIDToDownload")
                    }
                }
            }
            
            completion(file.data, nil)
        }
        
    }
    
    /// Creates a new folder in Google Drive.
    /// - Parameter name: Name of the folder.
    /// - Returns: The ID of the folder if it was successfully created. Else, returns nil.
    private func createFolder(_ name: String, completion: @escaping (String?, Error?) -> Void) {
        
        let folder = GTLRDrive_File()
        folder.name = name
        folder.mimeType = "application/vnd.google-apps.folder"

        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        query.fields = "id"
        
        driveService.executeQuery(query) { (ticket, folder, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let folder = folder as? GTLRDrive_File else {
                completion(nil, GoogleDriveError.folderCreationFailed)
                return
            }
            
            completion(folder.identifier, nil)
            
        }
    }
    
    /// Returns the list of files in a specified folder.
    /// - Parameter folder: The name of the folder to search.
    /// - Returns: The list of files if it exists. Else, returns nil.
    public func listFilesInFolder(_ folder: String, completion: @escaping (GTLRDrive_FileList?, Error?) -> Void) {
        
        search(for: folder) { [weak self] folderID, error in
            guard let self = self else { return }
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let folderID = folderID else {
                completion(nil, GoogleDriveError.fileNotFound)
                return
            }
            
            self.listFiles(folderID) { fileList, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                completion(fileList, nil)
            }
        }
        
    }
    
    /// List the files in a specified folder using its ID.
    /// - Parameter folderID: The ID of the folder.
    /// - Returns: The list of files if it exists. Else. returns nil.
    private func listFiles(_ folderID: String, completion: @escaping (GTLRDrive_FileList?, Error?) -> Void) {
        
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 100
        query.q = "'\(folderID)' in parents"
        query.fields = "files(id, name, mimeType, size, viewedByMeTime)"
        
        driveService.executeQuery(query) { (ticket, fileList, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let fileList = fileList as? GTLRDrive_FileList else {
                completion(nil, GoogleDriveError.fileNotFound)
                return
            }
            
            completion(fileList, nil)
        }
        
    }
    
    /// Searches for a specified file with the file name.
    /// - Parameter fileName: Name of the file.
    /// - Returns: The ID of the file if it exists. Else, returns nil.
    public func search(for fileName: String, completion: @escaping (String?, Error?) -> Void) {
        
        let query = GTLRDriveQuery_FilesList.query()
        query.executionParameters.shouldFetchNextPages = true
        query.pageSize = 1
        query.q = "name contains '\(fileName)'"
        
        
        driveService.executeQuery(query) { (ticket, filesList, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            
            guard let filesList = filesList as? GTLRDrive_FileList else {
                completion(nil, GoogleDriveError.fileNotFound)
                return
            }
            
            guard let fileID = filesList.files?.first?.identifier else {
                completion(nil, GoogleDriveError.fileNotFound)
                return
            }
            
            completion(fileID, nil)
        }
        
    }
    
    /// Returns the data to be converted to UIImage from the given URL.
    /// - Parameter url: The url of the file to be retrieved.
    /// - Returns: The data of the UIImage.
    public func downloadImage(from url: URL) async throws -> Data {
        
        let session = URLSession.shared
        let (data, _) = try await session.data(from: url)
        return data
        
    }
    
    /// Returns the data of the file at the given fileID.
    /// - Parameter fileID: The ID of the file.
    /// - Returns: Returns the data of the file if successful. Else, returns nil.
    public func getFileData(of fileID: String, completion: @escaping (FileData?, Error?) -> Void) {
        
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        
        driveService.executeQuery(query) { (ticket, file, error) in
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let file = file as? GTLRDataObject else {
                completion(nil, error)
                return
            }
            
            let fileData = FileData(data: file.data, contentType: file.contentType, fileID: fileID)
            completion(fileData, nil)
        }
        
    }
    
    func scheduleUploadTask() {
        let request = BGProcessingTaskRequest(identifier: "com.example.app.upload")
        request.requiresNetworkConnectivity = true // Ensure network connectivity
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule upload task: \(error)")
        }
    }
    
    func scheduleDownloadTask() {
        let request = BGProcessingTaskRequest(identifier: "com.example.app.download")
        request.requiresNetworkConnectivity = true // Ensure network connectivity
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule download task: \(error)")
        }
    }
    
    func resumeUpload(filePath: URL, mimeType: String, completion: @escaping (Bool) -> Void) {
        
        uploadFile("FolderName", filePath: filePath, MIMEType: mimeType, progressHandler: nil) { fileID, error in
            if let error = error {
                print("Upload failed: \(error)")
                completion(false)
            } else {
                print("Upload succeeded, file ID: \(fileID ?? "unknown")")
                completion(true)
            }
        }
    }
    
    func resumeDownload(fileID: String, completion: @escaping (Bool) -> Void) {
      
        download(fileID, progressHandler: nil) { data, error in
            if let error = error {
                print("Download failed: \(error)")
                completion(false)
            } else {
                print("Download succeeded")
                completion(true)
            }
        }
    }
    
    deinit {
        print("deinitialized")
    }
    
}

enum GoogleDriveError: Error {
    case accessTokenMissing
    case imageDataConversionFailed
    case unknown
    case uploadFailed
    case fileNotFound
    case driveServiceNotFound
    case folderCreationFailed
}
