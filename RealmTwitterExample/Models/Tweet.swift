//
//  RealmTweet.swift
//  RealmTwitterExample
//
//  Created by Robert Otani on 5/4/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import Foundation
import RealmSwift

final class Tweet: RealmSwift.Object {
    dynamic var id = 0
    dynamic var message: String!
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(id: Int, message: String) throws {
        self.init()
        self.id = id
        self.message = message
    }
}
