import UIKit
import MapKit
import CoreData
import SystemConfiguration

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    // MARK: - Properties
    
    var pin: Pin!
    
    var isEditingPhotoAlbum: Bool = false
    
    // API call
    var flickrClient = FlickrClient()
    
    // fetched results controller
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = { () -> NSFetchedResultsController<Photo> in
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        let predicate = NSPredicate(format: "pin = %@", argumentArray: [self.pin!])
        fetchRequest.predicate = predicate
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.delegate.dataController.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    var selectedIndexes = [IndexPath]()
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    
    var activityIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noImagesLabel.isHidden = true
        addActivityIndicator()
        fitCollectionFlowToSize(self.view.frame.size)
        createMap()
        do {
            try fetchedResultsController.performFetch()
            if self.fetchedResultsController.fetchedObjects?.count == 0 {
                fetchImages()
            }
        } catch {
            print("Error performing initial fetch for album photos.")
        }
    }
    
    func configureButton() {
        if isEditingPhotoAlbum {
            collectionButton.setTitle("Remove Selected Pictures", for: .normal)
        } else {
            collectionButton.setTitle("New Collection", for: .normal)
        }
    }
    
    func createMap() {
        let mapRegionDict = ["lat": pin.lat, "lon": pin.lon, "latDelta": 0.25, "lonDelta": 0.25]
        let mapRegion = MapRegion(from: mapRegionDict)
        let region = mapRegion.makeMapRegion(mapRegion)
        mapView.setRegion(region, animated: true)
    
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(pin.lat, pin.lon)
        self.mapView.addAnnotation(annotation)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func configureCell(_ cell: PhotoViewCell, atIndexPath indexPath: IndexPath) {
        if let _ = selectedIndexes.firstIndex(of: indexPath) {
            cell.imageView.alpha = 0.5
            self.isEditingPhotoAlbum = true
        } else {
            cell.imageView.alpha = 1.0
            self.isEditingPhotoAlbum = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoViewCell", for: indexPath) as! PhotoViewCell
        
        if self.fetchedResultsController.fetchedObjects?.count != 0 {
            let photo = self.fetchedResultsController.object(at: indexPath) as Photo
            if photo.image != nil {
                let photo = UIImage(data: photo.image! as Data)
                cell.update(with: photo)
            } else {
                flickrClient.fetchImage(for: photo) { (data: Data?) -> Void in
                    guard let imageData = data, let image = UIImage(data: imageData) else {
                        print("Image data could not be extracted")
                        return
                    }
                    let photoIndexPath = IndexPath(item: indexPath.row, section: 0)
                    if let cell = self.collectionView.cellForItem(at: photoIndexPath)
                        as? PhotoViewCell {
                        cell.update(with: image)
                    }
                }
            }
        }
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoViewCell

        if let index = selectedIndexes.firstIndex(of: indexPath) {
            selectedIndexes.remove(at: index)
        } else {
            selectedIndexes.append(indexPath)
        }
        configureCell(cell, atIndexPath: indexPath)
        configureButton()
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
        case .move:
            // No actions
            break
        @unknown default:
            fatalError("No actions possible")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
        }, completion: nil)
    }
    
    // MARK: - Fetch Images from Flickr
    
    func fetchImages() {
        activityIndicator.startAnimating()
        collectionButton.isEnabled = false

        flickrClient.fetchImagesWithLatitudeAndLongitude(lat: pin.lat, lon: pin.lon) { (data: AnyObject?, error: NSError?) -> Void in
            if error != nil {
                print("There was an error getting the images: \(String(describing: error))")
                self.activityIndicator.stopAnimating()
                if isInternetAvailable() == false {
                    self.showAlert(message: "Internet is not available", title: "Error")
                } else {
                    self.showAlert(message: "There was an error while getting the images.", title: "Error")
                }
                self.collectionButton.isEnabled = true
            } else {
                guard let data = data else {
                    print("No data was returned.")
                    return
                }
                let photoURLs = self.flickrClient.extractAllPhotoURLStrings(fromJSONDictionary: data)
                
                if !photoURLs.isEmpty {
                    print("There were \(photoURLs.count) photos returned.")
                    for url in photoURLs {
                        self.delegate.dataController.addFlickrPhotoToDatabase(url: url, pin: self.pin, fetchedResultsController: self.fetchedResultsController)
                        self.activityIndicator.stopAnimating()
                        self.collectionButton.isEnabled = true
                    }
                } else {
                    self.noImagesLabel.isHidden = false
                    self.activityIndicator.stopAnimating()
                    self.collectionButton.isEnabled = true
                }
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
            
            do {
                try self.delegate.dataController.saveContext()
            } catch {
                print("New collection changes could not be saved.")
            }
        }
    }
    
    func deleteAllPhotos() {
        for photo in self.fetchedResultsController.fetchedObjects! {
            delegate.dataController.context.delete(photo)
        }
    }
    
    func deleteSelectedFlickrPhotos() {
        var photosToDelete: [Photo] = []
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.object(at: indexPath))
        }
        for photo in photosToDelete {
            delegate.dataController.context.delete(photo)
        }
        selectedIndexes = [IndexPath]()
    }
    
    // MARK: - Import New Photos or Delete
    
    @IBAction func importNewPhotos(_ sender: Any) {
        collectionButton.isEnabled = false
        
        if isEditingPhotoAlbum {
            deleteSelectedFlickrPhotos()
            isEditingPhotoAlbum = false
            collectionButton.isEnabled = true
        } else {
            deleteAllPhotos()
            fetchImages()
        }
        configureButton()
        do {
            try self.delegate.dataController.saveContext()
        } catch {
            print("New collection changes could not be saved.")
        }
    }
    
    func addActivityIndicator() {
        self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x:0, y:0, width:100, height:100)) as UIActivityIndicatorView
        self.activityIndicator.style = UIActivityIndicatorView.Style.large
        self.activityIndicator.center = self.view.center
        self.activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // set up custom flow
        if flowLayout != nil {
            fitCollectionFlowToSize(size)
        }
    }
    
    func fitCollectionFlowToSize(_ size: CGSize) {
        // determine the number of and spacing between collection items
        let space: CGFloat = 3.0
        // adjust dimension to width and height of screen
        let dimension = size.width >= size.height ? (size.width - (5*space))/5.0 : (size.width - (2*space))/3.0
        // set up custom flow
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
}

