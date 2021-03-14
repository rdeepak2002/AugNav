import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var EmailTextField: UITextFieldWithDoneButton!
    
    @IBOutlet weak var PasswordTextField: UITextFieldWithDoneButton!
    
    @IBOutlet weak var LoginButton: UIButton!
    
    @IBOutlet weak var SignUpLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let handle = Firebase.Auth.auth().addStateDidChangeListener { (auth, user) in
            // [START_EXCLUDE]
            if Auth.auth().currentUser != nil {
              NSLog("logged in")
              self.performSegue(withIdentifier: "fromLoginToHome", sender: nil)
            }
            // [END_EXCLUDE]
        }
        
        // Do any additional setup after loading the view.

        if #available(iOS 13.0, *) {
            // Always adopt a light interface style.
            overrideUserInterfaceStyle = .light
        }
        
        let boldAttribute = [
           NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 18.0)!
        ]
        let regularAttribute = [
           NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Light", size: 18.0)!
        ]
        
        let regularText = NSAttributedString(string: "Don't have an account? ", attributes: regularAttribute)
       
        let boldText = NSAttributedString(string: "Sign Up Now", attributes: boldAttribute)

        let newString = NSMutableAttributedString()
        newString.append(regularText)
        newString.append(boldText)
        
        SignUpLabel.textColor = UIColor.white
        SignUpLabel.attributedText = newString
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.tapFunction))
        SignUpLabel.isUserInteractionEnabled = true
        SignUpLabel.addGestureRecognizer(tap)
        
        PasswordTextField.isSecureTextEntry = true
        
        // Listen for keyboard events
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        // Stop listening for keyboard events
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      // [START remove_auth_listener]
        //Firebase.Auth.auth().removeStateDidChangeListener(handle!)
      // [END remove_auth_listener]
    }
    
    @IBAction func LoginClick(_ sender: Any) {
        Auth.auth().signIn(withEmail: EmailTextField.text!, password: PasswordTextField.text!) {
            (user, error) in
            if (error != nil) {
                NSLog(error!.localizedDescription)
                
                let alert = UIAlertController(title: "Login Error", message: error!.localizedDescription, preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

                self.present(alert, animated: true)
            }
            else {
                let curUser = Firebase.Auth.auth().currentUser
        
                NSLog(String((curUser?.email)!))
                self.performSegue(withIdentifier: "fromLoginToHome", sender: nil)
            }
        }
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        if (notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification) {
            view.frame.origin.y = -keyboardRect.height*0.7
        }
        else {
            view.frame.origin.y = 0
        }
    }
    
    @objc
    func tapFunction(sender:UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "loginToSignUp", sender: nil)
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
