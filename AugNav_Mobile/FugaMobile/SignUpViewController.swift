import UIKit
import Firebase

class SignUpViewController: UIViewController {

    @IBOutlet weak var BackLabel: UILabel!
    
    @IBOutlet weak var EmailField: UITextFieldWithDoneButton!
    @IBOutlet weak var PasswordField: UITextFieldWithDoneButton!
    @IBOutlet weak var ConfirmPasswordField: UITextFieldWithDoneButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        if #available(iOS 13.0, *) {
            // Always adopt a light interface style.
            overrideUserInterfaceStyle = .light
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(SignUpViewController.tapFunction))
        
        BackLabel.textColor = UIColor.white
        BackLabel.isUserInteractionEnabled = true
        BackLabel.addGestureRecognizer(tap)
        
        PasswordField.isSecureTextEntry = true
        ConfirmPasswordField.isSecureTextEntry = true
        
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
    
    @objc
    func tapFunction(sender:UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        if (notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification) {
            view.frame.origin.y = -keyboardRect.height*0.4
        }
        else {
            view.frame.origin.y = 0
        }
    }
    
    
    @IBAction func SignUpButtonClick(_ sender: Any) {
        let email = EmailField.text
        let password = PasswordField.text
        let confirmPassword = ConfirmPasswordField.text
        
        if(password == confirmPassword) {
            Auth.auth().createUser(withEmail: email!, password: password!) {
                authResult, error in
                
                if (error != nil) {
                  NSLog(error!.localizedDescription)
                  
                  let alert = UIAlertController(title: "Login Error", message: error!.localizedDescription, preferredStyle: .alert)

                  alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

                  self.present(alert, animated: true)
                }
                else {
                    let curUser = Firebase.Auth.auth().currentUser
                    
                    NSLog(String((curUser?.email)!))
                    self.performSegue(withIdentifier: "signUpToHome", sender: nil)
                }
            }
        }
        else {
            let alert = UIAlertController(title: "Sign Up Error", message: "Passwords have to match.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

            self.present(alert, animated: true)
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
