import AVFoundation
 import UIKit

 func extractRandomFrames(from videoURL: URL, frameCount: Int, completion: @escaping ([UIImage]) -> Void) {
     let asset = AVAsset(url: videoURL)
     let generator = AVAssetImageGenerator(asset: asset)
     generator.appliesPreferredTrackTransform = true

     Task {
         do {
             let duration: CMTime = try await asset.load(.duration)
             let durationInSeconds = CMTimeGetSeconds(duration)

             // Generate a random array of time points (in chronological order)
             let times = (0..<frameCount).map { _ in CMTime(seconds: Double.random(in: 0..<durationInSeconds), preferredTimescale: 600) }.sorted(by: { $0.seconds < $1.seconds })

             var frames: [UIImage] = []
             let dispatchGroup = DispatchGroup()

             for time in times {
                 dispatchGroup.enter()
                 generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
                     if let image = image {
                         let uiImage = UIImage(cgImage: image)
                         frames.append(uiImage)
 //                        print("Image size: \(uiImage.size), scale: \(uiImage.scale), orientation: \(uiImage.imageOrientation)")
                     }
                     dispatchGroup.leave()
                 }
             }

             dispatchGroup.notify(queue: .main) {
                 print("extractRandomFrames - extracted frames : \(frames)")
                 completion(frames)
             }
         } catch {
             print("Error loading duration: \(error)")
             completion([])
         }
     }
 }
