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
            } else {
                Text("Choose a photo")
                    .foregroundColor(.gray)
                    .frame(width: 150, height: 150)
                    .background(Color(UIColor.systemFill))
                    .padding(.top, 20)
            }

            Button(action: {
                isImagePickerPresented = true
            }) {
                Text("Upload Image")
                    .padding()
                    .background(.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.vertical, 10)
        }
    }
}
