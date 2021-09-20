//
//  SettingsViewController.swift
//  Pinned
//
//  Created by Hong Son Ngo on 22/01/2021.
//

import UIKit
import FirebaseAuth
import UserNotifications

class SettingsViewController: UIViewController {
    
    private let center = UNUserNotificationCenter.current()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        center.delegate = self
    }
    
    // Log out
    @IBAction func signOutButtonTapped() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginViewController = storyboard.instantiateViewController(identifier: "LoginViewController")
            
            UIView.transition(with: UIApplication.shared.windows.first!, duration: 0.8, options: .transitionCurlDown, animations: {
                        let oldState = UIView.areAnimationsEnabled
                        UIView.setAnimationsEnabled(false)
                        UIApplication.shared.windows.first!.rootViewController = loginViewController
                        UIView.setAnimationsEnabled(oldState)
                
            }, completion: nil)
            
            
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}

extension SettingsViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.alert, .badge, .sound])
        }
}
