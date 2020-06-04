//
//  ChatCell.swift
//  japan_terebi-iOS
//
//  Created by Anime no Sekai on 20/04/2020.
//  Copyright © 2020 Anime no Sekai. All rights reserved.
//

import UIKit

class ChatCell: UITableViewCell {

    @IBOutlet weak var chatContent: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        adjustUITextViewHeight(arg: chatContent)
        //var frame = self.chatContent.frame
        //frame.size.height = self.chatContent.contentSize.height
        //self.chatContent.frame = frame

    }

    func setChat(chat:Chat){
        chatContent.text = (chat.sender ?? "anon") + ": " + (chat.content ?? "nothing")
    }
    
    
    func adjustUITextViewHeight(arg : UITextView){
        arg.translatesAutoresizingMaskIntoConstraints = true
        arg.sizeToFit()
        arg.isScrollEnabled = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
