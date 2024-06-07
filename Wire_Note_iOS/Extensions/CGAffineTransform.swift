import AVFoundation
import UIKit

extension CGAffineTransform {
    func videoOrientation() -> UIImage.Orientation {
        if a == 0 && b == 1.0 && c == -1.0 && d == 0 {
            return .right
        } else if a == 0 && b == -1.0 && c == 1.0 && d == 0 {
            return .left
        } else if a == 1.0 && b == 0 && c == 0 && d == 1.0 {
            return .up
        } else if a == -1.0 && b == 0 && c == 0 && d == -1.0 {
            return .down
        } else {
            return .up
        }
    }
}
