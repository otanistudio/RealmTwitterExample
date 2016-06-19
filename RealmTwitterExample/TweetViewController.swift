//
//  TweetViewController.swift
//  RealmTwitterExample
//
//  Created by Robert Otani on 5/4/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import Accounts
import Freddy
import RealmSwift
import Social
import UIKit

final class TweetCell: UITableViewCell {
    static let reuseID = "TweetCellID"
}

class TweetViewController: UITableViewController {
    struct Section {
        static let Outbound = 0
        static let Timeline = 1
    }
    
    var tweets: Results<Tweet>!
    var outboundTweets: Results<OutboundTweet>!
    
    var inboundTimer: NSTimer?
    var outboundTimer: NSTimer?
    
    let timelineURL = NSURL(string: "https://api.twitter.com/1.1/statuses/user_timeline.json")!  // rate lmited to 180 / 15min
    let inboundInterval: NSTimeInterval = 8.0
//    let timelineURL = NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")! //   rate limited to 15 / 15min
//    let inboundInterval = 60.0
    let statusUpdateURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json")!
    let outboundInterval: NSTimeInterval = 60.0
    
    let sendQueue = dispatch_queue_create("send_queue", nil)
    
    var account: ACAccount!
    let realm = try! Realm()
    
    var inboundNotificationToken: NotificationToken?
    var outboundNotificationToken: NotificationToken?
    
    deinit {
        inboundTimer?.invalidate()
        outboundTimer?.invalidate()
        inboundNotificationToken?.stop()
        outboundNotificationToken?.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // So we'll know which file to open in the OS X Realm Browser
        debugPrint("Realm file location:", Realm.Configuration.defaultConfiguration.fileURL)
        
        tweets = realm.objects(Tweet).sorted("id", ascending: false)
        outboundTweets = realm.objects(OutboundTweet).sorted("date")
            
        self.navigationItem.rightBarButtonItem?.target = self
        self.navigationItem.rightBarButtonItem?.action = #selector(addTweet)
        
        outboundNotificationToken = outboundTweets.addNotificationBlock{ (changes: RealmCollectionChange) in
            switch changes {
            case .Initial:
                let indexSet = NSIndexSet(index: Section.Outbound)
                self.tableView.reloadSections(indexSet, withRowAnimation: .Fade)
                break
            case .Update(_, let deletions, let insertions, let modifications):
                self.tableView.beginUpdates()
                self.tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: Section.Outbound) }, withRowAnimation: .Fade)
                self.tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: Section.Outbound) }, withRowAnimation: .Fade)
                self.tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: Section.Outbound) }, withRowAnimation: .Fade)
                self.tableView.endUpdates()
                break
            case .Error(let error):
                debugPrint("outbound tweet notification error", error)
                break
            }
        }
        
        inboundNotificationToken = tweets.addNotificationBlock{ (changes: RealmCollectionChange) in
            switch changes {
            case .Initial:
                let indexSet = NSIndexSet(index: Section.Timeline)
                self.tableView.reloadSections(indexSet, withRowAnimation: .Fade)
                break
            case .Update(_, let deletions, let insertions, let modifications):
                self.tableView.beginUpdates()
                self.tableView.insertRowsAtIndexPaths(insertions.map { NSIndexPath(forRow: $0, inSection: Section.Timeline) }, withRowAnimation: .Fade)
                self.tableView.deleteRowsAtIndexPaths(deletions.map { NSIndexPath(forRow: $0, inSection: Section.Timeline) }, withRowAnimation: .Fade)
                self.tableView.reloadRowsAtIndexPaths(modifications.map { NSIndexPath(forRow: $0, inSection: Section.Timeline) }, withRowAnimation: .Fade)
                self.tableView.endUpdates()
                break
            case .Error(let error):
                debugPrint("inbound tweet notification error", error)
                break
            }
        }
        
        inboundTimer = NSTimer.scheduledTimerWithTimeInterval(inboundInterval, target: self, selector: #selector(fetchTimeline), userInfo: nil, repeats: true)
        outboundTimer = NSTimer.scheduledTimerWithTimeInterval(outboundInterval, target: self, selector: #selector(send), userInfo: nil, repeats: true)
        
        fetchTimeline()
    }
    
    func addTweet() {
        let rlm = try! Realm()
        try! rlm.write {
            let outbound = try! OutboundTweet(message: "added by a button")
            rlm.add(outbound, update: true)
        }
    }
    
    func send() {
        let rlm = try! Realm()
        guard let outbound = rlm.objects(OutboundTweet).sorted("date").first else {
            return
        }
        self.postTweet(rlm, outbound: outbound)
    }
    
    func postTweet(rlm: Realm, outbound: OutboundTweet) {
        let params = [
            "status" : "\(outbound.message), \(outbound.date)"
        ]
        let slReq = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, URL: statusUpdateURL, parameters: params)
        slReq.account = account
        slReq.performRequestWithHandler { data, response, error in
            guard error == nil else {
                return
            }
            let statusCode = response.statusCode
            if statusCode >= 400 {
                debugPrint("Twitter Error (if it's 429, then it's rate-limiting):", response)
                debugPrint(NSString(data: data, encoding: NSUTF8StringEncoding))
                return
            }
            dispatch_async(dispatch_get_main_queue()) {
                try! rlm.write {
                    rlm.delete(outbound)
                }
            }
        }
    }
    
    func fetchTimeline() {
        let slReq = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: timelineURL, parameters: nil)
        slReq.account = account
        
        slReq.performRequestWithHandler { data, response, error in
            guard error == nil else {
                return
            }
            let statusCode = response.statusCode
            if statusCode >= 400 {
                debugPrint("Twitter Error (if it's 429, then it's rate-limiting):", response)
                debugPrint(NSString(data: data, encoding: NSUTF8StringEncoding))
                return
            }
            
            
            let responseJSON = try! JSON(data: data)
            let rlm = try! Realm()
            try! rlm.write {
                let rlmTweets = try! responseJSON.array().map { tweetJSON -> Tweet in
                    return try! Tweet(json: tweetJSON)
                }
                rlm.add(rlmTweets, update: true)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section.Outbound {
            return outboundTweets.count
        }
        if section == Section.Timeline {
            return tweets.count
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == Section.Timeline {
            let cell = tableView.dequeueReusableCellWithIdentifier(TweetCell.reuseID, forIndexPath: indexPath)
            cell.textLabel?.text = tweets[indexPath.row].message
            return cell
        }
        let cell = tableView.dequeueReusableCellWithIdentifier(TweetCell.reuseID, forIndexPath: indexPath)
        let outbound = outboundTweets[indexPath.row]
        cell.textLabel?.text = "\(outbound.message), \(outbound.date)"
        return cell
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.size.width - 30.0, height: 44.0))
        label.backgroundColor = UIColor.darkGrayColor()
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.systemFontOfSize(12.0)
        if section == Section.Timeline {
            label.text = " Timeline".uppercaseString
        } else {
            label.text = " Outbound".uppercaseString
        }
        
        return label
    }

}
