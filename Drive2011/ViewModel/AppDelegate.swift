//
//  AppDelegate.swift
//  Drive2011
//
//  Created by aswin-zstch1323 on 03/05/24.
//

import UIKit
import GoogleSignIn
import GoogleSignInSwift
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let uploadTaskIdentifier = "com.Aswin.Drive2011.BackgroundUpload"
    let downloadTaskIdentifier = "com.Aswin.Drive2011.BackgroundDownload"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: uploadTaskIdentifier, using: nil) { task in
            self.handleUploadTask(task: task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: downloadTaskIdentifier, using: nil) { task in
            self.handleDownloadTask(task: task as! BGProcessingTask)
        }
        
        return true
    }


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var handled: Bool
        
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        
        return false

    }
     
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleUploadTask()
        scheduleDownloadTask()
    }

}

extension AppDelegate {
    
    func handleUploadTask(task: BGProcessingTask) {
        scheduleUploadTask() // Reschedule the next task
        
        task.expirationHandler = {
            // Clean up if the task expires
        }
        
        let manager = DriveManager.shared
        
        guard let filePath = UserDefaults.standard.url(forKey: "filePathToUpload"),
              let mimeType = UserDefaults.standard.string(forKey: "mimetypeOfFileToUpload") else { return }
        
        // Assume you have a method to start/resume the upload
        manager.resumeUpload(filePath: filePath, mimeType: mimeType) { success in
            task.setTaskCompleted(success: success)
        }
    }
    
    func handleDownloadTask(task: BGProcessingTask) {
        scheduleDownloadTask() // Reschedule the next task
        
        task.expirationHandler = {
            // Clean up if the task expires
        }
        
        let manager = DriveManager.shared
        
        guard let fileID = UserDefaults.standard.string(forKey: "fileIDToDownload") else { return }
        
        manager.resumeDownload(fileID: fileID) { success in
            task.setTaskCompleted(success: success)
        }
    }
    
    func scheduleUploadTask() {
        let request = BGProcessingTaskRequest(identifier: uploadTaskIdentifier)
        request.requiresNetworkConnectivity = true // Ensure network connectivity
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule upload task: \(error)")
        }
    }
    
    func scheduleDownloadTask() {
        let request = BGProcessingTaskRequest(identifier: downloadTaskIdentifier)
        request.requiresNetworkConnectivity = true // Ensure network connectivity
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule download task: \(error)")
        }
    }
}
