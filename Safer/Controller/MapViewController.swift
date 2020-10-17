import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinLabel: UILabel!

    var mapIsEditing: Bool = false
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    var flickrClient: FlickrClient = FlickrClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editMap))
        deletePinLabel.isHidden = true

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(gesture:)))
        longPress.minimumPressDuration = 1.0
        self.mapView.addGestureRecognizer(longPress)
        retrieveSavedMapRegion()
        retrieveMapPins()
    }
    
    
    func retrieveMapPins() {
        do {
            let pinFetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
            let allPins = try self.delegate.dataController.context.fetch(pinFetchRequest)
            for pin in allPins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.lon)
                mapView.addAnnotation(annotation)
            }
        } catch {
            fatalError("Failed to fetch pins: \(error)")
        }
    }
    
    func retrieveSelectedPin(annotation: MKAnnotation) -> Pin? {

        let pinFetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        let predicate = NSPredicate(format: "lat == %@ AND lon == %@", argumentArray: [annotation.coordinate.latitude, annotation.coordinate.longitude])
        pinFetchRequest.predicate = predicate
        do {
            let selectedPin = try self.delegate.dataController.context.fetch(pinFetchRequest)
            return selectedPin[0]
        } catch {
            return nil
        }
    }
    
    
    @objc func dropPin(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: self.mapView)
            let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
            
            self.delegate.dataController.addPinToDatabase(lat: coordinate.latitude, lon: coordinate.longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            print("No annotation could be found")
            return
        }
        guard let selectedPin = retrieveSelectedPin(annotation: annotation) else {
            return
        }
        
        if mapIsEditing {
            self.delegate.dataController.context.delete(selectedPin)
            self.mapView.removeAnnotation(annotation)
        } else {
            let photoAlbumView = self.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            photoAlbumView.pin = selectedPin
            self.navigationController?.pushViewController(photoAlbumView, animated: true)
        }
        mapView.deselectAnnotation(annotation, animated: false)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let lat = mapView.region.center.latitude
        let lon = mapView.region.center.longitude
        let latDelta = mapView.region.span.latitudeDelta
        let lonDelta = mapView.region.span.longitudeDelta
        let regionDictionary: [String:Double] = ["lat": lat, "lon": lon, "latDelta": latDelta, "lonDelta": lonDelta]
        UserDefaults.standard.set(regionDictionary, forKey: "region")
    }
    
    
    func retrieveSavedMapRegion() {
        var mapRegion = MapRegion()
        if let savedRegion = UserDefaults.standard.object(forKey: "region") as? [String: Double] {
            mapRegion = MapRegion(from: savedRegion)
        }
        let region = mapRegion.makeMapRegion(mapRegion)
        mapView.setRegion(region, animated: true)
    }
    
    @objc func editMap(_ sender: UIBarButtonItem) {
        if mapIsEditing {
            sender.title = "Edit"
            deletePinLabel.isHidden = true
            mapIsEditing = false
        } else {
            sender.title = "Done"
            deletePinLabel.isHidden = false
            mapIsEditing = true
        }
    }
}
