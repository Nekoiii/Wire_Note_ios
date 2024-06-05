enum LoadingState {
    case load
    case upload_file
    case generate_music
    case extract_frames
    case image_to_text
    
    var description: String {
        switch self {
        case .load:
            return "Loading..."
        case .upload_file:
            return "Uploading file..."
        case .generate_music:
            return "Generating mumsic..."
        case .extract_frames:
            return "Extracting frames..."
        case .image_to_text:
            return "Descriptions image..."
        }
    }
}
