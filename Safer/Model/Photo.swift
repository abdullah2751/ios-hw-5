import Foundation
import CoreData


public class Photo: NSManagedObject {

    convenience init(url: String, image: Data? = nil, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.url = url
            self.image = image as NSData?
        } else {
            fatalError("Unable to find Photo Entity!")
        }
    }
}

extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var image: NSData?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?

}
