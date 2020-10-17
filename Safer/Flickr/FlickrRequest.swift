// يطلب الصور من الموقع
import Foundation

struct FlickrRequest {
    
    struct FlickrURL {
        static let Scheme: String = "https"
        static let Host: String = "api.flickr.com"
        static let Path: String = "/services/rest"
    }
    
    struct FlickrParameterKeys {
        static let Method: String = "method"
        static let APIKey: String = "api_key"
        static let Extras: String = "extras"
        static let Format: String = "format"
        static let NoJSONCallback: String = "nojsoncallback"
        static let SafeSearch: String = "safe_search"
        static let Latitude: String = "lat"
        static let Longitude: String = "lon"
        static let ResultsPerPage: String = "per_page"
        static let ResultsPage: String = "page"
    }
    
    struct FlickrParameterValues {
        static let APIKey: String = "8c86a16dd878ea1d136cfc8b1c5ae24d"
        static let SearchMethod: String = "flickr.photos.search"
        static let ResponseFormat: String = "json"
        static let DisableJSONCallback: String = "1" /* 1 means "yes" */
        static let MediumURL: String = "url_m"
        static let UseSafeSearch = "1"
        static let DesiredNumberOfResults = 21
    }
    
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let MediumURL = "url_m"
    }
    
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
    
    func buildURL(fromParameters parameters: [String: Any]?) -> URL {
        var components = URLComponents()
        components.scheme = FlickrURL.Scheme
        components.host = FlickrURL.Host
        components.path = FlickrURL.Path
        var queryItems = [URLQueryItem]()
        let baseParams: [String: Any] = [
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
            FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.ResultsPerPage: FlickrParameterValues.DesiredNumberOfResults,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback]
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: "\(value)")
            queryItems.append(item)
        }
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                queryItems.append(queryItem)
            }
        }
        components.queryItems = queryItems
        print("URL request is: \(components.url!)")
        return components.url!
    }
}

extension FlickrClient {
    
    func parseJSONDataWithCompletionHandler(_ data: Data, completionHandlerForData: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForData(nil, NSError(domain: "parseJSONDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        OperationQueue.main.addOperation {
            completionHandlerForData(parsedResult, nil)
        }
    }
    
    func extractAllPhotoURLStrings(fromJSONDictionary jsonDictionary: AnyObject) -> [String] {
        var allPhotoStrings = [String]()
        
        guard let photos = jsonDictionary[FlickrRequest.FlickrResponseKeys.Photos] as? [String: Any],
            let photosArray = photos[FlickrRequest.FlickrResponseKeys.Photo] as? [[String: Any]] else {
                print("The proper keys are not in the provided JSON array.")
                return []
        }
        
        for photoDict in photosArray {
            if let photoURLString = photoDict["url_m"] as? String {
                allPhotoStrings.append(photoURLString)
            }
        }
        return allPhotoStrings
    }
    
}

