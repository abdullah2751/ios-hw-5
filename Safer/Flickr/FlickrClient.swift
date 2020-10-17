// يطلب الصور من الموقع
import Foundation
import UIKit

class FlickrClient : NSObject {
    
    var session = URLSession.shared
    var flickrRequest = FlickrRequest()
    
    var pageRequested: Int = 0
    
    func fetchImagesWithLatitudeAndLongitude(lat: Double, lon: Double, completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        pageRequested += 1
        
        let methodParameters: [String: Any] = [
            FlickrRequest.FlickrParameterKeys.Latitude: lat,
            FlickrRequest.FlickrParameterKeys.Longitude: lon,
            FlickrRequest.FlickrParameterKeys.ResultsPage: pageRequested]

        let getRequestURL = flickrRequest.buildURL(fromParameters: methodParameters)
        
        let request = URLRequest(url: getRequestURL)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandler(nil, NSError(domain: "getImagesWithLatitudeAndLongitude", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil) else {
                sendError("Request error: \(String(describing: error))")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Request returned error which is not 2xx")
                return
            }
            
            guard let data = data else {
                sendError("No data returned from the request")
                return
            }
            
            self.parseJSONDataWithCompletionHandler(data, completionHandlerForData: completionHandler)
        }
        task.resume()
    }
    
    func fetchImage(for photo: Photo, completionHandler: @escaping (_ data: Data?) -> Void) {
        
        let photoURL = URL(string: photo.url!)
        
        let request = URLRequest(url: photoURL!)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            guard (error == nil) else {
                print("Request error: \(String(describing: error))")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Request returned error which is not 2xx")
                return
            }
            

            guard let data = data else {
                print("No data returned from the request")
                return
            }
            
            OperationQueue.main.addOperation {
                photo.image = data as NSData
                completionHandler(data)
            }
        }
        task.resume()
    }
    
}
