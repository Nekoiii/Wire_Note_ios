import SwiftUI

struct TextArea: View {
    @Binding var text: String
    var title: String
    var maxCharacters: Int = 200

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)

            let cornerRadius: CGFloat = 20
            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $text)
                    .padding(.vertical, 1)
                    .padding(.horizontal, 5)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxCharacters {
                            text = String(newValue.prefix(maxCharacters))
                        }
                    }
                Text("\(text.count)/\(maxCharacters)")
                    .foregroundColor(.gray)
                    .padding([.bottom, .trailing], 8)
            }
            .frame(minHeight: 150)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(cornerRadius)
        }
    }
}
