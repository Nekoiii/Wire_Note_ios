import AVFoundation

class VideoAudioProcessor {
    static func extractAudio(from inputURL: URL, to outputURL: URL) async throws {
        print("VideoAudioProcessor - extractAudio")

        removeExistingFile(at: outputURL)

        let asset = AVAsset(url: inputURL)
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw NSError(domain: "Audio extraction", code: -1, userInfo: [NSLocalizedDescriptionKey: "No audio track found in video"])
        }

        let composition = AVMutableComposition()
        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "Audio extraction", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio track"])
        }

        let duration = try await asset.load(.duration)
        try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: audioTrack, at: .zero)

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            throw NSError(domain: "Audio extraction", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()
        if let error = exportSession.error {
            print("extractAudio - error: \(error)")
            throw error
        }
    }

    static func addAudioToVideo(videoURL: URL, audioURL: URL, outputURL: URL) async throws {
        print("VideoAudioProcessor - combineVideoAndAudio - began")

        removeExistingFile(at: outputURL)

        let mixComposition = AVMutableComposition()

        let videoAsset = AVAsset(url: videoURL)
        let audioAsset = AVAsset(url: audioURL)

        let videoTrack = try await loadTrack(from: videoAsset, mediaType: .video)
        let audioTrack = try await loadTrack(from: audioAsset, mediaType: .audio)

        let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        let videoDuration = try await videoAsset.load(.duration)
        let audioDuration = try await audioAsset.load(.duration)
        let maxDuration = CMTimeMaximum(videoDuration, audioDuration)

        try insertTracks(videoTrack: videoTrack, audioTrack: audioTrack, videoDuration: videoDuration, audioDuration: audioDuration, videoCompositionTrack: videoCompositionTrack, audioCompositionTrack: audioCompositionTrack, maxDuration: maxDuration)

        let videoComposition = try await createVideoComposition(videoTrack: videoTrack, videoDuration: maxDuration, videoCompositionTrack: videoCompositionTrack)

        try await exportComposition(mixComposition: mixComposition, videoComposition: videoComposition, outputURL: outputURL, duration: maxDuration)

        print("VideoAudioProcessor - combineVideoAndAudio - finished")
    }

    private static func loadTrack(from asset: AVAsset, mediaType: AVMediaType) async throws -> AVAssetTrack {
        let tracks = try await asset.loadTracks(withMediaType: mediaType)
        guard let track = tracks.first(where: { $0.mediaType == mediaType }) else {
            throw NSError(domain: "Video and audio combination", code: -1, userInfo: [NSLocalizedDescriptionKey: "No \(mediaType) track found"])
        }
        return track
    }

    private static func insertTracks(videoTrack: AVAssetTrack, audioTrack: AVAssetTrack, videoDuration: CMTime, audioDuration: CMTime, videoCompositionTrack: AVMutableCompositionTrack?, audioCompositionTrack: AVMutableCompositionTrack?, maxDuration: CMTime) throws {
        var currentVideoTime = CMTime.zero
        var currentAudioTime = CMTime.zero

        while currentVideoTime < maxDuration {
            let remainingTime = CMTimeSubtract(maxDuration, currentVideoTime)
            let loopDuration = CMTimeMinimum(videoDuration, remainingTime)
            try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: loopDuration), of: videoTrack, at: currentVideoTime)
            currentVideoTime = CMTimeAdd(currentVideoTime, loopDuration)
        }

        while currentAudioTime < maxDuration {
            let remainingTime = CMTimeSubtract(maxDuration, currentAudioTime)
            let loopDuration = CMTimeMinimum(audioDuration, remainingTime)
            try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: loopDuration), of: audioTrack, at: currentAudioTime)
            currentAudioTime = CMTimeAdd(currentAudioTime, loopDuration)
        }
    }

    private static func createVideoComposition(videoTrack: AVAssetTrack, videoDuration: CMTime, videoCompositionTrack: AVMutableCompositionTrack?) async throws -> AVMutableVideoComposition {
        let transform = try await videoTrack.load(.preferredTransform)
        let videoOrientation = transform.videoOrientation()

        let videoSize = try await videoTrack.load(.naturalSize)
        let videoComposition = AVMutableVideoComposition()
        if videoOrientation == .left || videoOrientation == .right {
            videoComposition.renderSize = CGSize(width: videoSize.height, height: videoSize.width)
        } else {
            videoComposition.renderSize = videoSize
        }

        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: videoDuration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack!)
        layerInstruction.setTransform(transform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        return videoComposition
    }

    private static func exportComposition(mixComposition: AVMutableComposition, videoComposition: AVMutableVideoComposition, outputURL: URL, duration _: CMTime) async throws {
        guard let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "Video and audio combination", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition

        await exportSession.export()

        if let error = exportSession.error {
            print("combineVideoAndAudio - error: \(error)")
            throw error
        }
    }
}
