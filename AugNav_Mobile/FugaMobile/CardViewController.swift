import UIKit
import SceneKit
import Firebase

class CardViewController: UIViewController {

    @IBOutlet weak var handleArea: UIView!
    
    @IBOutlet weak var mapScene: SCNView!
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    @IBOutlet weak var feetText: UILabel!
    
    @IBOutlet weak var arrivalLabel: UILabel!
    
    @IBOutlet weak var arrivalText: UILabel!
    
    @IBOutlet weak var endBtnElement: UIButton!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var goMode:Bool = false
    
    func hideNavElements() {
        distanceLabel.isHidden = true
        feetText.isHidden = true
        arrivalLabel.isHidden = true
        arrivalText.isHidden = true
        //endBtnElement.isHidden = true
        endBtnElement.backgroundColor = UIColor.systemGreen
        endBtnElement.setTitle("Go", for: .normal)
        searchBar.isHidden = false
    }
    
    func showNavElements() {
        distanceLabel.isHidden = false
        feetText.isHidden = false
        arrivalLabel.isHidden = false
        arrivalText.isHidden = false
        endBtnElement.backgroundColor = UIColor.systemRed
        endBtnElement.setTitle("End", for: .normal)
        searchBar.isHidden = true
    }
    
    @IBAction func closeBtnClicked(_ sender: Any) {
        if(!goMode) {
            showNavElements()
            goMode = true
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    var scene: SCNScene!
    var mapSelected = "map 1"
    
    var userLocation: SCNNode!
    
    var scale = 2
    var scaleFloat = Float(2)
    var scaleDouble = Double(2)
    
    override func viewDidLoad() {
        addDoneButtonOnKeyboard()
        searchBar.endEditing(true)
        searchBar.backgroundImage = UIImage()
        hideNavElements()
    }
    
    func addDoneButtonOnKeyboard(){
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        searchBar.inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction(){
        searchBar.resignFirstResponder()
    }
    
    func updateDistanceInfo(totalDistance:Float) {
        let feetDistance = totalDistance*3.28084
        distanceLabel.text = String(format: "%.2f", feetDistance)
        
        let totalSeconds = Double(totalDistance/1.4)
        
        let startDate = Date()
        
        let date = startDate.addingTimeInterval(totalSeconds)
        
        let calendar = Calendar.current
        let hour = Float(calendar.component(.hour, from: date))
        let minutes = Float(calendar.component(.minute, from: date))
        let seconds = Float(calendar.component(.second, from: date))
        
        arrivalLabel.text = String(format:"%02.0f:%02.0f:%02.0f", hour, minutes, seconds)
    }
    
    func setupScene(offsetX:Float, offsetY:Float, offsetZ:Float, totalDistance:Float) {
        let sphereGeometry = SCNSphere(radius: 0.5)
        sphereGeometry.firstMaterial?.diffuse.contents = UIColor.blue
        userLocation = SCNNode(geometry: sphereGeometry)
        userLocation.position = SCNVector3Make(-1*offsetX*scaleFloat, -1*offsetY*scaleFloat, -1*offsetZ*scaleFloat)
        
        mapScene.allowsCameraControl = true
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        mapScene.scene = scene
        
        scene.rootNode.addChildNode(userLocation)

        let db = Firestore.firestore()
        let curUser = Firebase.Auth.auth().currentUser

        if(self.mapSelected == nil || self.mapSelected == "" ) {
            let alert = UIAlertController(title: "Map Not Found", message: "The map you entered does not exist. Please make sure names match exactly.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                self.dismiss(animated: true, completion: nil)
            }))

            self.present(alert, animated: true)
        }
        else {
            let docRef = db.collection("users").document((curUser?.email)!).collection("maps").document(self.mapSelected)

            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let mapData = (document.data()! as? [String:Any])!
                    let vertices = mapData["data"] as? [String:Any]

                    for vertex in vertices! {
                        let vertexData = vertex.value as! [String:Any]

                        let x = vertexData["x"] as! Float * self.scaleFloat
                        let y = vertexData["y"] as! Float * self.scaleFloat
                        let z = vertexData["z"] as! Float * self.scaleFloat
                        let radiusFloat = vertexData["radius"] as! Float * self.scaleFloat
                        let radius = CGFloat(((vertexData["radius"] as! Double)*self.scaleDouble))// * (CGFloat(scale as! Double))
                        let next = vertexData["next"] as! [String]
                        let name = vertexData["name"] as! String

                        let sphereGeometry = SCNSphere(radius: radius)
                        sphereGeometry.firstMaterial?.diffuse.contents = UIColor.red
                        let sphereNode = SCNNode(geometry: sphereGeometry)
                        sphereNode.position = SCNVector3Make(x, y, z)

                        self.scene.rootNode.addChildNode(sphereNode)

                        let text = SCNText(string: String(name), extrusionDepth: 0.01)

                        text.font = UIFont.systemFont(ofSize: radius*5)
                        text.flatness = 0.01
                        text.firstMaterial?.diffuse.contents = UIColor.black

                        let textNode = SCNNode(geometry: text)
                        textNode.position = SCNVector3Make(x, y-radiusFloat*6, z)

                        self.scene.rootNode.addChildNode(textNode)

                        for nextVertex in next {
                            let nextVertexData = vertices![nextVertex] as? [String:Any]
                            let nextX = nextVertexData!["x"] as! Float * self.scaleFloat
                            let nextY = nextVertexData!["y"] as! Float * self.scaleFloat
                            let nextZ = nextVertexData!["z"] as! Float * self.scaleFloat

                            let lineNode = SCNGeometry.lineNode(from: simd_float3(x, y, z), to: simd_float3(nextX, nextY, nextZ))
                            self.scene.rootNode.addChildNode(lineNode)
                        }
                    }

                } else {
                    print("Document does not exist")

                    let alert = UIAlertController(title: "Map Not Found", message: "The map you entered does not exist. Please make sure names match exactly.", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                        self.dismiss(animated: true, completion: nil)
                    }))

                    self.present(alert, animated: true)
                }
            }

            mapScene.scene = scene     // set the scene
        }
    }
    
    override var shouldAutorotate: Bool {
        return false
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use
    }
}
