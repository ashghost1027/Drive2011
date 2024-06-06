//
//  LoadTableViewCell.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 07/05/24.
//

import UIKit

class LoadTableViewCell: UITableViewCell {
    
    private let fileTypeImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    private let fileName: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .gray
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private let memory: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .gray
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .right
        
        return label
    }()
    
    private var fileType: FileType = .document
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
        setupConstraints()
    }
    
    private func setupFileTypeImage(with fileType: FileType) {
        
        switch fileType {
            case .document:
                fileTypeImage.image = UIImage(systemName: "doc")
                
            case .image:
                fileTypeImage.image = UIImage(systemName: "photo")
                
            case .video:
                fileTypeImage.image = UIImage(systemName: "video")
        }
        
    }
    
    public func setupCell(with fileInfo: LoadFileViewModel) {
        
        fileName.text = fileInfo.nameOfFile
        memory.text =  "\((Double(fileInfo.fileSize) / (1024.0 * 1024.0)).truncate(places: 2)) MB"
        if fileInfo.mimeType.contains("image") {
            fileType = .image
        } else if fileInfo.mimeType.contains("video") {
            fileType = .video
        } else {
            fileType = .document
        }
        setupFileTypeImage(with: fileType)
        
    }
    
    public func getFileType() -> FileType {
        self.fileType
    }
    
    private func getDate(from string: String) -> String? {
        
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        if let date = dateFormatterGet.date(from: string) {
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "dd/MM/yyyy"
            
            let formattedDate = dateFormatterPrint.string(from: date)
            return formattedDate
        } else {
            return nil
        }

    }
    
    private func addSubviews() {
        addSubview(fileTypeImage)
        addSubview(memory)
        addSubview(fileName)
    }
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            fileTypeImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            fileTypeImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            fileTypeImage.heightAnchor.constraint(equalToConstant: 50),
            fileTypeImage.widthAnchor.constraint(equalToConstant: 50),
            
            fileName.leadingAnchor.constraint(equalTo: fileTypeImage.trailingAnchor, constant: 20),
            fileName.centerYAnchor.constraint(equalTo: centerYAnchor),
            fileName.widthAnchor.constraint(equalToConstant: 200),
            fileName.heightAnchor.constraint(equalTo: heightAnchor),
            
            memory.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
            memory.widthAnchor.constraint(equalToConstant: 50),
            memory.topAnchor.constraint(equalTo: topAnchor),
            memory.bottomAnchor.constraint(equalTo: bottomAnchor),
            
        ])
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("Could not initalize for some reason.")
    }
    
}

enum FileType {
    case image
    case video
    case document
}

extension Double {
    func truncate(places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded(.towardZero) / factor
    }
}
