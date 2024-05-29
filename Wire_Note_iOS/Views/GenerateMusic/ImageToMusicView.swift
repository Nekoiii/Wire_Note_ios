import SwiftUI

struct ImageToMusicView: View {
    @State private var image: UIImage?
    @State private var isImagePickerPresented = false
    
    @State private var description: String = ""
    @State private var errorMessage: String?
    @State private var isLoadingDescription: Bool = false
    
    @State private var isMakeInstrumental: Bool = false
    @State private var generatedAudioUrls: [String] = []
    
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
            let isDescribeImageButtonDisable = image == nil
            Button(action: {generateImageDescribtion()}) {
                Text("Describe Image")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"),isDisable:isDescribeImageButtonDisable))
            .disabled(isDescribeImageButtonDisable)
            
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
            Button(action:{generateMusicWithDescription()}){
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
    
    private func generateImageDescribtion() {
        isLoadingDescription = true
        
        guard let image = image, let imageData = image.pngData() else {
            errorMessage = "No image selected."
            return
        }
        
        describeImage(imageData: imageData) { result in
            switch result {
            case .success(let description):
                DispatchQueue.main.async {
                    self.description = description
                    isLoadingDescription = false
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    

    private func generateMusicWithDescription(){
        let generatePrompt = description
        let generateIsMakeInstrumental = isMakeInstrumental
        let generateMode = GenerateMode.generate

        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)

        sunoGenerateAPI.generatemMusic(generateMode:generateMode, prompt: generatePrompt,  makeInstrumental: generateIsMakeInstrumental) { audioUrls in
            DispatchQueue.main.async {
                self.generatedAudioUrls = audioUrls
            }
        }
    }
}

struct ImageToMusicView_Previews: PreviewProvider {
    static var previews: some View {
        ImageToMusicView()
    }
}
