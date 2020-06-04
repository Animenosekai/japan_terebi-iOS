//
//  MoreViewController.swift
//  japan_terebi-iOS
//
//  Created by Anime no Sekai on 21/04/2020.
//  Copyright © 2020 Anime no Sekai. All rights reserved.
//

import UIKit
import SafariServices

class MoreViewController: UIViewController {
    @IBOutlet weak var mainUIView: UIView!
    @IBOutlet weak var usernameBtn: UIButton!
    @IBOutlet weak var termsOfServicesBtn: UIButton!
    @IBOutlet weak var privacyPolicyBtn: UIButton!
    @IBOutlet weak var githubBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mainUIView.layer.cornerRadius = 15
        
        self.usernameBtn.layer.cornerRadius = 10
        self.termsOfServicesBtn.layer.cornerRadius = 10
        self.privacyPolicyBtn.layer.cornerRadius = 10
        self.githubBtn.layer.cornerRadius = 10
        
        setTextInsideBtn()
        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange), name: UserDefaults.didChangeNotification, object: nil)
        
    }
    
    @objc func userDefaultsDidChange(){
        setTextInsideBtn()
    }
    func setTextInsideBtn(){
            let defaults = UserDefaults.standard
            usernameBtn.setTitle(defaults.string(forKey: "username") ?? "anon", for: .normal)
    }
    
    @IBAction func editUsername(_ sender: Any) {
        performSegue(withIdentifier: "editUsername", sender: nil)
        
        UIView.animate(withDuration: 0.5, delay: 0, animations: {
            self.usernameBtn.transform = CGAffineTransform(scaleX: 1, y: 1)
        })
    }
    
    @IBAction func openTermsOfServices(_ sender: Any) {
        showInAppSafari(url: "https://japanterebi.netlify.app/legal/termsofservices")
    }
    @IBAction func openPrivacyPolicy(_ sender: Any) {
        showInAppSafari(url: "https://japanterebi.netlify.app/legal/termsofservices")
    }
    @IBAction func openGitHub(_ sender: Any) {
        showInAppSafari(url: "https://github.com/Animenosekai")
    }
    
    func showInAppSafari(url: String){
        guard let url = URL(string: url) else {
            return
        }
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }
    
    
    @IBAction func goBack(_ sender: Any) {
        dismiss(animated:true, completion: nil)
    }
    
    
    
    
    
    // MARK: Animations
    @IBAction func usernameTouched(_ sender: Any) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 2, animations: {
                self.usernameBtn.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        })
    }
    
    @IBAction func usernameTouchCancel(_ sender: Any) {
        UIView.animate(withDuration: 0.2, delay: 0, animations: {
            self.usernameBtn.transform = CGAffineTransform(scaleX: 1, y: 1)
        })
    }
    
    @IBAction func termsOfServicesTouch(_ sender: Any) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 2, animations: {
            self.termsOfServicesBtn.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: { finish in
            UIView.animate(withDuration: 0.2, delay: 0, animations: {
                self.termsOfServicesBtn.transform = CGAffineTransform(scaleX: 1, y: 1)
            })
        })
    }
    
    @IBAction func privacyPolicyTouch(_ sender: Any) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 2, animations: {
            self.privacyPolicyBtn.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: { finish in
            UIView.animate(withDuration: 0.2, delay: 0, animations: {
                self.privacyPolicyBtn.transform = CGAffineTransform(scaleX: 1, y: 1)
            })
        })
    }
    
    @IBAction func githubTouch(_ sender: Any) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 2, animations: {
            self.githubBtn.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: { finish in
            UIView.animate(withDuration: 0.2, delay: 0, animations: {
                self.githubBtn.transform = CGAffineTransform(scaleX: 1, y: 1)
            })
        })
    }
}
