import UIKit
import SceneKit
import Firebase

class MapViewController: UIViewController {
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var closeBtn: UIImageView!
    
    var scene: SCNScene!
    var mapSelected = "map 1"
    
    override func viewDidLoad() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(MapViewController.tapFunction))
        
        closeBtn.isUserInteractionEnabled = true
        closeBtn.addGestureRecognizer(tap)
        
        setupScene()
    }
    
    func setupScene() {
        sceneView.allowsCameraControl = true
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        
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
                    let exit = document.data()!["endVertex"] as? String
                    
                    for vertex in vertices! {
                        let vertexData = vertex.value as! [String:Any]
                        
                        let scale = 2
                        let scaleFloat = Float(scale)
                        let scaleDouble = Double(scale)
                        
                        let x = vertexData["x"] as! Float * scaleFloat
                        let y = vertexData["y"] as! Float * scaleFloat
                        let z = vertexData["z"] as! Float * scaleFloat
                        let radiusFloat = vertexData["radius"] as! Float * scaleFloat
                        let radius = CGFloat(((vertexData["radius"] as! Double)*scaleDouble))// * (CGFloat(scale as! Double))
                        let next = vertexData["next"] as! [String]
                        var name = vertexData["name"] as! String
                        
                        let sphereGeometry = SCNSphere(radius: radius)
                        if(name==exit) {
                            sphereGeometry.firstMaterial?.diffuse.contents = UIColor.purple
                            name = name + " (exit)"
                        }
                        else {
                            sphereGeometry.firstMaterial?.diffuse.contents = UIColor.red
                        }
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
                            let nextX = nextVertexData!["x"] as! Float * scaleFloat
                            let nextY = nextVertexData!["y"] as! Float * scaleFloat
                            let nextZ = nextVertexData!["z"] as! Float * scaleFloat
                            
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
            
            sceneView.scene = scene     // set the scene
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
    
    @objc
    func tapFunction(sender:UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
}
