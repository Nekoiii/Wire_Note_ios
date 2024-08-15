import SwiftUI

struct TextToMusicPage: View {
    @StateObject private var viewModel = TextToMusicViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Group {
                generateModePicker
                generateFields
                generatemMusicButton
                InstrumentalToggleView(isMakeInstrumental: $viewModel.isMakeInstrumental)
                GeneratedAudioView(generatedAudioUrls: $viewModel.generatedAudioUrls)
            }
            .padding(.horizontal)
        }
    }

    private var generateModePicker: some View {
        Picker("Generate Mode", selection: $viewModel.generateMode) {
            Text("Generate").tag(GenerateMode.generate)
            Text("Custom Generate").tag(GenerateMode.customGenerate)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.vertical, 10)
    }

    private var generateFields: some View {
        Group {
            TextField("Enter \(viewModel.generateMode == .customGenerate ? "lyrics" : "prompt")", text: $viewModel.prompt)
            if viewModel.generateMode == .customGenerate {
                TextField("Enter style", text: $viewModel.style)
                TextField("Enter title", text: $viewModel.title)
            }
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
