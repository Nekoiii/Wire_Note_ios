import SwiftUI

struct ImagePickerView: View {
    @Binding var image: UIImage?
    @Binding var isImagePickerPresented: Bool

    var body: some View {
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("Choose a photo")
                    .foregroundColor(.gray)
                    .frame(width: 150, height: 150)
                    .background(Color(UIColor.systemFill))
            }

            Button(action: {
                isImagePickerPresented = true
            }) {
                Text("Upload Image")
                    .padding()
                    .background(Color("AccentColor"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.vertical, 10)
        }
    }
}
