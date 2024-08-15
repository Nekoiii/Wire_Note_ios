import SwiftUI

class ImageToMusicViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isImagePickerPresented = false

    @Published var description: String = ""
    @Published var errorMessage: String?
    @Published var isLoadingDescription: Bool = false

    @Published var isMakeInstrumental: Bool = false
    @Published var generatedAudioUrls: [URL] = []

    private let sunoGenerateAPI = SunoGenerateAPI()

    func doImageToText() {
        isLoadingDescription = true

        guard let image = image, let imageData = image.pngData() else {
            errorMessage = "No image selected."
            return
        }

        imageToText(imageData: imageData) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(description):
                    self.description = description
                    self.errorMessage = nil
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                }
            }
            self.isLoadingDescription = false
        }
    }

    func generateMusicWithDescription() async {
        let generatePrompt = description
        let generateIsMakeInstrumental = isMakeInstrumental
        let generateMode = GenerateMode.generate

        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)

        let audioUrls = await sunoGenerateAPI.generatemMusic(generateMode: generateMode, prompt: generatePrompt, makeInstrumental: generateIsMakeInstrumental)
        generatedAudioUrls = audioUrls
        Task {
            await sunoGenerateAPI.downloadAndSaveFiles(audioUrls: audioUrls)
        }
    }

    func saveImageToDefaultPath(image: UIImage) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("uploaded_image.png")

        if let imageData = image.pngData() {
            do {
                try imageData.write(to: fileURL)
                print("Image save at: \(fileURL.path)")
            } catch {
                print("Save image error: \(error)")
            }
        }
    }
}
