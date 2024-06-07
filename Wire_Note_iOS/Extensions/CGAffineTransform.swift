import UIKit
import AVFoundation

extension CGAffineTransform {
    func videoOrientation() -> UIImage.Orientation {
        if self.a == 0 && self.b == 1.0 && self.c == -1.0 && self.d == 0 {
            return .right
        } else if self.a == 0 && self.b == -1.0 && self.c == 1.0 && self.d == 0 {
            return .left
        } else if self.a == 1.0 && self.b == 0 && self.c == 0 && self.d == 1.0 {
            return .up
        } else if self.a == -1.0 && self.b == 0 && self.c == 0 && self.d == -1.0 {
            return .down
        } else {
            return .up 
        }
    }
}
