import SwiftUI

struct DescribeImageView: View {
    @State private var description: String = "Loading..."
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            Image("icon-1")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                Text(description)
                    .padding()
            }
            Button(action: loadImageAndDescribe) {
                Text("Describe Image")
            }
        }
        .onAppear(perform: loadImageAndDescribe)
    }
    
    private func loadImageAndDescribe() {
        if let image = UIImage(named: "icon-1"), let imageData = image.pngData() {   
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
        } else {
            errorMessage = "Failed to load image from assets."
        }
    }
}

struct DescribeImageView_Previews: PreviewProvider {
    static var previews: some View {
        DescribeImageView()
    }
}
