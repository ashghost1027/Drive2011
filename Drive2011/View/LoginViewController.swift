//
//  ViewController.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 03/05/24.
//

import UIKit
import GoogleSignIn

class LoginViewController: UIViewController {
    
    private let signInButton = GIDSignInButton()

    private var accessToken: String?
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.text = "Welcome to Drive2011"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private let signInLabel: UILabel = {
        let label = UILabel()
        label.text = "Please sign in using your google account to access drive."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        addSubviews()
        setupConstraints()
        setupGoogleSignInButton()
    }
    
    private func setupGoogleSignInButton() {

        signInButton.colorScheme = .dark
        signInButton.style = .wide
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        
        signInButton.addTarget(self, action: #selector(commenceGoogleSignIn), for: .touchUpInside)
    }
    
    private func addSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(signInLabel)
        view.addSubview(signInButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(equalToConstant: 200),
            
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            signInButton.widthAnchor.constraint(equalToConstant: 300),
            signInButton.heightAnchor.constraint(equalToConstant: 60),
            
            signInLabel.bottomAnchor.constraint(equalTo: signInButton.topAnchor, constant: -20),
            signInLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            signInLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            signInLabel.heightAnchor.constraint(equalToConstant: 50)
            
            
        ])
    }
    
    private func signInUserWithGoogle() async throws {
        
        let scopes = ["https://www.googleapis.com/auth/drive.readonly", "https://www.googleapis.com/auth/drive", "https://www.googleapis.com/auth/drive.file"]
        
        try await GIDSignIn.sharedInstance.signIn(withPresenting: self, hint: nil, additionalScopes: scopes)
        
        if requiredScopesGranted() {
            refreshTokenIfNeeded()
            presentTabBarForUser()
            
        } else {
            self.showAlert("Permission Required", "Please grant the required permission to access your files.")
        }

    }
    
    private func presentTabBarForUser() {
        
        let tabBarVC = TabBarViewController()
        tabBarVC.modalPresentationStyle = .fullScreen
        
        self.present(tabBarVC, animated: true)
        
    }

    private func requiredScopesGranted() -> Bool {
        guard let grantedScopes = GIDSignIn.sharedInstance.currentUser?.grantedScopes else {
            return false
        }
        let requiredScopes: Set<String> = ["https://www.googleapis.com/auth/drive.readonly", "https://www.googleapis.com/auth/drive", "https://www.googleapis.com/auth/drive.file"]
        
        return requiredScopes.isSubset(of: grantedScopes)
        
    }

    private func refreshTokenIfNeeded() {
        
        guard let user = GIDSignIn.sharedInstance.currentUser else { return }
        
        user.refreshTokensIfNeeded { user, error in
            if let error = error {
                print("Token refresh failed with error: \(error.localizedDescription)")
            } else if let user = user {
                self.accessToken = user.accessToken.tokenString
            }
        }
        
    }
    
    func accessTokenIsValid() -> Bool {
        return Date() < GIDSignIn.sharedInstance.currentUser?.accessToken.expirationDate ?? Date()
    }
    
    private func showAlert(_ title: String, _ message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc
    private func commenceGoogleSignIn() {
        
        Task {
            do {
                try await signInUserWithGoogle()
            } catch {
                showAlert("Sign in Error", error.localizedDescription)
            }
        }
    }
    
}
