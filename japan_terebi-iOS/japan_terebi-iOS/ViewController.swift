//
//  ViewController.swift
//  japan_terebi-iOS
//
//  Created by Anime no Sekai on 09/04/2020.
//  Copyright © 2020 Anime no Sekai. All rights reserved.
//

import UIKit
import WebKit
import MediaPlayer
import Firebase
import AVKit
import AVFoundation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfChatInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellChat:ChatCell = tableView.dequeueReusableCell(withIdentifier: "chat", for: indexPath) as! ChatCell
        cellChat.setChat(chat: listOfChatInfo[indexPath.row])
        return cellChat
    }
    
    var ref = DatabaseReference.init()
    
    // MARK: Variables
    // Create these 3 properties in the top of your class
    var secondToFadeOut = 5 // How many second do you want the comment button to idle before the button fades.
    var timer = Timer() // Create the timer!
    var isTimerRunning: Bool = false // Need this to prevent multiple timers from running at the same time.
    var tvChannelsLogo = [UIImage]()
    var loopTimer = Timer()
    var nowPlayingInfo = String()
    let defaults = UserDefaults.standard
    
    // MARK: IBOutlets
    @IBOutlet weak var Player: WKWebView!
    @IBOutlet weak var activityIndicator: UIImageView!
    @IBOutlet weak var tvChannelsSelection: UIScrollView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var CommentBtn: UIButton!
    @IBOutlet weak var chatView: UIView!
    @IBOutlet weak var chatMessageContent: UITextField!
    @IBOutlet weak var chatContentTable: UITableView!
    @IBOutlet weak var moreBtn: UIButton!

    

    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Notifications
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustViewToKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustViewToKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        
        // Loading GIF
        bringLoadingInForeground()
        self.activityIndicator.image = UIImage.gif(name: "activityIndicator")
           
        
        //Buttons Initialization
        self.CommentBtn.layer.zPosition = 10
        self.CommentBtn.layer.cornerRadius = 5
        self.moreBtn.layer.cornerRadius = 25
        self.moreBtn.layer.zPosition = 10
        runTimer()
        // Add a tap gesture recognizer to the main view to determine when the screen was tapped (for the purpose of resetting the timer).
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tap(_:)))
        self.view.addGestureRecognizer(tapRecognizer)
        
        
        //Load Chat
        self.ref = Database.database().reference()
        
        self.chatView.layer.zPosition = 20
        self.chatView.frame.origin.x = 215
        self.chatView.alpha = 0
        self.chatMessageContent.layer.cornerRadius = 5
        chatContentTable.delegate = self
        chatContentTable.dataSource = self
        loadChat()
        
        chatContentTable.estimatedRowHeight = 150
        chatContentTable.rowHeight = UITableView.automaticDimension
        
        // TV Channels Selection
        self.tvChannelsSelection.frame.origin.y = -80
        tvChannelsLogo = [UIImage(named: "NTV500x500")!, UIImage(named: "NHK500x500")!, UIImage(named: "FUJITV500x500")!, UIImage(named: "TBS500x500")!, UIImage(named: "TokyoMX500x500")!, UIImage(named: "TVAsahi500x500")!, UIImage(named: "TVTokyo500x500")!]
        tvChannelsSelection.isPagingEnabled = false
        tvChannelsSelection.showsHorizontalScrollIndicator = false
        tvChannelsSelection.showsVerticalScrollIndicator = false
        loadTvChannelsSelection(tvChannelsLogo)
        tvChannelsSelection.layer.cornerRadius = 3
        
        // Swipes (up and down)
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
        downSwipe.direction = .down
        view.addGestureRecognizer(downSwipe)
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
        upSwipe.direction = .up
        view.addGestureRecognizer(upSwipe)
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
        

        
        appLoadedChannel()
    }
    
    
    func bringLoadingInForeground(){
        self.activityIndicator.layer.zPosition = 5
        self.loadingLabel.layer.zPosition = 5
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { // Change `2.0` to the desired number of seconds.
           self.activityIndicator.layer.zPosition = 0
           self.loadingLabel.layer.zPosition = 0
        }
    }
    
    //Chat
    var listOfChatInfo = [Chat]()
    func loadChat(){
        let lastWatched = defaults.string(forKey: "lastSelectedChannel") ?? "ntv"
        self.ref.child("chat/\(lastWatched)").queryOrdered(byChild: "timestamp").observe(.value, with: {
            (snapshot) in
            //
            self.listOfChatInfo.removeAll()
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot{
                    if let chatData = snap.value as? [String:AnyObject]{
                        let username = chatData["sender"] as? String
                        let content = chatData["content"] as? String
                        var timestamp:CLong?
                        if let timestampIn = chatData["timestamp"] as? CLong{
                            timestamp = timestampIn
                        }
                        self.listOfChatInfo.append(Chat(sender: username ?? "anon", content: content ?? "nothing", timestamp: "\(timestamp ?? 0000000000000)") )
                    }
                }
                self.chatContentTable.reloadData()
                let indexpath = IndexPath(row: self.listOfChatInfo.count-1, section: 0)
                self.chatContentTable.scrollToRow(at: indexpath, at: .bottom, animated: true)
            }
        })
    }

    
    
    // MARK: Comment Button Fade
    func runTimer() {
        // Create the timer to run a method (in this case... updateTimer) every 1 second.
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
        // Set the isTimerRunning bool to true
        isTimerRunning = true
    }

    @objc func updateTimer() {
        // Every 1 second that this method runs, 1 second will be chopped off the secondToFadeOut property. If that hits 0 (< 1), then run the fadeOutButton and invalidate the timer so it stops running.
        secondToFadeOut -= 1
        print(secondToFadeOut)
        if secondToFadeOut < 1 {
            fadeOutButton()
            timer.invalidate()
            isTimerRunning = false
        }
    }

    @objc func tap(_ gestureRecognizer: UITapGestureRecognizer) {
        // When the view is tapped (based on the gesture recognizer), reset the secondToFadeOut property, fade in (and enable) the button.
        //secondToFadeOut = 5
        fadeInButton()
        timer.invalidate()
        if isTimerRunning == false {
            secondToFadeOut = 3
            runTimer()
        }
    }

    func fadeOutButton() {
        // Fade out your button! I also disabled it here. But you can do whatever your little heart desires.
        UIView.animate(withDuration: 3) {
            self.CommentBtn.alpha = 0.25
            self.moreBtn.alpha = 0
        }
        self.CommentBtn.isEnabled = false
        self.moreBtn.isEnabled = false
    }
    func fadeInButton() {
        // Fade the button back in, and set it back to active (so it's tappable)
        UIView.animate(withDuration: 0.5) {
            self.CommentBtn.alpha = 1
            self.moreBtn.alpha = 1
        }
        self.CommentBtn.isEnabled = true
        self.moreBtn.isEnabled = true
    }


    @IBAction func CommentBtnPressed(_ sender: UIButton) {
        print("CommentButton Pressed")
    }
    
    
    
    
    
    
    // MARK: Swipe Gesture (up and down) handler
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            switch sender.direction {
            case .down:
                UIView.animate(withDuration: 0.25) {
                    self.tvChannelsSelection.frame.origin.y = 0
                    self.Player.frame.origin.y = 80
                }
                UIView.animate(withDuration: 0.25) {
                    self.chatView.frame.origin.x = 215
                    self.chatView.alpha = 0
                }
            case .up:
                UIView.animate(withDuration: 0.25) {
                    self.tvChannelsSelection.frame.origin.y = -80
                    self.Player.frame.origin.y = 0
                }
            case .right:
                UIView.animate(withDuration: 0.25) {
                    self.chatView.frame.origin.x = 215
                    self.chatView.alpha = 0
                }
            default:
                break
            }
        }
    }
    
    
    
    
    // MARK: TV Channels Selection
    func loadTvChannelsSelection(_ images: [UIImage]){
        for i in 0..<images.count {
            let imageView = UIImageView()
            imageView.image = images[i]
            imageView.frame = CGRect(x: 150 * CGFloat(i), y: 0, width: 130, height: 70)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
            imageView.layer.cornerRadius = 5
            imageView.layer.masksToBounds = true
            imageView.frame.origin.x += 10
            imageView.frame.origin.y += 5
            imageView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
            imageView.layer.shadowOpacity = 0.5
            imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
            imageView.layer.shadowRadius = 2
            
            imageView.isUserInteractionEnabled = true
            if i == 0{
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ntvSelected(sender:)))
                imageView.addGestureRecognizer(tapRecognizer)
            }
            if i == 1{
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(nhkSelected(sender:)))
                imageView.addGestureRecognizer(tapRecognizer)
            }
            if i == 2{
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(fujitvSelected(sender:)))
                imageView.addGestureRecognizer(tapRecognizer)
            }
            if i == 3{
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tbsSelected(sender:)))
                imageView.addGestureRecognizer(tapRecognizer)
            }
            if i == 4{
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tokyomxSelected(sender:)))
                imageView.addGestureRecognizer(tapRecognizer)
            }
            if i == 5{
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tvasahiSelected(sender:)))
                imageView.addGestureRecognizer(tapRecognizer)
            }
            if i == 6{
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tvtokyoSelected(sender:)))
                imageView.addGestureRecognizer(tapRecognizer)
            }
            
            
            tvChannelsSelection.contentSize.width = 175 * CGFloat(i)
            tvChannelsSelection.contentSize.height = 80
            tvChannelsSelection.addSubview(imageView)
        }
    }
    
    
    
    
    
    func appLoadedChannel(){
        // Initializing HTML Player
        let lastWatched = defaults.string(forKey: "lastSelectedChannel") ?? "ntv"
        if lastWatched == "ntv"{
            tvChannelsSelection.subviews[0].backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = tvChannelsSelection.subviews[0].frame.origin
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
        }else if lastWatched == "nhk"{
            tvChannelsSelection.subviews[1].backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = tvChannelsSelection.subviews[1].frame.origin
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
        }else if lastWatched == "fujitv"{
            tvChannelsSelection.subviews[2].backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = tvChannelsSelection.subviews[2].frame.origin
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
        }else if lastWatched == "tbs"{
            tvChannelsSelection.subviews[3].backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = tvChannelsSelection.subviews[3].frame.origin
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
        }else if lastWatched == "tokyomx"{
            tvChannelsSelection.subviews[4].backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = tvChannelsSelection.subviews[4].frame.origin
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
        }else if lastWatched == "tvasahi"{
            tvChannelsSelection.subviews[5].backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = tvChannelsSelection.subviews[5].frame.origin
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
        }else if lastWatched == "tvtokyo"{
            tvChannelsSelection.subviews[6].backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = tvChannelsSelection.subviews[6].frame.origin
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
        }
        
        let HTMLPlayer = """
        <iframe class="tvplayer" style="transform: translateX(-100px) scale(1.05)" align="auto" frameborder="0" width="155%" height="130%" scrolling="no" allow="autoplay">
        </iframe>
        <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
        <script>
           axios({
              method: 'get',
              url: 'https://jsonblob.com/api/jsonBlob/8d462070-78d2-11ea-8599-21f0f9a3ea71',
              responseType: 'json'
           })
           .then(function(response){
              document.getElementsByClassName('tvplayer')[0].src = response.data.\(lastWatched)
           })
        </script>
        """
        
        Player.loadHTMLString(HTMLPlayer, baseURL:nil)
        Player.layer.zPosition = 2
    }
    
    
    
    
    

    
    
    
    @objc func ntvSelected(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            defaults.set("ntv", forKey: "lastSelectedChannel")
            for frame in tvChannelsSelection.subviews{
                frame.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
            }
            sender.view?.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = (sender.view?.frame.origin)!
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            UIView.animate(withDuration: 0.5){
                self.tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
            }
            channelSelected(channel: "ntv")
        }
    }
    
    @objc func nhkSelected(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            defaults.set("nhk", forKey: "lastSelectedChannel")
            for frame in tvChannelsSelection.subviews{
                frame.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
            }
            sender.view?.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = (sender.view?.frame.origin)!
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            UIView.animate(withDuration: 0.5){
                self.tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
            }
            channelSelected(channel: "nhk")
        }
    }
    
    @objc func fujitvSelected(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            defaults.set("fujitv", forKey: "lastSelectedChannel")
            for frame in tvChannelsSelection.subviews{
                frame.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
            }
            sender.view?.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = (sender.view?.frame.origin)!
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            UIView.animate(withDuration: 0.5){
                self.tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
            }
            channelSelected(channel: "fujitv")
        }
    }
    
    @objc func tbsSelected(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            defaults.set("tbs", forKey: "lastSelectedChannel")
            for frame in tvChannelsSelection.subviews{
                frame.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
            }
            sender.view?.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = (sender.view?.frame.origin)!
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            UIView.animate(withDuration: 0.5){
                self.tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
            }
            channelSelected(channel: "tbs")
        }
    }
    
    @objc func tokyomxSelected(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            defaults.set("tokyomx", forKey: "lastSelectedChannel")
            for frame in tvChannelsSelection.subviews{
                frame.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
            }
            sender.view?.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = (sender.view?.frame.origin)!
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            UIView.animate(withDuration: 0.5){
                self.tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
            }
            channelSelected(channel: "tokyomx")
        }
    }
    
    @objc func tvasahiSelected(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            defaults.set("tvasahi", forKey: "lastSelectedChannel")
            for frame in tvChannelsSelection.subviews{
                frame.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
            }
            sender.view?.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = (sender.view?.frame.origin)!
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            UIView.animate(withDuration: 0.5){
                self.tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
            }
            channelSelected(channel: "tvasahi")
        }
    }
    
    @objc func tvtokyoSelected(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            defaults.set("tvtokyo", forKey: "lastSelectedChannel")
            for frame in tvChannelsSelection.subviews{
                frame.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.2)
            }
            sender.view?.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
            let senderOrigin = (sender.view?.frame.origin)!
            let senderOriginX = Int(senderOrigin.x)
            let deviceWidth = Int(UIScreen.main.bounds.size.width)
            UIView.animate(withDuration: 0.5){
                self.tvChannelsSelection.contentOffset = CGPoint(x: senderOriginX - (deviceWidth/2) + 65, y: 0)
            }
            channelSelected(channel: "tvtokyo")
        }
    }
    
    func channelSelected(channel: String){
            loadChat()
            bringLoadingInForeground()
        
            UIView.animate(withDuration: 0.25) {
                self.tvChannelsSelection.frame.origin.y = -80
                self.Player.frame.origin.y = 0
            }

            Player.layer.zPosition = 2
            let HTMLPlayer = """
            <style>
            *::-webkit-media-controls{
                display: none !important;
            }
            </style>
            <iframe class="tvplayer" style="transform: translateX(-100px) scale(1.05)" align="auto" frameborder="0" width="155%" height="130%" scrolling="no" allow="autoplay">
            </iframe>
            <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
            <script>
               axios({
                  method: 'get',
                  url: 'https://jsonblob.com/api/jsonBlob/8d462070-78d2-11ea-8599-21f0f9a3ea71',
                  responseType: 'json'
               })
               .then(function(response){
                  document.getElementsByClassName('tvplayer')[0].src = response.data.\(channel)
               })
            </script>
            
            """
                    
            Player.loadHTMLString(HTMLPlayer, baseURL:nil)
        }
    

    
    
    
    // MARK: IBActions
    
    @IBAction func sendChatMessage(_ sender: Any) {
        if chatMessageContent.text != ""{
            let lastSelected = defaults.string(forKey: "lastSelectedChannel") ?? "ntv"
            let user = defaults.string(forKey: "username") ?? "anon"
            let message = ["content": chatMessageContent.text ?? "none", "sender": user, "timestamp": ServerValue.timestamp()] as [String : Any]; self.ref.child("chat").child(lastSelected).childByAutoId().setValue(message)
            chatMessageContent.text = ""
        }
        chatMessageContent.resignFirstResponder()
    }
    
    @IBAction func returnKeySendChatMessage(_ sender: Any) {
        if chatMessageContent.text != ""{
            let lastSelected = defaults.string(forKey: "lastSelectedChannel") ?? "ntv"
            let user = defaults.string(forKey: "username") ?? "anon"
            let message = ["content": chatMessageContent.text ?? "none", "sender": user, "timestamp": ServerValue.timestamp()] as [String : Any]; self.ref.child("chat").child(lastSelected).childByAutoId().setValue(message)
            chatMessageContent.text = ""
        }
        chatMessageContent.resignFirstResponder()
    }
    
    @IBAction func activateChat(_ sender: Any) {
        UIView.animate(withDuration: 0.25) {
            self.chatView.frame.origin.x = 0
            self.chatView.alpha = 1
        }
    }
    
    @IBAction func moreBtnViewActivation(_ sender: Any) {
        
        performSegue(withIdentifier: "moreView", sender: nil)
        
    }
    
    
    @objc func adjustViewToKeyboard(notification: Notification){
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            if self.chatView.frame.origin.y != 0{
                self.chatView.frame.origin.y = 0
            }
        } else if notification.name == UIResponder.keyboardWillChangeFrameNotification{
            if self.chatView.frame.origin.y == 0{
                self.chatView.frame.origin.y -= keyboardViewEndFrame.height
            }
        }
    }
    
    
}
