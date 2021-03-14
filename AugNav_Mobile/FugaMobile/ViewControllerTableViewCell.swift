import UIKit
import MapKit

class ViewControllerTableViewCell: UITableViewCell {

    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mySubLabel: UILabel!
    
    var delegate:MyCustomCellDelegator!
    var delegate2:MyCustomCellDelegator2!
    
    @IBOutlet weak var viewBtn: UIButton!
    @IBOutlet weak var loadBtn: UIButton!
    
    var mapName = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // For adding spacing  between cells
    override var frame: CGRect {
        get {
            return super.frame
        }
        set (newFrame) {
            var frame =  newFrame
            frame.origin.y += 4
            frame.size.height -= 2 * 5
            super.frame = frame
        }
    }
    
    
    @IBAction func viewBtnClicked(_ sender: Any) {
        if(self.delegate != nil){ //Just to be safe.
            self.delegate2.callSegueFromCell2(myData: mapName)
        }
    }
    
    @IBAction func loadBtnClicked(_ sender: Any) {
        if(self.delegate != nil){ //Just to be safe.
            self.delegate.callSegueFromCell(myData: mapName)
        }
    }
}
