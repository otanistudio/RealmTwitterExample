//
//  RealmOutboundTweet.swift
//  RealmTwitterExample
//
//  Created by Robert Otani on 5/4/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import Foundation
import Freddy
import RealmSwift

final class OutboundTweet: Object {
    dynamic var key: String!
    dynamic var message: String!
    dynamic var date: NSDate!
    
    override static func primaryKey() -> String? {
        return "key"
    }
    
    convenience init(message: String) throws {
        let _date = NSDate()
        self.init(
            value: [
                "key" : "\(message) \(_date)",
                "message": message,
                "date": _date
            ]
        )
    }
    
}