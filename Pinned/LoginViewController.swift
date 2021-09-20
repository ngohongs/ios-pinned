//
//  ViewController.swift
//  Pinned
//
//  Created by Hong Son Ngo on 21/01/2021.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseDatabase
import CodableFirebase

class LoginViewController: UIViewController {    
    @IBOutlet weak var signInButton: GIDSignInButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        GIDSignIn.sharedInstance()?.presentingViewController = self

    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
}

