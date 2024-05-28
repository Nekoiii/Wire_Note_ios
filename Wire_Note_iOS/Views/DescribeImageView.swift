import SwiftUI

struct DescribeImageView: View {
    @State private var image: UIImage?
    @State private var isImagePickerPresented = false
    
    @State private var description: String = ""
    @State private var errorMessage: String?
    @State private var isLoadingDescription: Bool = false
    
    @State private var makeInstrumental: Bool = false
    @State private var generatedAudioUrls: [String] = []
    
    var body: some View {
        VStack {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("Choose a photo")
                    .foregroundColor(.gray)
                    .frame(width: 300, height: 300)
                    .background(Color(UIColor.systemFill))
            }
            Button(action: {
                isImagePickerPresented = true
            }) {
                Text("Upload Image")
                    .padding()
                    .background(Color("AccentColor"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            let isDescribeImageButtonDisable = image == nil
            Button(action: {loadImageAndDescribe()}) {
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
            
            let isGenerateMusicButtonDisable = description.isEmpty
            Button(action:{generateMusicWithDescription()}){
                Text("Generate music with image description")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"),isDisable:isGenerateMusicButtonDisable))
            .disabled(isGenerateMusicButtonDisable)
            
            Toggle(isOn: $makeInstrumental) {
                Text("Make It Instrumental")
            }
            .padding()
            
            if !generatedAudioUrls.isEmpty {
                Text("Generated Audios: ")
                    .padding()
                ForEach(generatedAudioUrls, id: \.self) { AudioUrl in
                    AudioPlayerView(url:URL(string:AudioUrl)! )
                }
            }
            
            
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
    
    private func loadImageAndDescribe() {
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
        let generateTags = description //* unfinished
        let generateTitle = "Song"
        let generateMakeInstrumental = makeInstrumental
        let generateMode = GenerateMode.generate
        let waitAudio = true
        
        
        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)
        sunoGenerateAPI.generatemMusic(generateMode:generateMode, prompt: generatePrompt, tags: generateTags, title: generateTitle, makeInstrumental: generateMakeInstrumental, waitAudio: waitAudio) { sunoGenerateResponses, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error generating audio: \(error)")
                    self.generatedAudioUrls = ["Error generating audio"]
                } else if let responses = sunoGenerateResponses{
                    self.generatedAudioUrls = responses.compactMap { $0.audioUrl }
                    if self.generatedAudioUrls.isEmpty {
                        self.generatedAudioUrls = ["No audio URL found"]
                    }
                    for url in self.generatedAudioUrls {
                        print("Generated Audio: \(url)")
                    }
                } else {
                    self.generatedAudioUrls = ["No audio generated"]
                }
            }
        }
    }
}

struct DescribeImageView_Previews: PreviewProvider {
    static var previews: some View {
        DescribeImageView()
    }
}
