import SwiftUI

struct GenerateMusicArea: View {
    @Binding var title: String
    @Binding var style: String
    @Binding var isGenerateMusicButtonDisable: Bool
    @Binding var generatedAudioUrls: [URL]
    @Binding var isMakeInstrumental: Bool
    @Binding var loadingState: LoadingState?
    var description: String
    var generateMode: GenerateMode

    var body: some View {
        VStack {
            Group {
                GenerateTitleTextField(title: $title)
                GenerateStyleTextField(style: $style)
            }
            .frame(maxHeight: 60)
            .padding(.vertical, 20)

            InstrumentalToggleView(isMakeInstrumental: $isMakeInstrumental)
                .padding(.vertical, 10)
                .padding(.horizontal, 5)

            GenerateMusicButton(isDisable: $isGenerateMusicButtonDisable,
                                generatedAudioUrls: $generatedAudioUrls,
                                loadingState: $loadingState,
                                prompt: description,
                                style: style,
                                title: title,
                                isMakeInstrumental: isMakeInstrumental,
                                generateMode: generateMode)
                .padding(.vertical, 5)
        }
        .padding(.horizontal, 15)
    }
}

struct GenerateMusicArea_Previews: PreviewProvider {
    @State static var title = "Sample Title"
    @State static var style = "Sample Style"
    @State static var isGenerateMusicButtonDisable = true
    @State static var generatedAudioUrls: [URL] = []
    @State static var isMakeInstrumental = false
    @State static var loadingState: LoadingState?
    static var description = "Sample Description"
    static var generateMode = GenerateMode.customGenerate

    static var previews: some View {
        GenerateMusicArea(
            title: $title,
            style: $style,
            isGenerateMusicButtonDisable: $isGenerateMusicButtonDisable,
            generatedAudioUrls: $generatedAudioUrls,
            isMakeInstrumental: $isMakeInstrumental,
            loadingState: $loadingState,
            description: description,
            generateMode: generateMode
        )
    }
}
