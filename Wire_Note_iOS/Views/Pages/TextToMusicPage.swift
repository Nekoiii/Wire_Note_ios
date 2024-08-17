import SwiftUI

struct TextToMusicPage: View {
    @StateObject private var viewModel = TextToMusicViewModel()

    var body: some View {
        VStack(spacing: 20) {
            GenerateModePicker(generateMode: $viewModel.generateMode)
            ScrollView {
                InstrumentalToggleView(isMakeInstrumental: $viewModel.isMakeInstrumental)
                generateFields
                GeneratedAudioView(generatedAudioUrls: $viewModel.generatedAudioUrls)
            }.padding(.horizontal, 20)

            generatemMusicButton
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
