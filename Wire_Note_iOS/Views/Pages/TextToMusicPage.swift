import SwiftUI

struct TextToMusicPage: View {
    @StateObject private var viewModel = TextToMusicViewModel()

    var body: some View {
        VStack(spacing: 20) {
            GenerateModePicker(selectedMode: $viewModel.generateMode)

            ScrollView {
                InstrumentalToggleView(isMakeInstrumental: $viewModel.isMakeInstrumental)
                generateFields
                GeneratedAudioView(generatedAudioUrls: $viewModel.generatedAudioUrls)
            }.padding(.horizontal, 20)

            generateMusicButton
        }
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

    private var generateMusicButton: some View {
        Button(action: {
            Task {
                await viewModel.generateMusic()
            }
        }) {
            Text("Generate")
        }
        .buttonStyle(SolidButtonStyle(buttonColor: .accent))
    }
}

struct TextToMusicPage_Previews: PreviewProvider {
    static var previews: some View {
        TextToMusicPage()
    }
}
