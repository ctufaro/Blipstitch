//
//  REST.swift
//  Blipstitch
//
//  Created by Christopher Tufaro on 9/16/20.
//  Copyright © 2020 Christopher Tufaro. All rights reserved.
//

import Foundation
import Alamofire
import UIKit

class RestAPI{
    static func UploadVideo(fileURL:URL, imageUrl:URL, completion: @escaping ()->Void, working: @escaping (Double)->Void) {
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(Data("1".utf8), withName: "UserId")
            multipartFormData.append(Data("blipstitch post".utf8), withName: "Title")
            multipartFormData.append(fileURL, withName: "Motion")
            multipartFormData.append(imageUrl, withName: "Image")
        } , to: "https://kickshowapi.azurewebsites.net/api/userpost")
        .uploadProgress { progress in
            print("Upload Progress: \(progress.fractionCompleted)")
            if progress.fractionCompleted==1{
                completion()
            } else {
                working(progress.fractionCompleted)
            }
        }
        .responseDecodable(of: HTTPBinResponse.self) { response in
            debugPrint(response)
        }
    }
}

struct HTTPBinResponse: Decodable { let url: String }
