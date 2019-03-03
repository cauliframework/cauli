//
//  RequestModel.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 17.11.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import Foundation

protocol RequestModel {
    var name: String { get }
    var url: URL { get }
    func dataTask(in session: URLSession, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

struct DownloadRequestModel: RequestModel {
    let name: String
    let url: URL
    
    func dataTask(in session: URLSession, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return session.dataTask(with: url, completionHandler: completionHandler)
    }
}

struct UploadRequestModel: RequestModel {
    let name: String
    let url: URL
    let data: Data
    
    func dataTask(in session: URLSession, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        return session.uploadTask(with: urlRequest, from: data, completionHandler: completionHandler)
    }
}

extension UploadRequestModel {
    init(name: String, url: URL, localFileName: String) {
        let fileUrl = Bundle.main.url(forResource: localFileName, withExtension: nil)!
        let data = try! Data(contentsOf: fileUrl)
        self.init(name: name, url: url, data: data)
    }
}
