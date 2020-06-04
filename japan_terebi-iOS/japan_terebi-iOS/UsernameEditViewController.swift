//
//  UsernameEditViewController.swift
//  japan_terebi-iOS
//
//  Created by Anime no Sekai on 21/04/2020.
//  Copyright © 2020 Anime no Sekai. All rights reserved.
//

import UIKit

class UsernameEditViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var editingUsernameTitle: UILabel!
    
    let defaults = UserDefaults.standard
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.editingUsernameTitle.alpha = 0
        self.username.alpha = 0
        self.submitButton.alpha = 0
        
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.editingUsernameTitle.frame.origin.y -= 100
            self.editingUsernameTitle.alpha = 1
        })
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.username.frame.origin.y -= 90
            self.username.alpha = 1
        })
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.submitButton.frame.origin.y -= 90
            self.submitButton.alpha = 1
        })
        
        username.text = defaults.string(forKey: "username") ?? "anon"
        submitButton.layer.cornerRadius = 5
        
        self.username.delegate = self
        // Do any additional setup after loading the view.
    }
    
    @IBAction func goBack(_ sender: Any) {
        dismiss(animated:true, completion: nil)
    }
    
    @IBAction func submitUsername(_ sender: Any) {
        defaults.set(username.text, forKey: "username")
        username.resignFirstResponder()
        dismiss(animated:true, completion: nil)
    }
    
    @IBAction func submitUsernameReturnKey(_ sender: Any) {
        defaults.set(username.text, forKey: "username")
        username.resignFirstResponder()
        dismiss(animated:true, completion: nil)
    }

}
