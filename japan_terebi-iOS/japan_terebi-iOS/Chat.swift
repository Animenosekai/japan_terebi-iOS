//
//  Chat.swift
//  japan_terebi-iOS
//
//  Created by Anime no Sekai on 20/04/2020.
//  Copyright © 2020 Anime no Sekai. All rights reserved.
//

import UIKit

class Chat: NSObject {
    var sender: String?
    var content: String?
    var timestamp: String?
    
    init(sender:String, content:String, timestamp:String) {
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
    }
}
 
