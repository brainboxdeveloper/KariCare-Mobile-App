//
//  NetworkManager.swift
//  kariCare-ios
//
//  Created by akhigbe benjamin on 28/05/2021.
//

import Foundation


class NetworkManager {
    private let config = URLSessionConfiguration.default
    private var session: URLSession?
    
    init() {
        session = URLSession.init(configuration: config)
        config.timeoutIntervalForRequest = 60
    }
    
    func makeRequest<T:Decodable>(requestType:RequestType, url:String, params: Dictionary<String,Any>?,   completionHandler: @escaping (Result<T,Error>)-> ()){
        
        var urlComponent = URLComponents(string: url)
        
        guard let url = urlComponent?.url else {
            completionHandler(.failure(CustomHttpError.Unknown(error: String(format: UnknownError.unknownErrorArgs, UnknownError.badUrl.rawValue))))
            return}
        var request = URLRequest(url: url)
        
        request.httpMethod = requestType.rawValue
        
        
        if let params = params {
            if requestType == .get {
                var queryItems = [URLQueryItem]()
                for (key,value) in params {
                    queryItems.append(URLQueryItem(name: key, value: "\(value)"))
                }
                urlComponent?.queryItems = queryItems
            }else {
                let requestBodyData = try? JSONSerialization.data(withJSONObject: params)
                request.httpBody = requestBodyData
            }
        }
        
        guard let session = session else {
            completionHandler(.failure(CustomHttpError.Unknown(error: String(format: UnknownError.unknownErrorArgs, UnknownError.session.rawValue))))
            return}
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            //Handle Device related error
            
            if error != nil {
                completionHandler(.failure(error!))
                return
            }
            
            //Handle Server related error
            guard let httpResponse = response as? HTTPURLResponse else {
                completionHandler(.failure(CustomHttpError.Unknown(error: String(format: UnknownError.unknownErrorArgs, UnknownError.httpResponse.rawValue))))
                return}
            
            switch httpResponse.statusCode {
            case (200...299):
                
                if !(httpResponse.mimeType == "application/json"){
                    completionHandler(.failure(CustomHttpError.NotJson))
                    return
                }else {
                    guard let data = data else {
                        completionHandler(.failure(CustomHttpError.Unknown(error: String(format: UnknownError.unknownErrorArgs, UnknownError.data.rawValue))))
                        return
                        
                    }
                    
                    completionHandler(Decoder<T>().decode(from: data))
                }
            case (400...499):
                completionHandler(.failure(CustomHttpError.BadRequest))
            case (500...599):
                completionHandler(.failure(CustomHttpError.ServerError))
            default:
                completionHandler(.failure(CustomHttpError.Unknown(error: String(format: UnknownError.unknownErrorArgs, UnknownError.unknown.rawValue))))
            }
        }
        
        task.resume()
    }
}
