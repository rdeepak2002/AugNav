import UIKit
import Firebase

class InitViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let handle = Firebase.Auth.auth().addStateDidChangeListener { (auth, user) in
            // [START_EXCLUDE]
            if Auth.auth().currentUser != nil {
                NSLog("logged in")
                self.performSegue(withIdentifier: "toHomeScreen", sender: nil)
            }
            else {
                NSLog("not logged in")
                self.performSegue(withIdentifier: "toLoginScreen", sender: nil)
            }
            // [END_EXCLUDE]
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
