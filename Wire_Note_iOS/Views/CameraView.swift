//
//  CameraView.swift
//  Wire_Note_iOS
//
//  Created by John Smith on 2024/05/19.
//

import SwiftUI

struct CameraView: View {
    @StateObject var videoController = VideoController()
    @State private var img: UIImage?
    var body: some View {
        ZStack {
            if let image = img {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            VStack {
                Spacer()
                CameraControlsView()
            }
        }
        .maximize(alignment: .topLeading)
        .background(.black)
        .environmentObject(videoController)
        .onAppear {
            loadImage()
        }
    }
    
    func loadImage() {
        videoController.onFrameCaptured = { image in
            DispatchQueue.main.async {
                img = image
            }
            print("Image loaded")
        }
    }
}

#Preview {
    CameraView()
}
