import SwiftUI

struct ImageToMusicPage: View {
    static let pageTitle: String = "Image To Music"
    @StateObject private var viewModel = ImageToMusicViewModel()

    @State private var style: String = ""
    @State private var title: String = ""
    @State private var isImageToTextButtonDisable = true
    @State private var isGenerateMusicButtonDisable = true

    var body: some View {
        ScrollView {
            ImagePickerView(image: $viewModel.image, isImagePickerPresented: $viewModel.isImagePickerPresented)

            imageDescribtion
            generateMusicArea
            GeneratedAudioView(generatedAudioUrls: $viewModel.generatedAudioUrls)
        }
        .sheet(isPresented: $viewModel.isImagePickerPresented) {
            ImagePicker(image: $viewModel.image)
        }
        .onChange(of: viewModel.image) {
            guard let newImage = viewModel.image else {
                isImageToTextButtonDisable = true
                return
            }
            viewModel.saveImageToDefaultPath(image: newImage)
            isImageToTextButtonDisable = false
        }
        .padding(EdgeInsets(top: 30, leading: 20, bottom: 0, trailing: 20))
        .onChange(of: viewModel.description) {
            updateGenerateMusicButtonState()
        }
        .onChange(of: viewModel.loadingState) {
            updateGenerateMusicButtonState()
        }
        .navigationTitle(Self.pageTitle)
    }

    private func updateGenerateMusicButtonState() {
        isGenerateMusicButtonDisable = viewModel.description.isEmpty || viewModel.loadingState == .generate_music
    }

    private var imageDescribtion: some View {
        Group {
            Button(action: { viewModel.doImageToText() }) {
                Text("Image To Text")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isImageToTextButtonDisable))
            .disabled(isImageToTextButtonDisable)

            if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.isLoadingDescription {
                Text("Loading ...")
                    .padding()
            } else if !viewModel.description.isEmpty {
                Text(viewModel.description)
                    .padding()
            }
        }
    }

    private var generateMusicArea: some View {
        GenerateMusicArea(title: $title,
                          style: $style,
                          isGenerateMusicButtonDisable: $isGenerateMusicButtonDisable,
                          generatedAudioUrls: $viewModel.generatedAudioUrls,
                          isMakeInstrumental: $viewModel.isMakeInstrumental,
                          loadingState: $viewModel.loadingState,
                          description: viewModel.description,
                          generateMode: GenerateMode.customGenerate)
    }
}

struct ImageToMusicPage_Previews: PreviewProvider {
    static var previews: some View {
        ImageToMusicPage()
    }
}
