import SwiftUI

struct ImageToMusicPage: View {
    @State private var image: UIImage?
    @State private var isImagePickerPresented = false
    
    @State private var description: String = ""
    @State private var errorMessage: String?
    @State private var isLoadingDescription: Bool = false
    
    @State private var isMakeInstrumental: Bool = false
    @State private var generatedAudioUrls: [URL] = []
    
    var body: some View {
        VStack {
            ImagePickerView(image: $image, isImagePickerPresented: $isImagePickerPresented)
            imageDescribtion
            musicGeneration
            GeneratedAudioView(generatedAudioUrls: $generatedAudioUrls)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $image)
        }
        .onChange(of: image) {
            if let newImage = image {
                saveImageToDefaultPath(image: newImage)
            }
        }
    }
    
    private var imageDescribtion: some View {
        Group{
            let isImageToTextButtonDisable = image == nil
            Button(action: {doImageToText()}) {
                Text("Describe Image")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"),isDisable:isImageToTextButtonDisable))
            .disabled(isImageToTextButtonDisable)
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                Text(isLoadingDescription ? "Loading ..." :description)
                    .padding()
            }
        }
    }
    
    private var musicGeneration: some View {
        Group{
            let isGenerateMusicButtonDisable = description.isEmpty
            Button(action:{
                Task{
                    await generateMusicWithDescription()
                }
            }){
                Text("Generate music with image description")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"),isDisable:isGenerateMusicButtonDisable))
            .disabled(isGenerateMusicButtonDisable)
            
            InstrumentalToggleView(isMakeInstrumental:$isMakeInstrumental)
            .padding()
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
    
    private func doImageToText() {
        isLoadingDescription = true
        
        guard let image = image, let imageData = image.pngData() else {
            errorMessage = "No image selected."
            return
        }
        
        imageToText(imageData: imageData) { result in
            switch result {
            case .success(let description):
                DispatchQueue.main.async {
                    self.description = description
                    self.errorMessage = nil
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
            isLoadingDescription = false
        }
    }
    

    private func generateMusicWithDescription() async {
        let generatePrompt = description
        let generateIsMakeInstrumental = isMakeInstrumental
        let generateMode = GenerateMode.generate

        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)

        let audioUrls = await   sunoGenerateAPI.generatemMusic(generateMode:generateMode, prompt: generatePrompt,  makeInstrumental: generateIsMakeInstrumental)
        self.generatedAudioUrls = audioUrls
        
    }
}

struct ImageToMusicPage_Previews: PreviewProvider {
    static var previews: some View {
        ImageToMusicPage()
    }
}
