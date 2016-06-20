//
//  AuthViewController.swift
//  RealmTwitterExample
//
//  Created by Robert Otani on 5/4/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import Accounts
import RealmSwift
import Social
import UIKit

class AuthViewController: UIViewController {
    @IBOutlet weak var authButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var accountStore: ACAccountStore!
    var twAccountType: ACAccountType!
    var account: ACAccount?

    override func viewDidLoad() {
        super.viewDidLoad()
        accountStore = ACAccountStore()
        twAccountType = self.accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
    }
    
    @IBAction func didTapChooseTwitter() {
        accountStore.requestAccessToAccounts(with: self.twAccountType, options: nil) { isGranted, error in
            guard isGranted else {
                DispatchQueue.main.async {
                    self.displayAlertWithMessage("Access to Twitter account denied. Check iOS Settings.")
                }
                
                return
            }
            
            let twAccounts = self.accountStore.accounts(with: self.twAccountType) as? [ACAccount]
            if twAccounts?.count > 0 {
                DispatchQueue.main.async {
                    self.chooseAccount(twAccounts!)
                }
            } else {
                DispatchQueue.main.async {
                    self.displayAlertWithMessage("Sorry… couldn’t find Twitter accounts in iOS Settings")
                }
            }
        }
    }
    
    func chooseAccount(_ accounts: [ACAccount]) {
        if accounts.count == 1 {
            self.performReverseAuth(accounts.first!)
            return
        }
        
        let chooser = UIAlertController(title: "Twitter", message: "Choose Username", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        for account in accounts {
            let choice = UIAlertAction(title: account.username, style: UIAlertActionStyle.default, handler: { (actionChoice) -> Void in
                self.performReverseAuth(account)
            })
            chooser.addAction(choice)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        chooser.addAction(cancel)
        
        self.present(chooser, animated: true, completion: nil)
    }
    
    func performReverseAuth(_ twAccount: ACAccount) {
        debugPrint("using twitter username:", twAccount.username)
        activityIndicator.startAnimating()
        
        if let account = self.account where account.username == twAccount.username {
            debugPrint("same account")
        } else {
            let realm = try! Realm()
            try! realm.write {
                realm.deleteAllObjects()
            }
        }
        
        self.account = twAccount
        guard let storyboard = self.navigationController?.storyboard else {
            return
        }
        let tweetVC = storyboard.instantiateViewController(withIdentifier: String(TweetViewController)) as! TweetViewController
        tweetVC.account = twAccount
        self.activityIndicator.stopAnimating()
        self.navigationController?.show(tweetVC, sender: self)
    }
    
    func displayAlertWithMessage(_ message: String) {
        let alert = UIAlertController(title: "Hey", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }

}
