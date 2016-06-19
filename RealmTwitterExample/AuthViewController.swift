//
//  AuthViewController.swift
//  RealmTwitterExample
//
//  Created by Robert Otani on 5/4/16.
//  Copyright © 2016 otanistudio.com. All rights reserved.
//

import Accounts
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
        twAccountType = self.accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
    }
    
    @IBAction func didTapChooseTwitter() {
        accountStore.requestAccessToAccountsWithType(self.twAccountType, options: nil) { isGranted, error in
            guard isGranted else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.displayAlertWithMessage("Access to Twitter account denied. Check iOS Settings.")
                }
                
                return
            }
            
            let twAccounts = self.accountStore.accountsWithAccountType(self.twAccountType) as? [ACAccount]
            if twAccounts?.count > 0 {
                dispatch_async(dispatch_get_main_queue()) {
                    self.chooseAccount(twAccounts!)
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.displayAlertWithMessage("Sorry… couldn’t find Twitter accounts in iOS Settings")
                }
            }
        }
    }
    
    func chooseAccount(accounts: [ACAccount]) {
        if accounts.count == 1 {
            self.performReverseAuth(accounts.first!)
            return
        }
        
        let chooser = UIAlertController(title: "Twitter", message: "Choose Username", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        for account in accounts {
            let choice = UIAlertAction(title: account.username, style: UIAlertActionStyle.Default, handler: { (actionChoice) -> Void in
                self.performReverseAuth(account)
            })
            chooser.addAction(choice)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        chooser.addAction(cancel)
        
        self.presentViewController(chooser, animated: true, completion: nil)
    }
    
    func performReverseAuth(twAccount: ACAccount) {
        debugPrint(twAccount.username)
        activityIndicator.startAnimating()
        self.account = twAccount
        guard let storyboard = self.navigationController?.storyboard else {
            return
        }
        let tweetVC = storyboard.instantiateViewControllerWithIdentifier(String(TweetViewController)) as! TweetViewController
        tweetVC.account = twAccount
        self.navigationController?.showViewController(tweetVC, sender: self)
//        self.navigationController?.performSegueWithIdentifier("ShowTweetsSegue", sender: self)
    }
    
    func displayAlertWithMessage(message: String) {
        let alert = UIAlertController(title: "Hey", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
    }

    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        debugPrint("prepare for segue")
        if segue.identifier == "ShowTweetsSegue" {
            let tweetVC = segue.destinationViewController as! TweetViewController
            tweetVC.account = self.account!
        }
    }
 

}
