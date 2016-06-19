//
//  RealmTweet.swift
//  RealmTwitterExample
//
//  Created by Robert Otani on 5/4/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import Foundation
import Freddy
import RealmSwift

final class Tweet: RealmSwift.Object {
    dynamic var id = 0
    dynamic var message: String!
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(json: JSON) throws {
        self.init(
            value: [
                "id" : try json.int("id"),
                "message" : try json.string("text")
            ])
    }
}
