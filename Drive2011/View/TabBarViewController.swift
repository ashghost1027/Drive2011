//
//  TabBarViewController.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 06/05/24.
//

import UIKit

class TabBarViewController: UIViewController {
    
    private let tabBarVC: UITabBarController = {
        let tabBar = UITabBarController()
        tabBar.view.backgroundColor = .systemBackground
        
        return tabBar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        view.backgroundColor = .systemBackground
    }
    
    private func setupTabBar() {
        
        addChild(tabBarVC)
        view.addSubview(tabBarVC.view)
        tabBarVC.view.frame = view.bounds
        tabBarVC.tabBar.backgroundColor = UIColor.systemBackground
        tabBarVC.tabBar.isTranslucent = true
        tabBarVC.view.backgroundColor = .systemBackground
        
        let uploadVC = UploadsViewController()
        let profileVC = ProfileViewController()
        
        let uploadScreen = UINavigationController(rootViewController: uploadVC)
        let profileScreen = UINavigationController(rootViewController: profileVC)
        
        uploadScreen.tabBarItem.title = "Upload"
        profileScreen.tabBarItem.title = "Profile"
        
        uploadScreen.tabBarItem.image = UIImage(systemName: "square.and.arrow.up")
        profileScreen.tabBarItem.image = UIImage(systemName: "person.crop.circle")
        
        tabBarVC.setViewControllers([uploadScreen, profileScreen], animated: true)
        
    }
    
    


}
