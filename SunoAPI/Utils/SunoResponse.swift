struct SunoResponse: Codable {
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
