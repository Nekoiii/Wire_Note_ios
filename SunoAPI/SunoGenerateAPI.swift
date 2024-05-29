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
    
    func generatemMusic( generateMode: GenerateMode,prompt: String, tags: String = "", title: String = "", makeInstrumental: Bool = true, waitAudio: Bool = true, completion: @escaping ([String]) -> Void) {
        guard let url = URL(string: apiUrl) else {
            print("Invalid URL")
            completion([])
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
            completion([])
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error)")
                completion([])
                return
            }
            
            guard let data = data, !data.isEmpty else {
                print("No data returned from API")
                completion([])
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            } else {
                print("Unable to convert data to string")
            }
            
            do {
                let responses = try JSONDecoder().decode([SunoResponse].self, from: data)
                let audioUrls = self.extractAudioUrlsFromResponse(sunoGenerateResponses: responses, error: error)
                completion(audioUrls)
            } catch let jsonError {
                print("JSON decoding error: \(jsonError)")
                completion([])
            }
        }
        task.resume()
    }
    
    
    func extractAudioUrlsFromResponse(sunoGenerateResponses: [SunoResponse]?, error: Error?) -> [String] {
        var generatedAudioUrls: [String]
        if let error = error {
            print("Error generating audio: \(error)")
            generatedAudioUrls = ["Error generating audio"]
        } else if let responses = sunoGenerateResponses{
            generatedAudioUrls = responses.compactMap { $0.audioUrl }
            if generatedAudioUrls.isEmpty {
                generatedAudioUrls = ["No audio URL found"]
            }
            for url in generatedAudioUrls {
                print("Generated Audio: \(url)")
            }
        } else {
            generatedAudioUrls = ["No audio generated"]
        }
        return generatedAudioUrls
    }
}
