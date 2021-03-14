import UIKit
import SceneKit
import ARKit
import Firebase
import Foundation
import CoreLocation

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var CrossImage: UIImageView!
    @IBOutlet weak var AddButton: UIImageView!
    @IBOutlet weak var ChangeButton: UIImageView!
    @IBOutlet weak var VertexSelectedText: UILabel!
    @IBOutlet weak var ConnectButton: UIButton!
    
    var grids = [Grid]()
    
    var unsavedData = true
    
    var mapName = "no name"
    var vertexCount = 1
    var selectedVertex = "vertex1"
    
    var endVertex = "vertex1"
    
    var vertexContainer: [String: [String:Any]] = [:]
    
    var locManager = CLLocationManager()
    
    var currentLocation: CLLocation!
    
    
    var goodX = 0 as Float
    var goodY = 0 as Float
    var goodZ = 0 as Float
    var goodVertex = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            // Always adopt a light interface style.
            overrideUserInterfaceStyle = .light
        }
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        let scene = SCNScene()
        
        // Debug options
        //let debugOptions: SCNDebugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        let debugOptions: SCNDebugOptions = [ARSCNDebugOptions.showWorldOrigin]
        sceneView.debugOptions = debugOptions
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapFunction))
        
        CrossImage.isUserInteractionEnabled = true
        CrossImage.addGestureRecognizer(tap)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapFunction2))
        
        AddButton.isUserInteractionEnabled = true
        AddButton.addGestureRecognizer(tap2)
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapFunction3))
        
        ChangeButton.isUserInteractionEnabled = true
        ChangeButton.addGestureRecognizer(tap3)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        locManager.requestWhenInUseAuthorization()

        if
           CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
           CLLocationManager.authorizationStatus() ==  .authorizedAlways
        {
            currentLocation = locManager.location
        }
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        configuration.planeDetection = .vertical
        configuration.isLightEstimationEnabled = true
        
        let alert = UIAlertController(title: "Map Name", message: "Please enter a map name.", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = "map 1"
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            
            self.mapName = textField!.text!
            
            // Run the view's session
            self.sceneView.session.run(configuration)
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //var hideButton = false
    
    var i = 0
    var canChangeButtonState = true
    var buttonIsHidden = true
            
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        var hideButton = true
        
        for vertex in vertexContainer {
            let nextArrOfSelectedVertex = vertexContainer[selectedVertex]!["next"] as! [String]
            
            //print(nextArrOfSelectedVertex)
            //print(String(vertex.key) + " , " + String(selectedVertex))
            
            if(vertex.key != selectedVertex && !(nextArrOfSelectedVertex.contains(vertex.key))) {
                guard let pointOfView = sceneView.pointOfView else { return }
                
                let transform = pointOfView.transform
                let location = SCNVector3(transform.m41, transform.m42, transform.m43)
                
                let x = vertex.value["x"] as? Float
                let y = vertex.value["y"] as? Float
                let z = vertex.value["z"] as? Float
                
                let node1Pos = SCNVector3ToGLKVector3(SCNVector3(x!, y!, z!))
                let node2Pos = SCNVector3ToGLKVector3(location)

                let distance = GLKVector3Distance(node1Pos, node2Pos)
                                
                if(distance < 0.3) {
                    hideButton = false
                    goodX = x!
                    goodY = y!
                    goodZ = z!
                    goodVertex = vertex.key
                }
            }
        }
        
        if(hideButton != buttonIsHidden) {
            canChangeButtonState = true
        }

        if(canChangeButtonState) {
            DispatchQueue.main.async {
                self.ConnectButton.isHidden = hideButton
                self.buttonIsHidden = hideButton
                self.canChangeButtonState = false
            }
        }
    }
    
    @IBAction func connectBtnClicked(_ sender: Any) {
        // Add each other to next array
        if var downcastStrings = vertexContainer[selectedVertex]!["next"]! as? [String] {
            // Append to array
            downcastStrings.append(goodVertex)
            vertexContainer[selectedVertex]!["next"] = downcastStrings
        }
        
        if var downcastStrings = vertexContainer[goodVertex]!["next"]! as? [String] {
            // Append to array
            downcastStrings.append(selectedVertex)
            vertexContainer[goodVertex]!["next"] = downcastStrings
        }
        
        // Draw a line connecting the veriticies
        let prevX = vertexContainer[selectedVertex]!["x"] as! Float
        let prevY = vertexContainer[selectedVertex]!["y"] as! Float
        let prevZ = vertexContainer[selectedVertex]!["z"] as! Float
        
        let nextX = vertexContainer[goodVertex]!["x"] as! Float
        let nextY = vertexContainer[goodVertex]!["y"] as! Float
        let nextZ = vertexContainer[goodVertex]!["z"] as! Float
        
        let lineNode = SCNGeometry.lineNode(from: simd_float3(prevX, prevY, prevZ), to: simd_float3(nextX, nextY, nextZ))
        sceneView.scene.rootNode.addChildNode(lineNode)
        
        selectedVertex = goodVertex
        
        changeVertexSelectedText(newText: "Vertex Selected: " + selectedVertex)
    }

    func createBall(position : SCNVector3, ballRadius : Float, x : Float, y : Float, z : Float) {
        let ball = SCNSphere(radius: CGFloat(ballRadius))
        let ballNode = SCNNode(geometry: ball)
        ball.firstMaterial?.diffuse.contents = UIColor.red
        
        ballNode.position = position
        sceneView.scene.rootNode.addChildNode(ballNode)
        
        let text = SCNText(string: String(vertexCount), extrusionDepth: 0.1)
        
        text.font = UIFont.systemFont(ofSize: 1.0)
        text.flatness = 0.01
        text.firstMaterial?.diffuse.contents = UIColor.cyan
        
        let textNode = SCNNode(geometry: text)
        
        let fontSize = Float(0.04)
        textNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        
        textNode.position = SCNVector3(x, y+ballRadius, z)
        
        sceneView.scene.rootNode.addChildNode(textNode)
        
        let vertexName = "vertex" + String(vertexCount)
        
        let jsonObject: [String: Any] = [
            "x": x,
            "y": y,
            "z": z,
            "radius": ballRadius,
            "name" : vertexName,
            "next": []
        ]
        
        vertexContainer[vertexName] = jsonObject
        selectedVertex = vertexName
        changeVertexSelectedText(newText: "Vertex Selected: " + String(vertexCount))
        vertexCount+=1
        
        unsavedData = true
    }
    
    @IBAction func SaveButtonClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Select End Vertex", message: "Please enter the end vertex's number.", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = "1"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            
            if(Int(textField!.text!)! < Int(self.vertexCount) && Int(textField!.text!)! > 0) {
                self.endVertex = "vertex" + textField!.text!
                
                let db = Firestore.firestore()
                let curUser = Firebase.Auth.auth().currentUser
                
                let valid = JSONSerialization.isValidJSONObject(self.vertexContainer) // true
                
                if(valid) {
                    db.collection("users").document((curUser?.email)!).collection("maps").document(self.mapName).setData([
                        "email": curUser?.email,
                        "name": self.mapName,
                        "data": self.vertexContainer,
                        "size": self.vertexCount-1,
                        "endVertex": self.endVertex,
                        "longitude": String(self.currentLocation.coordinate.longitude),
                        "latitude": String(self.currentLocation.coordinate.latitude)
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                            
                            let alert = UIAlertController(title: "Database Error", message: "Error uploading map.", preferredStyle: .alert)

                            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

                            self.present(alert, animated: true)
                        } else {
                            let alert = UIAlertController(title: "Map Saved!", message: "Map was successfully saved to the database.", preferredStyle: .alert)

                            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

                            self.present(alert, animated: true)
                            self.unsavedData = false
                        }
                    }
                }
                else {
                    let alert = UIAlertController(title: "Map Error", message: "Error saving map.", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

                    self.present(alert, animated: true)
                }
            }
            else {
                let alert = UIAlertController(title: "Unknown Vertex", message: "That vertex does not exist.", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

                self.present(alert, animated: true)
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    @objc
    func tapFunction(sender:UITapGestureRecognizer) {
        if(unsavedData) {
            let alert = UIAlertController(title: "Exit Map Creator?", message: "Unsaved data will be lost.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak alert] (_) in
                self.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))

            self.present(alert, animated: true)
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc
    func tapFunction2(sender:UITapGestureRecognizer) {
        let xPos = sceneView.pointOfView!.position.x
        let yPos = sceneView.pointOfView!.position.y
        let zPos = sceneView.pointOfView!.position.z
        
        let curLocation = SCNVector3Make((xPos), (yPos), (zPos))
        let ballRadius = Float(0.05)
        
        let prevSelectedVertex = selectedVertex
        
        createBall(position: curLocation, ballRadius: ballRadius, x: xPos, y: yPos, z: zPos)
        
        if(vertexCount > 2) {
            // Link current vertex selected to new vertex placed
            if var downcastStrings = vertexContainer[prevSelectedVertex]!["next"]! as? [String] {
                // Append to array
                downcastStrings.append(selectedVertex)
                vertexContainer[prevSelectedVertex]!["next"] = downcastStrings
                
                // Draw a line connecting the veriticies
                let prevX = vertexContainer[prevSelectedVertex]!["x"]
                let prevY = vertexContainer[prevSelectedVertex]!["y"]
                let prevZ = vertexContainer[prevSelectedVertex]!["z"]
                
                let lineNode = SCNGeometry.lineNode(from: simd_float3(prevX as! Float,prevY as! Float,prevZ as! Float), to: simd_float3(xPos,yPos,zPos))
                sceneView.scene.rootNode.addChildNode(lineNode)
            }
            
            
            if var downcastStrings = vertexContainer[selectedVertex]!["next"]! as? [String] {
                // Append to array
                downcastStrings.append(prevSelectedVertex)
                vertexContainer[selectedVertex]!["next"] = downcastStrings
            }
        }
    }
    
    @objc
    func tapFunction3(sender:UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Change Selected Vertex", message: "Please enter a vertex number to change to.", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = "1"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            
            if(Int(textField!.text!)! < Int(self.vertexCount) && Int(textField!.text!)! > 0) {
                self.selectedVertex = "vertex" + textField!.text!
                self.changeVertexSelectedText(newText: "Vertex Selected: " + textField!.text!)
            }
            else {
                let alert = UIAlertController(title: "Unknown Vertex", message: "That vertex does not exist.", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

                self.present(alert, animated: true)
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func changeVertexSelectedText(newText:String) {
        VertexSelectedText.text = newText
    }
}

extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }

    static func lineNode(from: simd_float3, to: simd_float3, radius : CGFloat = 0.015) -> SCNNode
    {
        let vector = to - from
        let height = simd_length(vector)

        //cylinder
        let cylinder = SCNCylinder(radius: radius, height: CGFloat(height))
        cylinder.firstMaterial?.diffuse.contents = UIColor.green

        //line node
        let lineNode = SCNNode(geometry: cylinder)

        //adjust line position
        let line_axis = simd_float3(0, height/2, 0)
        lineNode.simdPosition = from + line_axis

        let vector_cross = simd_cross(line_axis, vector)
        let qw = simd_length(line_axis) * simd_length(vector) + simd_dot(line_axis, vector)
        let q = simd_quatf(ix: vector_cross.x, iy: vector_cross.y, iz: vector_cross.z, r: qw).normalized

        lineNode.simdRotate(by: q, aroundTarget: from)
        return lineNode
    }
}
