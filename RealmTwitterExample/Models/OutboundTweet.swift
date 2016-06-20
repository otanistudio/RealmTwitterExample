//
//  RealmOutboundTweet.swift
//  RealmTwitterExample
//
//  Created by Robert Otani on 5/4/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import Foundation
import RealmSwift

final class OutboundTweet: RealmSwift.Object {
    dynamic var key: String!
    dynamic var message: String!
    dynamic var date: Date!
    
    override static func primaryKey() -> String? {
        return "key"
    }
    
    convenience init(message: String) throws {
        self.init()
        let _date = Date()
        self.date = _date
        self.key = "\(message) \(_date)"
        self.message = message
    }
    
}
