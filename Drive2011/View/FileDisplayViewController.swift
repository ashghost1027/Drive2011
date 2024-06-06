//
//  FileDisplayViewController.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 10/05/24.
//

import UIKit
import GoogleAPIClientForREST
import WebKit
import MobileCoreServices
import AVKit

class FileDisplayViewController: UIViewController {
    
    // MARK: - Properties
    private var driveManager = DriveManager.shared
    private var activityIndicator = UIActivityIndicatorView()
    
    private var fileID: String?
    private var fileType: FileType?
    
    public var fileURL: URL?
    public var fileData: Data?
    
    private var fileExtension: String?
    private var fileName: String?
    
    public weak var delegate: FileLoaderDelegate?
    
    private var selectDocumentDestinationURL: URL?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupRightBarButton()
    }

    /// Places an imageView and displays the image from the given data.
    /// - Parameter imageData: Data object of the image.
    private func displayImage(imageData: Data) {
        
        let imageView = UIImageView(frame: view.bounds)
        imageView.center = view.center
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(data: imageData)
        
        view.addSubview(imageView)
        imageView.frame = view.bounds
        
    }
    
    /// Places WebView and displays the document from the given data using the path extension for file type.
    /// - Parameters:
    ///   - documentData: data of the file.
    ///   - pathExtension: the extension (pdf, docx) of the file.
    private func displayDocument(documentData: Data, pathExtension: String) {
        
        let webView = WKWebView(frame: view.bounds)
        webView.backgroundColor = .systemBackground
        
        webView.center = view.center
        view.addSubview(webView)
        
        do {
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let fileURL = temporaryDirectory.appendingPathComponent("document").appendingPathExtension(pathExtension)
            self.fileURL = fileURL
            
            try documentData.write(to: fileURL)
            
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
            
            
        } catch {
            showAlert(title: "Error displaying document: \(error.localizedDescription)")
        }
        
    }
    
    
    /// Adds a AVPlayerViewController and plays the video from the given data by storing it in a temporary directory and getting it's URL.
    /// - Parameters:
    ///   - videoData: The data of the video.
    ///   - filename: The name of the file.
    ///   - pathExtension: The extension of the video (mp4, mov)
    private func playVideo(videoData: Data, filename: String, pathExtension: String) {
        do {
            let temporaryDirectory = FileManager.default.temporaryDirectory
            let fileURL = temporaryDirectory.appendingPathComponent(filename).appendingPathExtension(pathExtension)
            try videoData.write(to: fileURL)
            
            self.fileURL = fileURL
            
            let playerItem = AVPlayerItem(url: fileURL)
            let player = AVPlayer(playerItem: playerItem)
            
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            addChild(playerViewController)
            view.addSubview(playerViewController.view)
            
            playerViewController.view.frame = view.bounds
            
            player.play()
        } catch {
            showAlert(title: "Error playing video: \(error.localizedDescription)")
        }
    }
    
    /// Fetches the data of the file at the specified file ID and sets the property of fileExtension.
    /// - Parameters:
    ///   - fileID: The ID of the file.
    ///   - fileExtension: The extension of the file.
    public func getData(for file: LoadFileViewModel, fileExtension: String) {
        
        guard let fileID = file.fileId else { return }
        self.fileID = fileID
        if let data = delegate?.getFileData() {
            
            if fileExtension.mimeType().contains("image") {
                self.fileType = .image
                self.displayImage(imageData: data)
            } else if fileExtension.mimeType().contains("video") {
                self.fileType = .video
                self.playVideo(videoData: data, filename: file.nameOfFile, pathExtension: fileExtension)
            } else {
                self.fileType = .document
                self.displayDocument(documentData: data, pathExtension: fileExtension)
            }
 
        } else {
            getDataOfFile(fileID: fileID, fileExtension: fileExtension)
            self.fileExtension = fileExtension
            self.fileName = file.nameOfFile
        }
        
    }
    
    /// Starts an activity indicator and gets the data of the file with file ID from drive manager and displays it on the screen.
    /// - Parameters:
    ///   - fileID: The ID of the file.
    ///   - fileExtension: The extension of the file.
    private func getDataOfFile(fileID: String, fileExtension: String) {
        
        startActivityIndicator()
        
        driveManager.getFileData(of: fileID) { [weak self] fileData, error in
            guard let self = self else { return }
            if error != nil {
                self.activityIndicator.stopAnimating()
                self.showAlert(title: "Error")
            }
            
            self.fileID = fileID
            
            guard let fileData = fileData else {
                self.activityIndicator.stopAnimating()
                self.showAlert(title: "file data nil")
                return
            }
            
            let mimeType = fileData.contentType
            let data = fileData.data
            delegate?.addToDictionary(data: data)
            
            if mimeType.contains("image") {
                DispatchQueue.main.async {
                    self.displayImage(imageData: data)
                }
                
                self.fileType = .image
            } else if mimeType.contains("video") {
                DispatchQueue.main.async {
                    self.playVideo(videoData: data, filename: fileData.fileID, pathExtension: fileExtension)
                }
                
                self.fileType = .video
            } else {
                DispatchQueue.main.async {
                    self.displayDocument(documentData: data, pathExtension: fileExtension)
                }
                
                self.fileType = .document
            }
            
            self.activityIndicator.stopAnimating()
            
        }
        
    }
    
    /// Clears the temporary folders used in case of videos or documents.
    private func cleanupTemporaryFiles() {
        if let fileURL = fileURL {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                showAlert(title: "Error removing temporary file: \(error.localizedDescription)")
            }
        }
    }
    
    /// Sets off the activity indicator.
    private func startActivityIndicator() {
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .large
        activityIndicator.backgroundColor = .systemBackground.withAlphaComponent(0.7)
        view.addSubview(activityIndicator)
        activityIndicator.frame = view.bounds
        activityIndicator.startAnimating()
        
    }
    
    /// Sets up the right bar button which initiates downloading.
    private func setupRightBarButton() {
        
        let barButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), style: .plain, target: self, action: #selector(selectFolder))
        navigationItem.rightBarButtonItem = barButton
    
    }
    
    /// Lets the user select the folder they want to download the file in.
    @objc
    private func selectFolder() {
        
        if self.fileType == .document {
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder], asCopy: false)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = false
            documentPicker.shouldShowFileExtensions = true
            present(documentPicker, animated: true, completion: nil)
        } else {
            guard let fileID = fileID else { return }
            download(fileID: fileID)
        }
        
    }
    
    /// Moves the file from one specified URL to the other.
    /// - Parameters:
    ///   - sourceURL: The URL the file currently resides.
    ///   - destinationURL: The destination it should be moved to.
    private func moveFile(from sourceURL: URL, to destinationURL: URL) {
        let fileManager = FileManager.default
        do {
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            
        } catch {
            
            showAlert(title: "Error moving file: \(error.localizedDescription)")
            
        }
    }
    
    /// Shows the alert on screen with a title
    /// - Parameter title: The title of the alert.
    private func showAlert(title: String) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    /// Downloads the file with the fileID from drive manager.
    /// - Parameter fileID: The ID of the file that should be downloaded
    private func download(fileID: String) {
        startActivityIndicator()
        
        DispatchQueue.main.async {
            
            self.navigationController?.navigationBar.isUserInteractionEnabled = false
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            self.navigationItem.leftBarButtonItem?.isEnabled = false
        }
        
        driveManager.download(fileID, progressHandler: nil) { [weak self] data, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.navigationController?.navigationBar.isUserInteractionEnabled = true
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                self.navigationItem.leftBarButtonItem?.isEnabled = true
                
            }
            
            guard let data = data, error == nil else {
                self.showAlert(title: "Error downloading file: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            activityIndicator.stopAnimating()
    
            DispatchQueue.main.async {
                switch self.fileType {
                    case .image:
                        guard let image = UIImage(data: data) else {
                            self.showAlert(title: "Failed to convert data to UIImage")
                            return
                        }
                        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
                        self.showAlert(title: "Photo downloaded successfully")
                        
                    case .video:
                        guard let fileURL = self.fileURL else {
                            self.showAlert(title: "File URL is nil")
                            return
                        }
                        UISaveVideoAtPathToSavedPhotosAlbum(fileURL.path, self, nil, nil)
                        self.showAlert(title: "Video downloaded successfully")
                        
                    default:
                        guard let fileURL = self.fileURL else {
                            self.showAlert(title: "File URL is nil")
                            return
                        }
                        self.moveFile(from: fileURL, to: self.selectDocumentDestinationURL!.appendingPathComponent(self.fileName!).appendingPathExtension(self.fileExtension!))
                        self.showAlert(title: "Document downloaded successfully")
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        cleanupTemporaryFiles()
        navigationItem.rightBarButtonItem = nil
    }
    
}

extension FileDisplayViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFolderURL = urls.first else { return }
        selectDocumentDestinationURL = selectedFolderURL
        print("Selected folder URL: \(selectedFolderURL.path)")
        
        if let fileID = fileID {
            download(fileID: fileID)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
}


