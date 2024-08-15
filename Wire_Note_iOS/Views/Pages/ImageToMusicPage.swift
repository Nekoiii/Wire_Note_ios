import SwiftUI

struct ImageToMusicPage: View {
    @StateObject private var viewModel = ImageToMusicViewModel()

    var body: some View {
        VStack {
            ImagePickerView(image: $viewModel.image, isImagePickerPresented: $viewModel.isImagePickerPresented)
            imageDescribtion
            musicGeneration
            GeneratedAudioView(generatedAudioUrls: $viewModel.generatedAudioUrls)
        }
        .sheet(isPresented: $viewModel.isImagePickerPresented) {
            ImagePicker(image: $viewModel.image)
        }
        .onChange(of: viewModel.image) {
            if let newImage = viewModel.image {
                viewModel.saveImageToDefaultPath(image: newImage)
            }
        }
    }

    private var imageDescribtion: some View {
        Group {
            let isImageToTextButtonDisable = viewModel.image == nil
            Button(action: { viewModel.doImageToText() }) {
                Text("Describe Image")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isImageToTextButtonDisable))
            .disabled(isImageToTextButtonDisable)

            if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                Text(viewModel.isLoadingDescription ? "Loading ..." : viewModel.description)
                    .padding()
            }
        }
    }

    private var musicGeneration: some View {
        Group {
            let isGenerateMusicButtonDisable = viewModel.description.isEmpty
            Button(action: {
                Task {
                    await viewModel.generateMusicWithDescription()
                }
            }) {
                Text("Generate music with image description")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isGenerateMusicButtonDisable))
            .disabled(isGenerateMusicButtonDisable)

            InstrumentalToggleView(isMakeInstrumental: $viewModel.isMakeInstrumental)
                .padding()
        }
    }
}

struct ImageToMusicPage_Previews: PreviewProvider {
    static var previews: some View {
        ImageToMusicPage()
    }
}
