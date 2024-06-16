enum LoadingState {
    case load
    case upload_file
    case download_file
    case generate_music
    case extract_frames
    case image_to_text
    case composite_video

    var description: String {
        switch self {
        case .load:
            return "Loading..."
        case .upload_file:
            return "Uploading file..."
        case .download_file:
            return "Downloading file..."
        case .generate_music:
            return "Generating music..."
        case .extract_frames:
            return "Extracting frames..."
        case .image_to_text:
            return "Descriptions image..."

        case .composite_video:
            return "Compositing video..."
        }
    }
}
