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
    
    func generatemMusic( generateMode: GenerateMode,prompt: String, tags: String = "", title: String = "", makeInstrumental: Bool = true, waitAudio: Bool = true) async -> [URL]{
        guard let url = URL(string: apiUrl) else {
            print("Invalid URL")
            return []
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
            return []
        }
        
        let session = URLSession.shared
        do{
            let (data, _) = try await session.data(for: request)
            
            guard !data.isEmpty else {
                print("No data returned from API")
                return []
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            } else {
                print("Unable to convert data to string")
            }
            
            do {
                let responses = try JSONDecoder().decode([SunoResponse].self, from: data)
                let audioUrls = self.extractAudioUrlsFromResponse(responses: responses)
                
                Task {
                    await self.downloadAndSaveFiles(audioUrls: audioUrls)
                }
                
                return(audioUrls)
                
            } catch {
                print("JSON decoding error: \(error)")
                return []
            }
        } catch {
            print("Request error: \(error)")
            return []
        }
    }
    
    
    func extractAudioUrlsFromResponse(responses: [SunoResponse]?) -> [URL] {
        var generatedAudioUrls: [URL] = []
        if let responses = responses{
            generatedAudioUrls = responses.compactMap {
                guard let urlString = $0.audioUrl else { return nil }
                return URL(string: urlString)
            }
            
            if generatedAudioUrls.isEmpty {
                print("No audio URL found")
            }
            for url in generatedAudioUrls {
                print("Generated Audio: \(url)")
            }
        } else {
            print("No audio generated")
        }
        return  generatedAudioUrls
    }
    
    private func downloadAndSaveFiles(audioUrls: [URL]) async {
        var localUrls: [URL] = []
        for audioUrl in audioUrls {
            if let localUrl = await downloadAndSaveFile(from: audioUrl) {
                localUrls.append(localUrl)
            }
        }
        print("Files downloaded: \(localUrls)")
    }
}
