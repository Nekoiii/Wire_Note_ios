import AVKit
import SwiftUI

extension VideoToMusicPages {
    struct CompositeVideoPage: View {
        @EnvironmentObject var videoToMusicData: VideoToMusicData

        @State private var isDetectWire: Bool

        init(isDetectWire: Bool = true) {
            _isDetectWire = State(initialValue: isDetectWire)
        }

        var body: some View {
            VStack {
                Toggle(isOn: $isDetectWire) {
                    Text("Detect Wire")
                }
            }
            .onAppear {}
        }
    }
}
