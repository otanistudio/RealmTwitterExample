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
    
    var inboundTimer: Timer?
    var outboundTimer: Timer?
    
    let timelineURL = URL(string: "https://api.twitter.com/1.1/statuses/user_timeline.json")!  // rate lmited to 180 / 15min
    let inboundInterval: TimeInterval = 8.0
//    let timelineURL = NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")! //   rate limited to 15 / 15min
//    let inboundInterval = 60.0
    let statusUpdateURL = URL(string: "https://api.twitter.com/1.1/statuses/update.json")!
    let outboundInterval: TimeInterval = 60.0
    
    let sendQueue = DispatchQueue(label: "send_queue", attributes: [])
    
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
            case .initial:
                let indexSet = IndexSet(integer: Section.Outbound)
                self.tableView.reloadSections(indexSet, with: .fade)
                break
            case .update(_, let deletions, let insertions, let modifications):
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: Section.Outbound) }, with: .fade)
                self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: Section.Outbound) }, with: .fade)
                self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: Section.Outbound) }, with: .fade)
                self.tableView.endUpdates()
                break
            case .error(let error):
                debugPrint("outbound tweet notification error", error)
                break
            }
        }
        
        inboundNotificationToken = tweets.addNotificationBlock{ (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                let indexSet = IndexSet(integer: Section.Timeline)
                self.tableView.reloadSections(indexSet, with: .fade)
                break
            case .update(_, let deletions, let insertions, let modifications):
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: Section.Timeline) }, with: .fade)
                self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: Section.Timeline) }, with: .fade)
                self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: Section.Timeline) }, with: .fade)
                self.tableView.endUpdates()
                break
            case .error(let error):
                debugPrint("inbound tweet notification error", error)
                break
            }
        }
        
        inboundTimer = Timer.scheduledTimer(timeInterval: inboundInterval, target: self, selector: #selector(fetchTimeline), userInfo: nil, repeats: true)
        outboundTimer = Timer.scheduledTimer(timeInterval: outboundInterval, target: self, selector: #selector(send), userInfo: nil, repeats: true)
        
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
    
    func postTweet(_ rlm: Realm, outbound: OutboundTweet) {
        let params = [
            "status" : "\(outbound.message), \(outbound.date)"
        ]
        let slReq = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .post, url: statusUpdateURL, parameters: params)
        slReq.account = account
        slReq.perform { data, response, error in
            guard error == nil else {
                return
            }
            let statusCode = response.statusCode
            if statusCode >= 400 {
                debugPrint("Twitter Error (if it's 429, then it's rate-limiting):", response)
                debugPrint(NSString(data: data, encoding: String.Encoding.utf8))
                return
            }
            DispatchQueue.main.async {
                try! rlm.write {
                    rlm.delete(outbound)
                }
            }
        }
    }
    
    func fetchTimeline() {
        let slReq = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .get, url: timelineURL, parameters: nil)
        slReq.account = account
        
        slReq.perform { data, response, error in
            guard error == nil else {
                return
            }
            let statusCode = response.statusCode
            if statusCode >= 400 {
                debugPrint("Twitter Error (if it's 429, then it's rate-limiting):", response)
                debugPrint(NSString(data: data, encoding: String.Encoding.utf8))
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section.Outbound {
            return outboundTweets.count
        }
        if section == Section.Timeline {
            return tweets.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == Section.Timeline {
            let cell = tableView.dequeueReusableCell(withIdentifier: TweetCell.reuseID, for: indexPath)
            cell.textLabel?.text = tweets[(indexPath as NSIndexPath).row].message
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: TweetCell.reuseID, for: indexPath)
        let outbound = outboundTweets[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = "\(outbound.message), \(outbound.date)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.size.width - 30.0, height: 44.0))
        label.backgroundColor = UIColor.darkGray()
        label.textColor = UIColor.white()
        label.font = UIFont.systemFont(ofSize: 12.0)
        if section == Section.Timeline {
            label.text = " Timeline".uppercased()
        } else {
            label.text = " Outbound".uppercased()
        }
        
        return label
    }

}
