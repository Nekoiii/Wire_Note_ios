import SwiftUI

struct ImageToMusicPage: View {
    @StateObject private var viewModel = ImageToMusicViewModel()

    @State private var style: String = ""
    @State private var title: String = ""
    @State private var isImageToTextButtonDisable = true
    @State private var isGenerateMusicButtonDisable = false

    var body: some View {
        ScrollView {
            ImagePickerView(image: $viewModel.image, isImagePickerPresented: $viewModel.isImagePickerPresented)

            imageDescribtion
            musicGeneration
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
        .padding([.top, .horizontal], 20)
        .onChange(of: viewModel.description) {
            isGenerateMusicButtonDisable = viewModel.description.isEmpty
        }
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

    private var musicGeneration: some View {
        Group {
            Group {
                GenerateTitleTextField(title: $title)
                GenerateStyleTextField(style: $style)
            }
            .frame(maxHeight: 60)

            InstrumentalToggleView(isMakeInstrumental: $viewModel.isMakeInstrumental)
                .padding(.horizontal, 5)

            GenerateMusicButton(isDisable: $isGenerateMusicButtonDisable,
                                generatedAudioUrls: $viewModel.generatedAudioUrls,
                                prompt: viewModel.description,
                                style: style,
                                title: title,
                                isMakeInstrumental: viewModel.isMakeInstrumental,
                                generateMode: GenerateMode.customGenerate)
        }
        .padding(.vertical, 15)
    }
}

struct ImageToMusicPage_Previews: PreviewProvider {
    static var previews: some View {
        ImageToMusicPage()
    }
}
