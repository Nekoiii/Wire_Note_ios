import SwiftUI
 import AVKit

 struct VideoToMusicPage: View {
     //    @State private var videoUrl: URL?
     @State private var videoUrl: URL? = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Videos/sky-1.dataset/sky-1.MOV")
     @State private var extractedFrames: [UIImage] = []

     @State private var isPickerPresented = false
     @State private var isLoading: Bool = false

     @State private var selectedImage: UIImage? = nil
     @State private var isImageViewerPresented = false

     @State private var description: String = ""

     @State private var isMakeInstrumental: Bool = false
     @State private var generatedAudioUrls: [URL] = []

     var body: some View {
         VStack{

             //            Button("Upload Video") {
             //                isPickerPresented = true
             //            }
             //            .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
             //            .padding()


             //        .sheet(isPresented: $isPickerPresented, onDismiss: setupPlayer) {
             //            VideoPicker(videoURL: $originVideoURL)
             //        }

             Text("videoUrl: \(videoUrl?.absoluteString ?? "")")
             let isVideoUrlNil = videoUrl == nil
             Button(action: {doextractRandomFrames() }) {
                 Text("Extract Frames")
             }
             .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isVideoUrlNil))
             .disabled(isVideoUrlNil)

             if isLoading {
                 ProgressView("Extracting frames...")
             }
             if !extractedFrames.isEmpty {
                 ScrollView {
                     LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                         ForEach(extractedFrames, id: \.self) { frame in
                             Image(uiImage: frame)
                                 .resizable()
                                 .scaledToFit()
                                 .frame(height: 100)
                                 .onTapGesture {
                                     selectedImage = frame
                                     print("onTapGesture -- Selected Image: \(selectedImage!)")
                                     isImageViewerPresented = true
                                 }
                         }
                     }
                 }
             } else {
                 Text("No frames extracted")
             }


             let isExtractedFramesEmpty = extractedFrames.isEmpty
             Button(action:{doImageToText()}){
                 Text("Describe Image")
             }
             .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"),isDisable:isExtractedFramesEmpty))
             .disabled(isExtractedFramesEmpty)

             if !description.isEmpty{
                 Text("Descriptions: \(description)")
             }

             musicGeneration
             GeneratedAudioView(generatedAudioUrls: $generatedAudioUrls)

         }
         .sheet(isPresented: $isImageViewerPresented) {//*problem
             //            if selectedImage == nil{
             //                Text("zzz")}
             if let selectedImage = selectedImage {
                 ImageViewer(image: selectedImage)
             } else {
                 Text("No Image Selected")
             }
         }
     }

     //*unfinished: need to be refactor with same function in ImageToMusicPage.swift
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
     private func generateMusicWithDescription() async {
         let generatePrompt = description
         let generateIsMakeInstrumental = isMakeInstrumental
         let generateMode = GenerateMode.generate

         let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)

         let audioUrls = await   sunoGenerateAPI.generatemMusic(generateMode:generateMode, prompt: generatePrompt,  makeInstrumental: generateIsMakeInstrumental)
         self.generatedAudioUrls = audioUrls

     }

     private func doImageToText(){
         isLoading = true

         for image in extractedFrames {
             guard let imageData = image.pngData() else {
                 print("doImageToText - no imageData")
                 return
             }
             //            print("imageData: \(imageData)")
             imageToText(imageData: imageData) { result in
                 switch result {
                 case .success(let desc):
                     DispatchQueue.main.async {
                         if self.description.isEmpty {
                             self.description += desc
                         } else {
                             self.description += ". " + desc
                         }
                     }
                 case .failure(let error):
                     DispatchQueue.main.async {
                         print("doImageToText - error: \(error.localizedDescription)")
                     }
                 }
                 isLoading = false

                 if self.description.count > 150 {
                     self.description = String(self.description.prefix(150))
                 }
             }
         }
     }

     private func doextractRandomFrames(){
         guard let videoUrl = videoUrl else {
             print("Video URL is nil")
             return
         }
         description = ""
         isLoading = true
         extractRandomFrames(from: videoUrl, frameCount: 5) { extractedFrames in
             self.extractedFrames = extractedFrames
             self.isLoading = false
         }
     }
 }

 struct VideoToMusicPage_Previews: PreviewProvider {
     static var previews: some View {
         VideoToMusicPage()
     }
 }
