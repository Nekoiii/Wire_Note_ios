import SwiftUI

struct TextToMusicPage: View {
    static let pageTitle: String = "Text To Music"
    @StateObject private var viewModel = TextToMusicViewModel()

    @State private var isGenerateButtonDisable = true

    var body: some View {
        VStack(spacing: 20) {
            GenerateModePicker(selectedMode: $viewModel.generateMode)

            ScrollView {
                InstrumentalToggleView(isMakeInstrumental: $viewModel.isMakeInstrumental)
                generateFields
            }.padding(.horizontal, 20)

            GeneratedAudioView(generatedAudioUrls: $viewModel.generatedAudioUrls)
            GenerateMusicButton(isDisable: $isGenerateButtonDisable,
                                generatedAudioUrls: $viewModel.generatedAudioUrls,
                                loadingState: $viewModel.loadingState,
                                prompt: viewModel.prompt,
                                style: viewModel.style,
                                title: viewModel.title,
                                isMakeInstrumental: viewModel.isMakeInstrumental,
                                generateMode: viewModel.generateMode)
        }
        .onAppear {
            if EnvironmentConfigs.debugMode {
                viewModel.generatedAudioUrls = DemoFiles.audioUrls
            }
        }
        .onChange(of: [viewModel.prompt, viewModel.style, viewModel.title]) {
            isGenerateButtonDisable = viewModel.prompt.isEmpty && viewModel.style.isEmpty && viewModel.title.isEmpty
        }
        .navigationTitle(Self.pageTitle)
    }

    private var generateFields: some View {
        Group {
            if viewModel.generateMode == .customGenerate {
                GenerateTitleTextField(title: $viewModel.title)
                GenerateStyleTextField(style: $viewModel.style)
            }
            GeneratePromptTextField(prompt: $viewModel.prompt, generateMode: viewModel.generateMode)
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding(.vertical, 5)
    }
}

struct TextToMusicPage_Previews: PreviewProvider {
    static var previews: some View {
        TextToMusicPage()
    }
}
