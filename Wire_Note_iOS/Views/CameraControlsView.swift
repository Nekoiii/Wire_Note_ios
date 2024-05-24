//
//  CameraControlsView.swift
//  Wire_Note_iOS
//
//  Created by John Smith on 2024/05/19.
//

import SwiftUI

struct CameraControlsView: View {
    @EnvironmentObject var videoController: VideoController
    var body: some View {
        HStack (spacing: 20) {
            Spacer()
            Button {
                videoController.flipCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
            }
            Spacer()
        }
        .font(.system(size: 26))
    }
}

#Preview {
    CameraControlsView()
        .environmentObject(VideoController())
}
