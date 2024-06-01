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
