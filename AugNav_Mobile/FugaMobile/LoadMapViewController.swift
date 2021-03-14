import UIKit
import SceneKit
import ARKit
import Firebase
import Foundation
import CoreLocation

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}

class LoadMapViewController: UIViewController, ARSCNViewDelegate {
    
    //@IBOutlet weak var CrossImage: UIImageView!
    
    @IBOutlet weak var PlaneDetectionStatus: UILabel!
    
    var canChangeStatusToEmpty:Bool = true
    var canChangeStatusToTap:Bool = true
    
    @IBOutlet weak var sceneView: ARSCNView!
        
    var mapSelected = "map 1"
    
    var locManager = CLLocationManager()
    
    var currentLocation: CLLocation!
    
    var vertexContainer: [String: [String:Any]] = [:]
    
    var exitPath: [String] = []
    
    var xOffset:Float = 0.0
    var yOffset:Float = 0.0
    var zOffset:Float = 0.0
    
    var dogPlaced = false
    var removedPlane = false
    
    var dogNode:SCNNode!
    var dogDestIndex = 0
    var dogVertexDestination = ""
    
    var dogYDistFromVertex = 0.00 as Float
    
    var startVertex = "vertex1"
    var endVertex = "vertex1"
    
    var totalDistance:Float = 0
    
    // For animations
    var animations = [String: CAAnimation]()
    var canChangeAnimation:Bool = true
    
    // DELTE BELOW
    enum CardState {
        case expanded
        case collapsed
    }
    
    var cardViewController:CardViewController!
    var visualEffectView:UIVisualEffectView!
    
    let cardHeight:CGFloat = 600
    let cardHandleAreaHeight:CGFloat = 110
    
    var cardVisible = false
    var nextState:CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted:CGFloat = 0
    
    var expanded:Bool = false
    var keyboardOpen:Bool = false
    
    var goTrigger:Bool = true
    
    var mapData:[String:Any] = [:]
    
    var lastSpeakTime = Date().currentTimeMillis()
    
    var angle1 = 0.0;
    var angle2 = 0.0;
    var updateAngle1 = false;
    
    func setupCard() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        
        cardViewController = CardViewController(nibName:"CardViewController", bundle:nil)
        self.addChild(cardViewController)
        self.view.addSubview(cardViewController.view)
                
        cardViewController.view.frame = CGRect(x: 0, y: self.view.frame.height - cardHandleAreaHeight, width: self.view.bounds.width, height: cardHeight)
        
        cardViewController.view.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoadMapViewController.handleCardTap(recognzier:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(LoadMapViewController.handleCardPan(recognizer:)))
        cardViewController.handleArea.addGestureRecognizer(tapGestureRecognizer)
        cardViewController.handleArea.addGestureRecognizer(panGestureRecognizer)
        cardViewController.mapSelected = self.mapSelected
        
        // set up the scene in the card
        self.cardViewController.setupScene(offsetX: self.xOffset, offsetY: self.yOffset, offsetZ: self.zOffset, totalDistance: self.totalDistance)
    }

    @objc
    func handleCardTap(recognzier:UITapGestureRecognizer) {
        if(!keyboardOpen) {
            switch recognzier.state {
            case .ended:
                animateTransitionIfNeeded(state: nextState, duration: 0.9)
            default:
                break
            }
        }
    }
    
    @objc
    func handleCardPan (recognizer:UIPanGestureRecognizer) {
        if(!keyboardOpen) {
            switch recognizer.state {
            case .began:
                startInteractiveTransition(state: nextState, duration: 0.9)
            case .changed:
                let translation = recognizer.translation(in: self.cardViewController.handleArea)
                var fractionComplete = translation.y / cardHeight
                fractionComplete = cardVisible ? fractionComplete : -fractionComplete
                updateInteractiveTransition(fractionCompleted: fractionComplete)
            case .ended:
                continueInteractiveTransition()
            default:
                break
            }
        }
    }
    
    func synthesisToSpeaker(toSpeak: String) {
        
        var speechConfig: SPXSpeechConfiguration?
        do {
            try speechConfig = SPXSpeechConfiguration(subscription: "6b5b7c08f29449a48200b7abdf584529", region: "eastus")
        } catch {
            print("error \(error) happened")
            speechConfig = nil
        }
        let synthesizer = try! SPXSpeechSynthesizer(speechConfig!)
        let result = try! synthesizer.speakText(toSpeak)
        if result.reason == SPXResultReason.canceled
        {
            let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: result)
            print("cancelled, detail: \(cancellationDetails.errorDetails!) ")
        }
    }
    
    func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.expanded = true
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                case .collapsed:
                    self.expanded = false
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.cardViewController.view.layer.cornerRadius = 12
                case .collapsed:
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
            
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
//            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
//                switch state {
//                    case .expanded:
//                        self.visualEffectView.effect = UIBlurEffect(style: .dark)
//                    case .collapsed:
//                        self.visualEffectView.effect = nil
//                }
//            }
//
//            blurAnimator.startAnimation()
//            runningAnimations.append(blurAnimator)
            
        }
    }
    
    func startInteractiveTransition(state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted:CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition (){
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    // DELETE ABOVE
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // addTapGestureToSceneView()

        if #available(iOS 13.0, *) {
            // Always adopt a light interface style.
            overrideUserInterfaceStyle = .light
        }
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        // let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let scene = SCNScene()
        
        // Debug options
//        let debugOptions: SCNDebugOptions = [ARSCNDebugOptions.showWorldOrigin]
//        sceneView.debugOptions = debugOptions
//        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Load the DAE animations
        loadAnimations()
        
        //let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapFunction))
        
        //CrossImage.isUserInteractionEnabled = true
        //CrossImage.addGestureRecognizer(tap)
        
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
    
    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardRect = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        if (notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification) {
            keyboardOpen = true
        }
        else {
            keyboardOpen = false
        }
        
        if (!expanded && notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification) {
            view.frame.origin.y = -keyboardRect.height
        }
        else {
            view.frame.origin.y = 0
        }

    }
    
    func loadAnimations () {
      // Load the character in the idle animation
      let idleScene = SCNScene(named: "art.scnassets/RunningFixedScn.scn")!

      // This node will be parent of all the animation models
      dogNode = SCNNode()

      // Add all the child nodes to the parent node
      for child in idleScene.rootNode.childNodes {
        dogNode.addChildNode(child)
      }

      // Set up some properties
      dogNode.position = SCNVector3(0, 0, 0)
      dogNode.scale = SCNVector3(0.2, 0.2, 0.2)

      // Add the node to the scene
      //sceneView.scene.rootNode.addChildNode(dogNode)
        
//        let runningScene = SCNScene(named: "art.scnassets/RunningFixedScn.scn")!
//        if let animationObject = runningScene?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
//          // To create smooth transitions between animations
//          animationObject.fadeInDuration = CGFloat(1)
//          animationObject.fadeOutDuration = CGFloat(0.5)
//
//          // Store the animation for later use
//          animations[withKey] = animationObject
//        }
        
      // Load all the DAE animations
//      loadAnimation(withKey: "running", sceneName: "art.scnassets/RunningFixed", animationIdentifier: "RunningFixed-1")
    }
    
//    func loadAnimation(withKey: String, sceneName:String, animationIdentifier:String) {
//      let sceneURL = Bundle.main.url(forResource: sceneName, withExtension: "scn")
//      let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
//
//      if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
//        // To create smooth transitions between animations
//        animationObject.fadeInDuration = CGFloat(1)
//        animationObject.fadeOutDuration = CGFloat(0.5)
//
//        // Store the animation for later use
//        animations[withKey] = animationObject
//      }
//    }
    
    func playAnimation(key: String) {
        // Add the animation to start playing it right away
        print("playing " + key)
        // sceneView.scene.rootNode.addAnimation(animations[key]!, forKey: key)
    }

    func stopAnimation(key: String) {
        // Stop the animation with a smooth transition
        print("stopping " + key)
        // sceneView.scene.rootNode.removeAnimation(forKey: key, blendOutDuration: CGFloat(0.5))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(!(cardViewController == nil) && cardViewController.goMode) {
            if(dogPlaced == false) {
                guard let touch = touches.first else { return }
                let results = sceneView.hitTest(touch.location(in: sceneView), types: [.existingPlaneUsingExtent])
                guard let hitResult = results.last else { return }
                let hitTransform = SCNMatrix4.init(hitResult.worldTransform) // <- if higher than beta 1, use just this -> hitFeature.worldTransform
                let hitPosition = SCNVector3Make(hitTransform.m41,
                                                 hitTransform.m42,
                                                 hitTransform.m43)
                createDog(hitPosition: hitPosition)
            }
        }
    }
    
    func updateLabelToTouch() {
        if(canChangeStatusToTap) {
            PlaneDetectionStatus.text="Tap on the Blue Plane"
            canChangeStatusToTap = false
        }
    }
    
    func createDog(hitPosition : SCNVector3) {
        if(canChangeStatusToEmpty) {
            PlaneDetectionStatus.backgroundColor = UIColor.clear
            PlaneDetectionStatus.text=""
            canChangeStatusToEmpty = false
        }

        dogNode.position = hitPosition
        self.sceneView.scene.rootNode.addChildNode(dogNode)
            
        for vertex in self.vertexContainer {
            let x = (vertex.value["x"] as? Float)! + self.xOffset
            let y = (vertex.value["y"] as? Float)! + self.yOffset
            let z = (vertex.value["z"] as? Float)! + self.zOffset
            
            dogVertexDestination = exitPath[dogDestIndex]
            
            // Calculate y offset based off starting vertex
            if(vertex.key == startVertex) {
                dogYDistFromVertex = -1*(abs(y-dogNode.position.y))
            }

        }
        
        playAnimation(key: "running")

        dogPlaced = true
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
        configuration.planeDetection = .horizontal
        
        //let alert = UIAlertController(title: "Select Map", message: "Please enter the vertex you are at and where you want to go.", preferredStyle: .alert)

        let alert = UIAlertController(title: "Start Position", message: "Please enter the vertex you are at.", preferredStyle: .alert)
                
        alert.addTextField { (textField2) in
            textField2.text = "vertex1"
        }
        
//        alert.addTextField { (textField3) in
//            textField3.text = "exit"
//        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
//            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
//            let textField2 = alert?.textFields![1] // Force unwrapping because we know it exists.
            let textField2 = alert?.textFields![0]
            //let textField3 = alert?.textFields![1]
            
            //self.mapSelected = textField!.text!

            // Run the view's session
            self.sceneView.session.run(configuration)
            
            let db = Firestore.firestore()
            let curUser = Firebase.Auth.auth().currentUser
            
            //print("going to use " + String(self.mapSelected))
            
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
                        // Call to server to find path
                        self.mapData = (document.data()! as? [String:Any])!
                        
                        self.endVertex = (self.mapData["endVertex"] as? String)!
                        
                        // IMPORTANT STUFF TO MOVE:::
//                        if(textField3!.text != "exit") {
//                            endVertex = textField3!.text
//                        }
//
//                        self.sendPathRequest(mapDataIn: mapData, startPointIn: textField2!.text!, endPointIn: endVertex!)
                        
                        // setup card at bottom
                        
                        // set to 30% opacity
                        // Draw spheres
                        if let downcastVerticies = self.mapData["data"]! as? [String:Any] {
                            print(downcastVerticies)
                            
                            if let size = self.mapData["size"] as? Int {
                                for index in 1...size {
                                    let curVertex = "vertex" + String(index)
                                    
                                    if let downcastVertex = downcastVerticies[curVertex]! as? [String:Any] {
                                        let x = downcastVertex["x"] as? Float
                                        let y = downcastVertex["y"] as? Float
                                        let z = downcastVertex["z"] as? Float
                                        
                                        let radius = downcastVertex["radius"] as? Float
                                        let name = downcastVertex["name"] as? String
                                        let next = downcastVertex["next"] as? [String]
                                        
                                        let obj: [String: Any] = [
                                            "x": x!,
                                            "y": y!,
                                            "z": z!,
                                            "radius": radius!,
                                            "name" : name!,
                                            "next": next!,
                                            "dogReached": false
                                        ]
                                        
                                        print(obj)
                                        
                                        self.vertexContainer[curVertex] = obj
                                    }
                                }
                                
                                self.startVertex = textField2!.text!
                                
                                if(self.vertexContainer[self.startVertex] == nil) {
                                    print("ERROR: Start point does not exist.")
                                    DispatchQueue.main.async {
                                        let alert = UIAlertController(title: "Path Error", message: "The starting point you chose does not exist. Please enter it correctly.", preferredStyle: .alert)

                                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                                            self.dismiss(animated: true, completion: nil)
                                        }))

                                        self.present(alert, animated: true)
                                    }
                                }
                                else {
                                    // setup card after loading map and parsing the data
                                    print(self.vertexContainer)
                                    print("start: " + self.startVertex)

                                    self.xOffset = -1*(self.vertexContainer[self.startVertex]!["x"] as? Float)!
                                    self.yOffset = -1*(self.vertexContainer[self.startVertex]!["y"] as? Float)!
                                    self.zOffset = -1*(self.vertexContainer[self.startVertex]!["z"] as? Float)!
                                    //DispatchQueue.main.async {
                                    // }
                                    self.setupCard()
                                }
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
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    func createBall(position : SCNVector3, ballRadius : Float, x : Float, y : Float, z : Float, name: String) {
//        let ball = SCNSphere(radius: CGFloat(ballRadius))
//        let ballNode = SCNNode(geometry: ball)
//        ball.firstMaterial?.lightingModel = SCNMaterial.LightingModel.physicallyBased
//        ball.firstMaterial?.diffuse.contents = UIColor.red
//
//        ballNode.position = position
//        sceneView.scene.rootNode.addChildNode(ballNode)
//
//        let text = SCNText(string: String(name), extrusionDepth: 0.1)
//
//        text.font = UIFont.systemFont(ofSize: 1.0)
//        text.flatness = 0.01
//        text.firstMaterial?.diffuse.contents = UIColor.white
//
//        let textNode = SCNNode(geometry: text)
//
//        let fontSize = Float(0.04)
//        textNode.scale = SCNVector3(fontSize, fontSize, fontSize)
//
//        textNode.position = SCNVector3(x, y+ballRadius, z)
//
//        sceneView.scene.rootNode.addChildNode(textNode)
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if(!(cardViewController == nil) && cardViewController.goMode) {
            if(dogPlaced == false) {
                // 1
                guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

                // 2
    //            let width = CGFloat(planeAnchor.extent.x)
    //            let height = CGFloat(planeAnchor.extent.z)
                let width = 0.5 as Float
                let height = 0.5 as Float
                let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))

                // 3
                plane.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.8)

                // 4
                let planeNode = SCNNode(geometry: plane)

                // 5
                let x = CGFloat(planeAnchor.center.x)
                let y = CGFloat(planeAnchor.center.y)
                let z = CGFloat(planeAnchor.center.z)
                planeNode.position = SCNVector3(x,y,z)
                planeNode.eulerAngles.x = -.pi / 2

                // 6
                node.addChildNode(planeNode)
                
                DispatchQueue.global(qos: .background).async {// global() will use a background thread rather than the main thread
                    DispatchQueue.main.sync {
                        self.updateLabelToTouch()
                    }
                }
                
                //updateLabelToTouch()
            }
            if(dogPlaced==true){
                // Remove all plane nodes
                guard let _ = anchor as?  ARPlaneAnchor,
                 let planeNode = node.childNodes.first,
                    let _ = planeNode.geometry as? SCNPlane
                 else { return }

                planeNode.removeFromParentNode()
            }
        }
    }
    
    func updatePositionAndOrientationOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) {
        let referenceNodeTransform = matrix_float4x4(referenceNode.transform)

        // Setup a translation matrix with the desired position
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = position.x
        translationMatrix.columns.3.y = position.y
        translationMatrix.columns.3.z = position.z

        // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
        node.transform = SCNMatrix4(updatedTransform)
    }
    
    //Vertex is pos1
    func calculateAngleBetween3Positions(pos1:SCNVector3, pos2:SCNVector3, pos3:SCNVector3) -> Float {
        let v1 = SCNVector3(x: pos2.x-pos1.x, y: pos2.y-pos1.y, z: pos2.z-pos1.z)
        let v2 = SCNVector3(x: pos3.x-pos1.x, y: pos3.y-pos1.y, z: pos3.z-pos1.z)

        let v1Magnitude = sqrt(v1.x * v1.x + v1.y * v1.y + v1.z * v1.z)
        let v1Normal = SCNVector3(x: v1.x/v1Magnitude, y: v1.y/v1Magnitude, z: v1.z/v1Magnitude)

        let v2Magnitude = sqrt(v2.x * v2.x + v2.y * v2.y + v2.z * v2.z)
        let v2Normal = SCNVector3(x: v2.x/v2Magnitude, y: v2.y/v2Magnitude, z: v2.z/v2Magnitude)

        let result = v1Normal.x * v2Normal.x + v1Normal.y * v2Normal.y + v1Normal.z * v2Normal.z
        let angle = acos(result)
        
        return angle
    }
    
    func findDirection(pos1:SCNVector3, pos2:SCNVector3, pos3:SCNVector3) -> Float {
        let v1 = SCNVector3(x: pos2.x-pos1.x, y: pos2.y-pos1.y, z: pos2.z-pos1.z)
        let v2 = SCNVector3(x: pos3.x-pos1.x, y: pos3.y-pos1.y, z: pos3.z-pos1.z)
        
        return v1.x*(-1)*v2.z + v1.z*v2.x
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if(!(cardViewController == nil) && cardViewController.goMode) {
            if(dogPlaced == false) {
                // 1
                guard let planeAnchor = anchor as?  ARPlaneAnchor,
                 let planeNode = node.childNodes.first,
                 let plane = planeNode.geometry as? SCNPlane
                 else { return }

                // 2
                //            let width = CGFloat(planeAnchor.extent.x)
                //            let height = CGFloat(planeAnchor.extent.z)
                let width = 0.5 as Float
                let height = 0.5 as Float
                plane.width = CGFloat(width)
                plane.height = CGFloat(height)

                // 3
                let x = CGFloat(planeAnchor.center.x)
                let y = CGFloat(planeAnchor.center.y)
                let z = CGFloat(planeAnchor.center.z)
                planeNode.position = SCNVector3(x, y, z)
                
                DispatchQueue.global(qos: .background).async {// global() will use a background thread rather than the main thread
                    DispatchQueue.main.sync {
                        self.updateLabelToTouch()
                    }
                }
                //updateLabelToTouch()
            }
            if(dogPlaced==true){
                // Remove all plane nodes
                guard let _ = anchor as?  ARPlaneAnchor,
                 let planeNode = node.childNodes.first,
                    let _ = planeNode.geometry as? SCNPlane
                 else { return }

                planeNode.removeFromParentNode()
            }
        }
    }
    
    var startTime = 0.0
    
    var prevLocation = SCNVector3(0, 0, 0)
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        
        let prevLocNode = SCNVector3ToGLKVector3(prevLocation)
        let curLocNode = SCNVector3ToGLKVector3(location)
        
        let currentTime = Date().currentTimeMillis()
                    
        
        let lookingNode:SCNNode = SCNNode()
        //Now update node say `2` away in the Z (looking direction)
        let position = SCNVector3(x: 0, y: 0, z: -2)
        updatePositionAndOrientationOf(lookingNode, withPosition: position, relativeTo: pointOfView)
        let angle = calculateAngleBetween3Positions(pos1: location, pos2: SCNVector3(lookingNode.position.x, lookingNode.position.y, lookingNode.position.z), pos3: dogNode.position)
        let directionAngle = findDirection(pos1: location, pos2: SCNVector3(lookingNode.position.x, lookingNode.position.y, lookingNode.position.z), pos3: dogNode.position)
        
        if(dogPlaced && location != nil && dogNode != nil && currentTime - lastSpeakTime > 2000) {
            self.lastSpeakTime = currentTime

            DispatchQueue.global(qos: .background).async {
                if(angle < 0.2) {
                    self.synthesisToSpeaker(toSpeak: "go forward")
                }
                else {
                    if(directionAngle < 0) {
                        self.synthesisToSpeaker(toSpeak: "turn right")
                    }
                    else {
                        self.synthesisToSpeaker(toSpeak: "turn left")
                    }
                }

                DispatchQueue.main.async {
                    
                }
            }
        }
        
        if(location != nil && GLKVector3Distance(prevLocNode, curLocNode) > 0.5) {
            print("updating location")
            
            if(location != nil && !(cardViewController==nil) && !(cardViewController.userLocation == nil)) {
                cardViewController.userLocation.position = SCNVector3Make((location.x-xOffset)*cardViewController.scaleFloat, (location.y-yOffset)*cardViewController.scaleFloat, (location.z-zOffset)*cardViewController.scaleFloat)
                cardViewController.mapScene.sceneTime += 1
            }
            
            prevLocation = location
        }
        
        if(!(cardViewController == nil) && goTrigger && cardViewController.goMode) {
            DispatchQueue.main.async {
                print("Finding path!")
                
                if(self.cardViewController.searchBar.text != nil && self.cardViewController.searchBar.text != "exit") {
                    self.endVertex = self.cardViewController.searchBar.text!
                }
                
                self.sendPathRequest(mapDataIn: self.mapData, startPointIn: self.startVertex, endPointIn: self.endVertex)
            }
            goTrigger = false
        }

        if(!(cardViewController == nil) && cardViewController.goMode) {
            if(dogPlaced==true){
                let dt = (time - startTime) as Double
                let v = 0.5 as Double
                let dx = Float(v*dt)
                
                let threshold = 0.1
                
                for vertex in self.vertexContainer {
                    let x = (vertex.value["x"] as? Float)! + self.xOffset
                    let y = (vertex.value["y"] as? Float)! + self.yOffset
                    let z = (vertex.value["z"] as? Float)! + self.zOffset
                    
                    dogVertexDestination = exitPath[dogDestIndex]
                    
                    if(vertex.key == dogVertexDestination) {
                        let dogX = dogNode.position.x as Float
                        let dogY = dogNode.position.y as Float
                        let dogZ = dogNode.position.z as Float
                        
                        var dogReachedWaypoint = false
                        
                        let node1Pos = SCNVector3ToGLKVector3(SCNVector3(x, y, z))
                        let node2Pos = SCNVector3ToGLKVector3(location)

                        let distance = GLKVector3Distance(node1Pos, node2Pos)
                        
                        //print(distance)
                        
                        
                        if(Double(abs(dogX - x)) > threshold) {
                            if(dogNode.position.x < x) {
                                dogNode.position.x += dx
                            }
                            else if(dogNode.position.x > x) {
                                dogNode.position.x -= dx
                            }
                            dogReachedWaypoint = false
                        }
                        else {
                            dogReachedWaypoint = true
                        }
                        
                        // Don't move y axis for now
                        if(Double(abs(dogY - dogYDistFromVertex - y)) > threshold) {
                            if(dogNode.position.y - dogYDistFromVertex < y) {
                                dogNode.position.y += dx
                            }
                            else if(dogNode.position.y - dogYDistFromVertex > y) {
                                dogNode.position.y -= dx
                            }
                            dogReachedWaypoint = false
                        }

                        if(Double(abs(dogZ - z)) > threshold) {
                            if(dogNode.position.z < z) {
                                dogNode.position.z += dx
                            }
                            else if(dogNode.position.z > z) {
                                dogNode.position.z -= dx
                            }
                            
                            dogReachedWaypoint = false
                        }
                        
                        // If the dog reached the waypoint and the camera is close to it, update the vertex container
                        if(dogReachedWaypoint) {
                            dogNode.simdLook(at: simd_float3(location.x,dogY,location.z), up: simd_float3(0,1,0), localFront: simd_float3(0,0,1))
                            
                            if(canChangeAnimation) {
                                stopAnimation(key: "running")
                                canChangeAnimation = false
                            }
                            if(distance < 1.0) {
                                if(dogDestIndex + 1 < exitPath.count) {
                                    print("Hello world");
                                    print("Doggo reached " + dogVertexDestination)
                                    dogDestIndex+=1
                                    playAnimation(key: "running")
                                    canChangeAnimation = true
                                    if(currentTime - lastSpeakTime > 1000) {
                                        self.lastSpeakTime = currentTime

                                        DispatchQueue.global(qos: .background).async {
                                            self.synthesisToSpeaker(toSpeak: "stop walking")

                                            DispatchQueue.main.async {

                                            }
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            dogNode.simdLook(at: simd_float3(x,dogY,z), up: simd_float3(0,1,0), localFront: simd_float3(0,0,1))
                        }
                    }
                    
                    startTime = time
                }
                
            }
            else {
                startTime = time
            }
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
//    @objc
//    func tapFunction(sender:UITapGestureRecognizer) {
//        self.dismiss(animated: true, completion: nil)
//    }
    
    func sendPathRequest(mapDataIn: [String:Any], startPointIn: String, endPointIn: String) {

        //declare parameter as a dictionary which contains string as key and value combination. considering inputs are valid
        
        startVertex = startPointIn

        let parameters = ["mapDataIn": mapDataIn, "startPointIn": startPointIn, "endPointIn": endPointIn] as [String : Any]

        //create the url with URL
        let url = URL(string: "http://augnav.herokuapp.com/getPath")! //change the url

        //create the session object
        let session = URLSession.shared

        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
        } catch let error {
            print(error.localizedDescription)
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            guard error == nil else {
                return
            }

            guard let data = data else {
                return
            }

            do {
                //create json object from data
                var prevX:Float = -1
                var prevY:Float = -1
                var prevZ:Float = -1
                
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print("EXIT PATH FOUND:")
                    
                    if(json["exitPath"] != nil) {
                        self.exitPath = json["exitPath"] as! [String]
                        
                        print(self.exitPath)
                        print(self.exitPath.count)
                        
                        if(self.exitPath.count > 0) {
                            DispatchQueue.main.async {
                                self.PlaneDetectionStatus.text = "Searching for Floor"
                                self.PlaneDetectionStatus.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
                            }
                            
                            if let downcastVerticies = mapDataIn["data"]! as? [String:Any] {
                                if let size = mapDataIn["size"] as? Int {
                                    for index in 1...size {
                                        let curVertex = "vertex" + String(index)
                                        
                                        if self.exitPath.contains(curVertex) {
                                            if let downcastVertex = downcastVerticies[curVertex]! as? [String:Any] {
                                                let x = downcastVertex["x"] as? Float
                                                let y = downcastVertex["y"] as? Float
                                                let z = downcastVertex["z"] as? Float
                                                
                                                if(prevX != -1) {
                                                    let node1Pos = SCNVector3ToGLKVector3(SCNVector3(x!, y!, z!))
                                                    let node2Pos = SCNVector3ToGLKVector3(SCNVector3(prevX, prevY, prevZ))

                                                    let distance = GLKVector3Distance(node1Pos, node2Pos)
                                                    
                                                    self.totalDistance += distance
                                                }
                                                
                                                prevX = x!
                                                prevY = y!
                                                prevZ = z!
                                            }
                                        }
                                    }
                                }
                            }
                            
                            
                            if(self.vertexContainer[startPointIn] == nil) {
                                let alert = UIAlertController(title: "Vertex Not Found", message: "The starting or ending vertex you entered could not be found.", preferredStyle: .alert)

                                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                                    self.dismiss(animated: true, completion: nil)
                                }))

                                self.present(alert, animated: true)
                            }
                            else {
//                                for vertex in self.vertexContainer {
//                                    let x = (vertex.value["x"] as? Float)! + self.xOffset
//                                    let y = (vertex.value["y"] as? Float)! + self.yOffset
//                                    let z = (vertex.value["z"] as? Float)! + self.zOffset
//                                    let radius = vertex.value["radius"] as? Float
//                                    let name = vertex.value["name"] as? String
//                                    let nextArr = vertex.value["next"] as? [String]
//                                    self.createBall(position: SCNVector3(x,y,z), ballRadius: radius!, x: x, y: y, z: z, name: name!)
//                                }
                                
                                // set up the scene in the card
                                DispatchQueue.main.async {
                                    self.cardViewController.updateDistanceInfo(totalDistance: self.totalDistance)
                                }
                            }
                        }
                        else {
                            print("ERROR PATH SIZE IS 0 OR LESS")
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Path Error", message: "The ending point you chose does not exist.", preferredStyle: .alert)

                                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                                    self.dismiss(animated: true, completion: nil)
                                }))

                                self.present(alert, animated: true)
                            }
                        }

                    }
                    else {
                        print("ERROR: NO EXIT PATH FOUND (LOAD MAP VIEW CONTROLLER)")
                        
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Server Error", message: "Error making the server call.", preferredStyle: .alert)

                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                                self.dismiss(animated: true, completion: nil)
                            }))

                            self.present(alert, animated: true)
                        }
                    }
                    
                }
            } catch let error {
                print("ERROR MAKING SERVER CALL!")
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Server Error", message: "Error making the server call.", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                        self.dismiss(animated: true, completion: nil)
                    }))

                    self.present(alert, animated: true)
                }
            }
        })
        task.resume()
    }
}
