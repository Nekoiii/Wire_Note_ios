import Foundation

class SunoGenerateAPI {
    private let apiUrl: String
    
    init(generateMode: GenerateMode = .generate) {
        switch generateMode {
        case .customGenerate:
            self.apiUrl = "\(API.baseUrl)/api/custom_generate"
        case .generate:
            self.apiUrl = "\(API.baseUrl)/api/generate"
        }
    }
    
    func generatemMusic( generateMode: GenerateMode,prompt: String, tags: String, title: String, makeInstrumental: Bool, waitAudio: Bool, completion: @escaping ([SunoResponse]?, Error?) -> Void) {
        guard let url = URL(string: apiUrl) else {
            print("Invalid URL")
            completion(nil, NSError(domain: "InvalidURL", code: -1000, userInfo: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "accept")
        
        let parameters: [String: Any]
        
        switch generateMode {
        case .customGenerate:
            parameters = [
                "prompt": prompt,
                "tags": tags ,
                "title": title ,
                "make_instrumental": makeInstrumental,
                "wait_audio": waitAudio
            ]
        case .generate:
            parameters = [
                "prompt": prompt,
                "make_instrumental": makeInstrumental,
                "wait_audio": waitAudio
            ]
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            print("Request body: \(String(data: request.httpBody!, encoding: .utf8)!)")
        } catch {
            print("Error serializing JSON: \(error)")
            completion(nil, error)
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error)")
                completion(nil, error)
                return
            }
            
            guard let data = data, !data.isEmpty else {
                print("No data returned from API")
                completion(nil, NSError(domain: "NoData", code: -1001, userInfo: nil))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            } else {
                print("Unable to convert data to string")
            }
            
            do {
                let responses = try JSONDecoder().decode([SunoResponse].self, from: data)
                completion(responses, nil)
            } catch let jsonError {
                print("JSON decoding error: \(jsonError)")
                completion(nil, jsonError)
            }
        }
        task.resume()
    }
}
