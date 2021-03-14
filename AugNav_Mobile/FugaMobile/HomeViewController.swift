import UIKit
import Firebase
import MapKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarDelegate, MKMapViewDelegate, CLLocationManagerDelegate, MyCustomCellDelegator, MyCustomCellDelegator2 {
    
    var mapNameSelected = "map 1"
    var loadMapTouched = false
    var viewMapTouched = false
    
    var curLong : Double = 0;
    var curLat : Double = 0;
    
    var db = Firestore.firestore()
    
    @IBOutlet weak var CreateMapItem: UITabBarItem!
    @IBOutlet weak var TabBarReference: UITabBar!
    
    @IBOutlet weak var TableReference: UITableView!
    
    var list:[String] = []
    var vertCountList:[Int] = []
    var latList:[String] = []
    var lonList:[String] = []
    let cellSpacingHeight: CGFloat = 5
    
    var itemChosen: Int = 1
    
    var locManager = CLLocationManager()
    
    @IBOutlet weak var largeMapView: MKMapView!
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = TableReference.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ViewControllerTableViewCell
        cell.myLabel.text = list[indexPath.row]
        cell.myLabel.adjustsFontSizeToFitWidth = true
        cell.mapName = list[indexPath.row]
        if(vertCountList[indexPath.row] > 1) {
            cell.mySubLabel.text = String(vertCountList[indexPath.row]) + " vertices"
        }
        else {
            cell.mySubLabel.text = String(vertCountList[indexPath.row]) + " vertex"
        }
        
        if(curLat != nil && curLong != nil) {
            let annotation:MKPointAnnotation = MKPointAnnotation()
            annotation.title = "You"
            // You can also add a subtitle that displays under the annotation such as
            let pos = CLLocationCoordinate2D(latitude: curLat, longitude: curLong)
            annotation.coordinate = pos
        
            cell.mapView.addAnnotation(annotation)

            cell.mapView.showAnnotations(cell.mapView.annotations, animated: true)
        }
                
        let location = CLLocationCoordinate2D(latitude: Double(latList[indexPath.row])!, longitude: Double(lonList[indexPath.row])!)
        
        let diameter = 500
        let region: MKCoordinateRegion = MKCoordinateRegion(center: location, latitudinalMeters: CLLocationDistance(diameter), longitudinalMeters: CLLocationDistance(diameter))
        cell.mapView.setRegion(region, animated: true)
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = bgColorView
        cell.layer.backgroundColor = UIColor.clear.cgColor
        
//        cell.layer.cornerRadius = 8
        
        cell.delegate = self
        cell.delegate2 = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let modifyAction = UIContextualAction(style: .normal, title:  "Delete", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Update action ...")
            success(true)
            print(self.list[indexPath[1]])
            
            let user = Auth.auth().currentUser
            
            if ((user) != nil) {
                let alert = UIAlertController(title: "Delete Map", message: "Would you like to delete the " + self.list[indexPath[1]] + " map?", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                    self.db.collection("users").document((user?.email)!).collection("maps").document(self.list[indexPath[1]]).delete() { err in
                      if let err = err {
                          print("Error removing document: \(err)")
                      } else {
                          print("Document successfully removed!")
                      }
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [weak alert] (_) in
                    print("canceled")
                }))

                self.present(alert, animated: true)
            } else {
                print("no user logged in!")
            }
        })
        
        modifyAction.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0)
    
        return UISwipeActionsConfiguration(actions: [modifyAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let modifyAction = UIContextualAction(style: .normal, title:  "Edit", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Update action ...")
            success(true)
            print(self.list[indexPath[1]])
            
            let user = Auth.auth().currentUser
            
            if ((user) != nil) {
                let docRef = self.db.collection("users").document((user?.email)!).collection("maps").document(self.list[indexPath[1]])

                docRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let alert = UIAlertController(title: "Edit Map", message: "Enter a new end vertex.", preferredStyle: .alert)
                                                
                        let endVertex = document.data()!["endVertex"] as! String
                        let data = document.data()!["data"] as! [String:Any]
                        
                        alert.addTextField { (textField) in
                            textField.text = endVertex
                        }
                        
                        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak alert] (_) in
                            let newEndVertex = alert?.textFields![0].text
                            
                            if(newEndVertex != nil && data[newEndVertex!] != nil) {
                                docRef.updateData([
                                    "endVertex": newEndVertex!.trimmingCharacters(in: .whitespacesAndNewlines)
                                ]) { err in
                                    if let err = err {
                                        print("Error updating document: \(err)")
                                    } else {
                                        print("Document successfully updated")
                                    }
                                }
                            }
                            else {
                                let alert2 = UIAlertController(title: "Error", message: "The end vertex you entered is invalid.", preferredStyle: .alert)
                                alert2.addAction(UIAlertAction(title: "Ok", style: .default, handler: { [weak alert] (_) in
                                    print("end vertex error")
                                }))
                                self.present(alert2, animated: true)
                            }
                        }))
                        
                        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [weak alert] (_) in
                            print("canceled")
                        }))
                        
                        self.present(alert, animated: true)

                    } else {
                        print("Document does not exist")
                    }
                }
            } else {
                print("no user logged in!")
            }
        })
        
        modifyAction.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0)
    
        return UISwipeActionsConfiguration(actions: [modifyAction])
    }
    
    
    //MARK: - MyCustomCellDelegator Methods

    func callSegueFromCell(myData: String) {
        loadMapTouched = true
        self.mapNameSelected = myData
        print("going to load " + myData)
        performSegue(withIdentifier: "HomeToLoadMap", sender: self)

    }
    
        func callSegueFromCell2(myData: String) {
            viewMapTouched = true
            self.mapNameSelected = myData
            print("going to load " + myData)
            performSegue(withIdentifier: "HomeToViewMap", sender: self)

        }

    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if(item.tag == -1) {
            //print("going to create map")
            //performSegue(withIdentifier: "HomeToARView", sender: nil)
            TableReference.isHidden = true
            tabBar.selectedItem = tabBar.items?.first
            //self.largeMapView.mapType = .hybridFlyover
            self.largeMapView.isHidden = false
            self.largeMapView.showAnnotations(self.largeMapView.annotations, animated: true)
            //realisticMapView()
            itemChosen = 0
        }
        else if(item.tag == 0) {
            //print("going to create map")
            //performSegue(withIdentifier: "HomeToARView", sender: nil)
            TableReference.isHidden = false
            tabBar.selectedItem = tabBar.items?[1]
            self.largeMapView.isHidden = true
            //self.largeMapView.mapType = .standard
            //materialMapView()
            itemChosen = 1
        }
        else if(item.tag == 1) {
            print("going to create map")
            performSegue(withIdentifier: "HomeToARView", sender: nil)
        }
        else if (item.tag == 2) {
            let firebaseAuth = Auth.auth()
            
            do {
                try firebaseAuth.signOut()
                dismiss(animated: true, completion: nil)
                print("logged out")
            } catch let signOutError as NSError {
                NSLog("Error signing out: %@", signOutError)
            }
        }
        
        print(itemChosen)
        
        if(itemChosen == 0) {
            tabBar.selectedItem = tabBar.items?.first
        }
        else {
            tabBar.selectedItem = tabBar.items?[1]
        }
    }
    
    func realisticMapView() {
        //self.largeMapView.mapType = .hybridFlyover
        
        let location = CLLocationCoordinate2D(latitude: self.curLat, longitude: self.curLong)
        
        let diameter = 100
        let region: MKCoordinateRegion = MKCoordinateRegion(center: location, latitudinalMeters: CLLocationDistance(diameter), longitudinalMeters: CLLocationDistance(diameter))
        self.largeMapView.setRegion(region, animated: true)
    }
    
    func materialMapView() {
        //self.largeMapView.mapType = .standard
        
        let location = CLLocationCoordinate2D(latitude: self.curLat, longitude: self.curLong)
        
        let diameter = 10000000
        let region: MKCoordinateRegion = MKCoordinateRegion(center: location, latitudinalMeters: CLLocationDistance(diameter), longitudinalMeters: CLLocationDistance(diameter))
        self.largeMapView.setRegion(region, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TableReference.isHidden = true
                
        let handle = Firebase.Auth.auth().addStateDidChangeListener { (auth, user) in
            // [START_EXCLUDE]
            NSLog("logged in")
            // [END_EXCLUDE]
                        
            var currentLocation: CLLocation!

            if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() ==  .authorizedAlways)
            {
                currentLocation = self.locManager.location
                
                self.curLong = currentLocation.coordinate.longitude
                self.curLat = currentLocation.coordinate.latitude
                
                self.materialMapView()
            
                if(user != nil) {
                    self.db.collection("users").document((user?.email)!).collection("maps")
                    .addSnapshotListener { querySnapshot, error in
                
                        guard let documents = querySnapshot?.documents else {
                            print("Error fetching documents: \(error!)")
                            return
                        }
                        
                        // clear the table
                        self.list = []
                        self.vertCountList = []
                        self.latList = []
                        self.lonList = []
                        
                        let allAnnotations = self.largeMapView.annotations
                        self.largeMapView.removeAnnotations(allAnnotations)
                        
                        self.TableReference.reloadData()
                        
//                        let annotation:MKPointAnnotation = MKPointAnnotation()
//                        annotation.title = "You"
//
//                            // You can also add a subtitle that displays under the annotation such as
//                        let pos = CLLocationCoordinate2D(latitude: Double(self.curLat) as! CLLocationDegrees, longitude: Double(self.curLong) as! CLLocationDegrees)
//                        annotation.coordinate = pos
//
//                        self.largeMapView.addAnnotation(annotation)
                        
                        // get data from db
                        for data in documents {
                            let name = data["name"] as! String
                            let vertCount = data["size"] as! Int
                            let lat = data["latitude"] as! String
                            let lon = data["longitude"] as! String
                            
                            self.list.append(name)
                            self.vertCountList.append(vertCount)
                            self.latList.append(lat)
                            self.lonList.append(lon)
                            
                            let annotation:MKPointAnnotation = MKPointAnnotation()
                            annotation.title = name
                                // You can also add a subtitle that displays under the annotation such as
                            let pos = CLLocationCoordinate2D(latitude: Double(lat) as! CLLocationDegrees, longitude: Double(lon) as! CLLocationDegrees)
                            annotation.coordinate = pos

                            self.largeMapView.addAnnotation(annotation)
                        }
                        
                        //self.largeMapView.showAnnotations(self.largeMapView.annotations, animated: true)
                                                
                        // Sort by longitude and latitude
                        for x in 0..<self.list.count {         // 2
                            var y = x
                                                        
                            //while y > 0 && self.list[y] < self.list[y - 1] { // 3
                            while y > 0 && self.distance(lat1: self.curLat, lon1: self.curLong, lat2: Double(self.latList[y])!, lon2: Double(self.lonList[y])!, unit: "M") < self.distance(lat1: self.curLat, lon1: self.curLong, lat2: Double(self.latList[y-1])!, lon2: Double(self.lonList[y-1])!, unit: "M") { // 3
                                self.list.swapAt(y - 1, y)
                                self.vertCountList.swapAt(y - 1, y)
                                self.latList.swapAt(y - 1, y)
                                self.lonList.swapAt(y - 1, y)
                                y -= 1
                            }
                        }
                        
                        // Add sorted list to listview
                        self.TableReference.reloadData()
                    }
                }
            }
        }
        
        TableReference.delegate = self
        TableReference.dataSource = self
        TableReference.showsVerticalScrollIndicator = false
        TableReference.contentInset = UIEdgeInsets(top: 85, left: 0, bottom: 0, right: 0)
        
        TabBarReference.delegate = self
        TabBarReference.selectedItem = TabBarReference.items?[1]
        TabBarReference.isTranslucent = false

        if #available(iOS 13.0, *) {
            // Always adopt a light interface style.
            overrideUserInterfaceStyle = .light
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        locManager.requestWhenInUseAuthorization()
        
        self.largeMapView.showsUserLocation = false
        self.largeMapView.showsUserLocation = true
    }
    
    func deg2rad(deg:Double) -> Double {
        return deg * Double.pi / 180
    }

    func rad2deg(rad:Double) -> Double {
        return rad * 180.0 / Double.pi
    }

    func distance(lat1:Double, lon1:Double, lat2:Double, lon2:Double, unit:String) -> Double {
        let theta = lon1 - lon2
        var dist = sin(deg2rad(deg: lat1)) * sin(deg2rad(deg: lat2)) + cos(deg2rad(deg: lat1)) * cos(deg2rad(deg: lat2)) * cos(deg2rad(deg: theta))
        dist = acos(dist)
        dist = rad2deg(rad: dist)
        dist = dist * 60 * 1.1515
        if (unit == "K") {
            dist = dist * 1.609344
        }
        else if (unit == "N") {
            dist = dist * 0.8684
        }
        return dist
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(viewMapTouched) {
            let viewmapVC = segue.destination as! MapViewController
            viewmapVC.mapSelected = self.mapNameSelected
            viewMapTouched = false
        }
        else if(loadMapTouched) {
            let loadmapVC = segue.destination as! LoadMapViewController
            loadmapVC.mapSelected = self.mapNameSelected
            loadMapTouched = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      // [START remove_auth_listener]
        //Firebase.Auth.auth().removeStateDidChangeListener(handle!)
        //dismiss(animated: true, completion: nil)

      // [END remove_auth_listener]
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


protocol MyCustomCellDelegator {
    func callSegueFromCell(myData dataobject: String)
}

protocol MyCustomCellDelegator2 {
    func callSegueFromCell2(myData dataobject: String)
}
