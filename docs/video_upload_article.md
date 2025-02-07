Uploading files using Base64 encoding and multipart file upload in Swift involves a few steps, depending on whether you’re working with URLSession or a library like Alamofire. Here's a guide for both approaches:
1. Using Base64 Encoding for File Content
You first encode your file to Base64. This is useful for text-based uploads, but remember that Base64 increases the file size by ~33%.
import Foundation

func encodeFileToBase64(fileURL: URL) -> String? {
    do {
        let fileData = try Data(contentsOf: fileURL)
        return fileData.base64EncodedString()
    } catch {
        print("Error reading file data: \(error)")
        return nil
    }
}
2. Building Multipart Request with Base64 in URLSession
Here’s how to create and send a multipart request:
import Foundation

func uploadFileWithBase64(to url: URL, fileBase64: String, fileName: String, mimeType: String) {
    let boundary = "Boundary-\(UUID().uuidString)"
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    
    // Add Base64-encoded file part
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
    body.append(fileBase64.data(using: .utf8)!)
    body.append("\r\n".data(using: .utf8)!)
    
    // Close boundary
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = body
    
    // Send request
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error uploading file: \(error)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Upload finished with status code: \(httpResponse.statusCode)")
        }
    }
    
    task.resume()
}
3. Using Alamofire for Multipart File Upload
Alamofire simplifies multipart uploads. If you want to upload the raw file (not Base64), follow this example.
import Alamofire

func uploadFileUsingAlamofire(fileURL: URL, to url: String) {
    AF.upload(multipartFormData: { multipartFormData in
        multipartFormData.append(fileURL, withName: "file", fileName: fileURL.lastPathComponent, mimeType: "application/octet-stream")
    }, to: url).response { response in
        switch response.result {
        case .success(let data):
            print("File uploaded successfully")
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
        case .failure(let error):
            print("File upload failed: \(error)")
        }
    }
}
Thank you!!