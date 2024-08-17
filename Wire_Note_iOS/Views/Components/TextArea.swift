import SwiftUI

struct TextArea: View {
    @Binding var text: String
    var title: String
    var maxCharacters: Int = 200
    var minHeight: CGFloat = UIFont.preferredFont(forTextStyle: .body).lineHeight * 2

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)

            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $text)
                    .padding(.top, 4)
                    .padding(.horizontal, 7)
                    .frame(minHeight: minHeight)
                    .padding(.bottom, minHeight / 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxCharacters {
                            text = String(newValue.prefix(maxCharacters))
                        }
                    }
                Text("\(text.count)/\(maxCharacters)")
                    .foregroundColor(.gray)
                    .padding([.bottom, .trailing], 8)
            }
        }
    }
}
