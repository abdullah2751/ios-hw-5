import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let dataController = DataController(modelName: "Virtual_Tourist")!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        dataController.autoSave(15)
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // save when the application is about to move from active to inactive state.
        do {
            try dataController.saveContext()
        } catch {
            print("There was an error saving the app data in WillResignActive.")
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // save when app moves to the background
        do {
            try dataController.saveContext()
        } catch {
            print("There was an error saving the app data in WillResignActive.")
        }
    }

}

