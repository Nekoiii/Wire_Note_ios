import SwiftUI

struct TitleBar: View {
    var title: String

    var body: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.black)

            Text(title)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 5)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(.black)
        }
        .padding()
    }
}

struct TitleBar_Previews: PreviewProvider {
    static var previews: some View {
        TitleBar(title: "The Title")
    }
}
