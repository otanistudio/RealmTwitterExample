
# RealmTwitterExample
This example code demonstrates posts and feed refreshing happening simultaneously, using [Realm](https://realm.io) as the persistence layer. Used as a live demo of how the basics work in context of async networking, and delayed spooler-type uploads, with reads and writes in different threads to update the display of Tweets in a UITableViewController.

Because this is sample code, posts and refreshing happens via naive polling in the app's main view controller. However, data updates happen by responding to Realm notifications, and then updating the UI in the main thread (Realm notifications in the view controller are set-up here to happen the main run loop by default.)

<img src="https://cloud.githubusercontent.com/assets/517428/16182411/b92b066a-365a-11e6-9e43-fc4b6b204f3c.gif" width="420" height="345" />

## Setup
After cloning, make sure submodules are updated. If you're uncomfortable with submodules, running `scripts/setup.sh` should help you get going.

## Test Account Recommended
This example will post timestamp Tweets to whatever Twitter account you choose via iOS Settings. Unless you want these weird-looking timestamp tweets in your personal Twitter timeline, you should setup a test account for this information.

_Reminder:_ The [Twitter API](https://dev.twitter.com/rest/reference/get/statuses/user_timeline) is rate-limited, so be wary when you update the default time interval, which are set to conservative defaults.
