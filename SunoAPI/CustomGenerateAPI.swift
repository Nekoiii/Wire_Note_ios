import Foundation

struct CustomGenerateResponse: Codable {
    let id: String
    let title: String?
    let imageUrl: String?
    let lyric: String?
    let audioUrl: String?
    let videoUrl: String?
    let createdAt: String?
    let modelName: String?
    let status: String?
    let gptDescriptionPrompt: String?
    let prompt: String?
    let type: String?
    let tags: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageUrl = "image_url"
        case lyric
        case audioUrl = "audio_url"
        case videoUrl = "video_url"
        case createdAt = "created_at"
        case modelName = "model_name"
        case status
        case gptDescriptionPrompt = "gpt_description_prompt"
        case prompt
        case type
        case tags
    }
}

class CustomGenerateAPI {
    private let apiUrl = "http://192.168.0.209:3001/api/custom_generate" //*unfinished :use https。https://suno.gcui.art/api/custom_generate

    func generateCustomAudio(prompt: String, tags: String, title: String, makeInstrumental: Bool, waitAudio: Bool, completion: @escaping ([CustomGenerateResponse]?, Error?) -> Void) {
        guard let url = URL(string: apiUrl) else {
            print("Invalid URL")
            completion(nil, NSError(domain: "InvalidURL", code: -1000, userInfo: nil))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "accept")

        let parameters: [String: Any] = [
            "prompt": prompt,
            "tags": tags,
            "title": title,
            "make_instrumental": makeInstrumental,
            "wait_audio": waitAudio
        ]

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
                let customGenerateResponses = try JSONDecoder().decode([CustomGenerateResponse].self, from: data)
                completion(customGenerateResponses, nil)
            } catch let jsonError {
                print("JSON decoding error: \(jsonError)")
                completion(nil, jsonError)
            }
        }
        task.resume()
    }
}
