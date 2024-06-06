//
//  ProfileViewController.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 07/05/24.
//

import UIKit
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    private let profileImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    private let profileName: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private let profileEmail: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private let signOutButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign Out", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubviews()
        setupConstraints()
        loadUser()
        
        view.backgroundColor = .systemBackground
        
        signOutButton.addTarget(self, action: #selector(logOutUser), for: .touchUpInside)
    }
    
    private func addSubviews() {
        view.addSubview(profileImage)
        view.addSubview(profileName)
        view.addSubview(profileEmail)
        view.addSubview(signOutButton)
    }
    
    private func loadUser() {
        guard let userProfile = GIDSignIn.sharedInstance.currentUser?.profile else { return }
        if userProfile.hasImage {
            guard let url = userProfile.imageURL(withDimension: 200) else { return }
            let driveManager = DriveManager.shared
            Task {
                do {
                    let data = try await driveManager.downloadImage(from: url)
                    let image = UIImage(data: data)
                    profileImage.image = image
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        profileName.text = userProfile.name
        profileEmail.text = userProfile.email
        
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            profileImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            profileImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileImage.bottomAnchor.constraint(equalTo: view.centerYAnchor),
            
            profileName.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 20),
            profileName.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            profileName.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            profileName.heightAnchor.constraint(equalToConstant: 100),
            
            profileEmail.topAnchor.constraint(equalTo: profileName.bottomAnchor, constant: 10),
            profileEmail.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            profileEmail.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            profileEmail.heightAnchor.constraint(equalToConstant: 60),
            
            signOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            signOutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            signOutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            signOutButton.heightAnchor.constraint(equalToConstant: 55)
            
        ])
    }
    
    @objc
    private func logOutUser() {
        GIDSignIn.sharedInstance.signOut()
        let loginViewController = LoginViewController()
        UIApplication.shared.windows.first?.rootViewController = loginViewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }

}
