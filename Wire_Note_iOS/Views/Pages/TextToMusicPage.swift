import SwiftUI

struct TextToMusicPage: View {
    @StateObject private var viewModel = TextToMusicViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Group {
                generateFields
                generatemMusicButton
                InstrumentalToggleView(isMakeInstrumental: $viewModel.isMakeInstrumental)
                GeneratedAudioView(generatedAudioUrls: $viewModel.generatedAudioUrls)
            }
            .padding(.horizontal)
        }
    }

    private var generateFields: some View {
        Group {
            GenerateModePicker(generateMode: $viewModel.generateMode)
            Group {
                GeneratePromptTextField(prompt: $viewModel.prompt, generateMode: viewModel.generateMode)
                if viewModel.generateMode == .customGenerate {
                    GenerateStyleTextField(style: $viewModel.style)
                    GenerateTitleTextField(title: $viewModel.title)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.vertical, 5)
        }
    }

    private var generatemMusicButton: some View {
        Button(action: {
            Task {
                await viewModel.generatemMusic()
            }
        }) {
            Text("Generate")
        }
        .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
    }
}

struct TextToMusicPage_Previews: PreviewProvider {
    static var previews: some View {
        TextToMusicPage()
    }
}
