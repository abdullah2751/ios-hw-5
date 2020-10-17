import Foundation
import CoreData

public class Pin: NSManagedObject {
    convenience init(lat: Double, lon: Double, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.lat = lat
            self.lon = lon
        } else {
            fatalError("Unable to find Pin Entity!")
        }
    }
}

extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }

    @NSManaged public var lat: Double
    @NSManaged public var lon: Double
    @NSManaged public var photos: NSSet?

}

// MARK: Generated accessors for flickrPhotos
extension Pin {

    @objc(addFlickrPhotosObject:)
    @NSManaged public func addToFlickrPhotos(_ value: Photo)

    @objc(removeFlickrPhotosObject:)
    @NSManaged public func removeFromFlickrPhotos(_ value: Photo)

    @objc(addFlickrPhotos:)
    @NSManaged public func addToFlickrPhotos(_ values: NSSet)

    @objc(removeFlickrPhotos:)
    @NSManaged public func removeFromFlickrPhotos(_ values: NSSet)

}
