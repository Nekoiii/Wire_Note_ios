import SwiftUI

struct ImageViewer: View {
    let image: UIImage

    var body: some View {
        VStack {
            Spacer()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
            Spacer()
        }
        .background(Color.black)
        .onTapGesture {
            // Dismiss the sheet when tapped
        }
    }
}
