import Foundation
import MapKit

struct MapRegion {
    
    
    var lat: Double
    var lon: Double
    var latDelta: Double
    var lonDelta: Double
    
    
    init() {
        self.lat = 45.065448
        self.lon = 7.694489
        self.latDelta = 44.065168
        self.lonDelta = 6.276014
    }
    
    init(from dictionary: [String: Double]) {
        if let lat = dictionary["lat"] {
            self.lat = lat
        } else {
            self.lat = 45.065448
        }
        if let lon = dictionary["lon"] {
            self.lon = lon
        } else {
            self.lon = 7.694489
        }
        if let latDelta = dictionary["latDelta"] {
            self.latDelta = latDelta
        } else {
            self.latDelta = 44.065168
        }
        if let lonDelta = dictionary["lonDelta"] {
            self.lonDelta = lonDelta
        } else {
            self.lonDelta = 6.276014
        }
    }
    
    
    func makeMapRegion(_ mapRegion: MapRegion) -> MKCoordinateRegion {
        let lat: CLLocationDegrees = mapRegion.lat
        let lon: CLLocationDegrees = mapRegion.lon
        let latDelta: CLLocationDegrees = mapRegion.lat
        let lonDelta: CLLocationDegrees = mapRegion.lon
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, lon)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: location, span: span)
        return region
    }
}

