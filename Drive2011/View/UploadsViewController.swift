//
//  UploadsViewController.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 06/05/24.
//

import UIKit
import MobileCoreServices
import GoogleAPIClientForREST

class UploadsViewController: UIViewController {
    
    private var uploads: [LoadFileViewModel] = []

    private var filteredUploads: [LoadFileViewModel] = []
    
    private var loadedFiles: [Int: Data] = [:]
    private var currentlyDisplaying: Int?
    
    private var isSearchActive: Bool = false
    private let driveManager = DriveManager.shared
    
    private let activityIndicator = UIActivityIndicatorView()
    private let searchBar = UISearchController(searchResultsController: nil)

    private var fileToUpload: LoadFileViewModel?
    
    private let refreshControl = UIRefreshControl()

    private let uploadTable: UITableView = {
        
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 75
        
        let backgroundView = UIView()
        tableView.backgroundView = backgroundView
        backgroundView.backgroundColor = .systemBackground
        
        
        return tableView
    }()
    
    private let progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progressTintColor = .systemBlue
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        progressView.backgroundColor = .systemGray
        
        return progressView
    }()
    
    private var progressHandler: ((Float) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Uploads"
        view.backgroundColor = .systemBackground
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        uploadTable.refreshControl = refreshControl
        
        setProgress()
        setupSearchBar()
        getUsersUploads()
        setupTableView()
        setupConstriants()
        setupBarButtons()
        
    }
    
    //MARK: Background Tasks
    private func registerBackgroundTask() {
        
    }
    //MARK: Application UI
    
    private func setProgress() {
        
        progressHandler = { [weak self] progress in
            guard let self = self else { return }
            self.progressView.setProgress(progress, animated: true)
        }
    }
    
    private func showProgress() {
        
        guard let headerView = uploadTable.tableHeaderView else { return }
        headerView.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: headerView.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 5)
        ])
        
    }
    
    internal func removeProgress() {
        progressView.removeFromSuperview()
    }
    
    private func setupSearchBar() {
        searchBar.searchResultsUpdater = self
        searchBar.obscuresBackgroundDuringPresentation = false
        searchBar.automaticallyShowsCancelButton = true
        searchBar.searchBar.placeholder = "Search"
        
        navigationItem.searchController = searchBar
    }
    
    private func setupTableView() {
        view.addSubview(uploadTable)
        
        uploadTable.delegate = self
        uploadTable.dataSource = self
    
        uploadTable.backgroundColor = .systemBackground
        uploadTable.tableHeaderView = getHeaderView()
        uploadTable.tableHeaderView?.isUserInteractionEnabled = true
        
        uploadTable.register(LoadTableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    private func getHeaderView() -> UIView {
        
        let headerView = UIView()
        headerView.frame = CGRect(x: 0, y: 0, width: uploadTable.frame.width, height: 50)
        
        let headerLabel = UILabel()
        headerLabel.text = "Filter"
        headerLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        headerLabel.textAlignment = .left
        headerLabel.numberOfLines = 1
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(headerLabel)
        
        let sortButton = UIButton()
        sortButton.setBackgroundImage(UIImage(systemName: "arrow.up.arrow.down.circle"), for: .normal)
        sortButton.addTarget(self, action: #selector(sortTable), for: .touchUpInside)
        sortButton.tintColor = .systemBlue
        sortButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        headerView.addSubview(sortButton)
        
        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),
            headerLabel.widthAnchor.constraint(equalToConstant: 100),
            headerLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            sortButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            sortButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            sortButton.heightAnchor.constraint(equalToConstant: 25),
            sortButton.widthAnchor.constraint(equalToConstant: 25)
        ])
        
        return headerView
        
    }
    
    private func uploadToDrive(file: LoadFileViewModel) {
        showProgress()
        driveManager.uploadFile("BetterWork", filePath: file.filePath!, MIMEType: file.mimeType, progressHandler: progressHandler) {
            [weak self] fileId, error in
            
            guard let self = self else { return }
            guard let fileId = fileId else {
                self.showAlert(title: "Failed to upload file", message: error?.localizedDescription)
                return
            }
            
            self.fileToUpload?.fileId = fileId
            guard let fileToUpload = fileToUpload else {
                showAlert(title: "File To Upload was not found", message: nil)
                return
            }
            self.uploads.append(fileToUpload)
            
            DispatchQueue.main.async {
                self.uploadTable.beginUpdates()
                self.uploadTable.insertRows(at: [IndexPath(row: self.uploads.count - 1, section: 0)], with: .automatic)
                self.uploadTable.endUpdates()
            }
            
            self.showAlert(title: "Upload Successful", message: nil)
            removeProgress()
        }

    }
    
    private func getUsersUploads() {
        
        startActivityIndicator()
        
        driveManager.listFilesInFolder("BetterWork") { [weak self] fileList, error in
            guard let self = self else { return }
            guard let fileList = fileList, error == nil,
            let files = fileList.files else { 
                print("File not found.")
                return
            }
            
            let existingFilesOnDrive = files.map {
                
                let loadFileModel = LoadFileViewModel(filePath: nil, date: $0.viewedByMeTime?.date.description ?? Date().description, mimeType: $0.mimeType!, fileId: $0.identifier!, nameOfFile: $0.name!, fileSize: $0.size!.uint64Value)
                
                return loadFileModel
            }
            
            self.uploads = existingFilesOnDrive
            self.activityIndicator.stopAnimating()
            
            DispatchQueue.main.async {
                self.uploadTable.reloadData()
            }
            
        }

    }

    private func setupBarButtons() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(chooseFileToUpload))
        
    }
    
    private func startActivityIndicator() {
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .large
        view.addSubview(activityIndicator)
        
        activityIndicator.frame = uploadTable.bounds
        activityIndicator.center = uploadTable.center
        
        activityIndicator.startAnimating()
        
    }
    
    private func showAlert(title: String, message: String?) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .cancel))
        
        self.present(alertController, animated: true)
    }
    
    private func setupConstriants() {
        
        NSLayoutConstraint.activate([
            uploadTable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            uploadTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            uploadTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            uploadTable.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    private func getMediaFromGallery() {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            
            imagePicker.mediaTypes = [
                kUTTypeImage as String,
                kUTTypeMovie as String
            ]
            
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true)
        }
    }
    
    private func getMediaFromCamera() {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            
            imagePicker.mediaTypes = [
                kUTTypeImage as String,
                kUTTypeMovie as String
            ]
            
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true)
        }
    }
    
    private func getDocumentsFromPicker() {
    
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])

        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        
        present(documentPicker, animated: true)
    }
    
    private func getFileSize(from url: URL) -> NSNumber {
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
            return NSNumber(integerLiteral: resources.fileSize!)
        } catch {
            print("Error retrieving file size: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func getFileTypeRank(for mimeType: String) -> Int {
        if mimeType.contains("image") {
            return 1
        } else if mimeType.contains("video") {
            return 2
        } else  {
            return 3
        }
    }
    
    private func getSortType() {
        let sortType = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let memorySort = UIAlertAction(title: "Memory", style: .default) { action in

            self.uploads.sort {
                $0.fileSize < $1.fileSize
            }
            
            DispatchQueue.main.async {
                self.uploadTable.reloadData()
            }
        }
        
        let fileTypeSort = UIAlertAction(title: "File Type", style: .default) { action in
            self.uploads.sort { file1, file2 in
                let rank1 = self.getFileTypeRank(for: file1.mimeType)
                let rank2 = self.getFileTypeRank(for: file2.mimeType)
                return rank1 < rank2
            }
            
            DispatchQueue.main.async {
                self.uploadTable.reloadData()
            }
            
        }
        
        let AlphabetSort = UIAlertAction(title: "Alphabetically", style: .default) { action in
            self.uploads.sort { file1, file2 in
                return file1.nameOfFile < file2.nameOfFile
            }
            
            DispatchQueue.main.async {
                self.uploadTable.reloadData()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        sortType.addAction(fileTypeSort)
        sortType.addAction(memorySort)
        sortType.addAction(AlphabetSort)
        sortType.addAction(cancelAction)
        
        self.present(sortType, animated: true)
    }
    
    @objc 
    private func chooseFileToUpload() {
        
        let choiceOfFileType = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let addImageFromPhotosAction = UIAlertAction(title: "Photos", style: .default) { action in
            self.getMediaFromGallery()
        }
        
        let addImageFromCameraAction = UIAlertAction(title: "Camera", style: .default) { action in
            self.getMediaFromCamera()
        }
        
        let addDocumentAction = UIAlertAction(title: "Document", style: .default) { action in
            self.getDocumentsFromPicker()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        choiceOfFileType.addAction(addImageFromCameraAction)
        choiceOfFileType.addAction(addImageFromPhotosAction)
        choiceOfFileType.addAction(addDocumentAction)
        choiceOfFileType.addAction(cancelAction)
        
        self.present(choiceOfFileType, animated: true)
    }
    
    @objc 
    private func refreshData() {
        
        driveManager.listFilesInFolder("BetterWork") { [weak self] fileList, error in
            guard let self = self else { return }
            guard let fileList = fileList, error == nil,
                  let files = fileList.files else {
                print("File not found.")
                return
            }
            
            let existingFilesOnDrive = files.map {
                
                let loadFileModel = LoadFileViewModel(filePath: nil, date: $0.viewedByMeTime?.date.description ?? Date().description, mimeType: $0.mimeType!, fileId: $0.identifier!, nameOfFile: $0.name!, fileSize: $0.size!.uint64Value)
                
                return loadFileModel
            }
            
            self.uploads = existingFilesOnDrive
            
            DispatchQueue.main.async {
                self.uploadTable.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
        
    }
    
    @objc
    private func sortTable() {
        if uploads.count > 1 {
            getSortType()
        } else {
            showAlert(title: "There is only one file", message: nil)
        }
    }

}

extension UploadsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! NSString
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let url = info[UIImagePickerController.InfoKey.imageURL] as! URL
            let name = url.lastPathComponent
            let date = Date().description
            let mimeType = url.pathExtension.mimeType()
            let fileSize = getFileSize(from: url)
            
            
            let fileToUpload = LoadFileViewModel(filePath: url, date: date, mimeType: mimeType, nameOfFile: name, fileSize: UInt64(truncating: fileSize))
            self.fileToUpload = fileToUpload
            self.uploadToDrive(file: fileToUpload)
            
            picker.dismiss(animated: true)
            
        } else if mediaType.isEqual(to: kUTTypeMovie as String) {
            
            let url = info[UIImagePickerController.InfoKey.mediaURL] as! URL
            let name = url.lastPathComponent
            let date = Date().description
            let mimeType = url.pathExtension.mimeType()
            let fileSize = getFileSize(from: url)
            
            let fileToUpload = LoadFileViewModel(filePath: url, date: date, mimeType: mimeType, nameOfFile: name, fileSize: UInt64(truncating: fileSize))
            
            self.fileToUpload = fileToUpload
            
            self.uploadToDrive(file: fileToUpload)
            
            picker.dismiss(animated: true)
            
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }
    
    
}

extension UploadsViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        
        let mimeType = url.pathExtension.mimeType()
        let fileSize = getFileSize(from: url)
        
        driveManager.uploadFile("BetterWork", filePath: url, MIMEType: mimeType, progressHandler: progressHandler) { [weak self] fileId, error in
            
            if error != nil {
                return
            }
            
            guard let self = self else { return }
            
            guard let fileId = fileId else { return }
            let date = Date().description
            
            let fileToUpload = LoadFileViewModel(filePath: url, date: date, mimeType: mimeType, fileId: fileId, nameOfFile: url.lastPathComponent, fileSize: UInt64(truncating: fileSize))
            
            self.fileToUpload = fileToUpload
            self.uploads.append(fileToUpload)
            
            DispatchQueue.main.async {
                self.uploadTable.reloadData()
            }
            
            self.fileToUpload?.fileId = fileId
            
        }
        
        controller.dismiss(animated: true)
    }
    
}

extension UploadsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchActive ? filteredUploads.count : uploads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LoadTableViewCell
        
        if isSearchActive {
            let filteredFile = filteredUploads[indexPath.row]
            cell.setupCell(with: filteredFile)
        } else {
            let uploadFile = uploads[indexPath.row]
            cell.setupCell(with: uploadFile)
        }
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        self.currentlyDisplaying = indexPath.row
        tableView.isUserInteractionEnabled = false
        
        var fileSelected: LoadFileViewModel
        
        if isSearchActive {
            let selectedFile = filteredUploads[indexPath.row]
            fileSelected = selectedFile
        } else {
            let selectedFile = uploads[indexPath.row]
            fileSelected = selectedFile
        }
        
        let fullScreen = FileDisplayViewController()
        fullScreen.delegate = self
        
        let fileExtension = fileSelected.mimeType.fileExtension()
        
        fullScreen.hidesBottomBarWhenPushed = true
        
        fullScreen.getData(for: fileSelected, fileExtension: fileExtension)
        
        self.navigationController?.pushViewController(fullScreen, animated: true)
        tableView.isUserInteractionEnabled = true
        searchBar.isActive = false
        isSearchActive = false
    }
    
}

extension UploadsViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            
            isSearchActive = !searchText.isEmpty
            
            filteredUploads = uploads.filter { file in
                
                return file.nameOfFile.lowercased().contains(searchText.lowercased())
            }
            
            DispatchQueue.main.async {
                self.uploadTable.reloadData()
            }
        }
    }
    
}

extension UploadsViewController: FileLoaderDelegate {
    
    func getFileData() -> Data? {
        guard let currentlyDisplaying = currentlyDisplaying else { return nil }
        let data = loadedFiles[currentlyDisplaying]
        return data
    }
    
    func addToDictionary(data: Data) {
        guard let currentlyDisplaying = currentlyDisplaying else { return }
        loadedFiles[currentlyDisplaying] = data
    }
    
}

extension String {
    
    public func mimeType() -> String {
        
        switch self.lowercased() {
            case "pdf":
                return "application/pdf"
            case "doc", "docx":
                return "application/msword"
            case "xls", "xlsx":
                return "application/vnd.ms-excel"
            case "ppt", "pptx":
                return "application/vnd.ms-powerpoint"
            case "txt":
                return "text/plain"
            case "rtf":
                return "application/rtf"
            case "html":
                return "text/html"
            case "csv":
                return "text/csv"
            case "jpg", "jpeg":
                return "image/jpeg"
            case "png":
                return "image/png"
            case "gif":
                return "image/gif"
            case "bmp":
                return "image/bmp"
            case "mp4":
                return "video/mp4"
            case "mov":
                return "video/quicktime"
            case "avi":
                return "video/x-msvideo"
            case "mkv":
                return "video/x-matroska"
                
            default:
                return "application/octet-stream"
                
        }
        
    }
    
    public func fileExtension() -> String {
        
        switch self.lowercased() {
            case "application/pdf":
                return "pdf"
            case "application/msword":
                return "docx"
            case "application/vnd.ms-excel":
                return "xlsx"
            case "application/vnd.ms-powerpoint":
                return "pptx"
            case "text/plain":
                return "txt"
            case "application/rtf":
                return "rtf"
            case "text/html":
                return "html"
            case "text/csv":
                return "csv"
            case "image/jpeg":
                return "jpg"
            case "image/png":
                return "png"
            case "image/gif":
                return "gif"
            case "image/bmp":
                return "bmp"
            case "video/mp4":
                return "mp4"
            case "video/quicktime":
                return "mov"
            case "video/x-msvideo":
                return "avi"
            case "video/x-matroska":
                return "mkv"
            default:
                return ""
        }
        
    }
}
                                                                      
