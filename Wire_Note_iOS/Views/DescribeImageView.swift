import SwiftUI

struct DescribeImageView: View {
    @State private var image: UIImage?
    @State private var isImagePickerPresented = false
    
    @State private var description: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("Choose a photo")
                    .foregroundColor(.gray)
                    .frame(width: 300, height: 300)
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
            
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                Text(description)
                    .padding()
            }
            
            Button(action: {loadImageAndDescribe()}) {
                Text("Describe Image")
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(image == nil ? Color("gray3"):Color("AccentColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(image == nil ? Color("gray3"):Color("AccentColor"), lineWidth: 2)
                    )
            }
            .disabled(image == nil)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $image)
        }
        .onChange(of: image) {
            if let newImage = image {
                saveImageToDefaultPath(image: newImage)
            }
        }
    }
    
    func saveImageToDefaultPath(image: UIImage) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("uploaded_image.png")
        
        if let imageData = image.pngData() {
            do {
                try imageData.write(to: fileURL)
                print("Image save at: \(fileURL.path)")
            } catch {
                print("Save image error: \(error)")
            }
        }
    }
    
    private func loadImageAndDescribe() {
        description = "Loading..."
        
        guard let image = image, let imageData = image.pngData() else {
            errorMessage = "No image selected."
            return
        }
        
        describeImage(imageData: imageData) { result in
            switch result {
            case .success(let description):
                DispatchQueue.main.async {
                    self.description = description
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct DescribeImageView_Previews: PreviewProvider {
    static var previews: some View {
        DescribeImageView()
    }
}
