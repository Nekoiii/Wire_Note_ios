import SwiftUI

struct MaximizeFrame: ViewModifier {
    let alignment: Alignment
    func body(content: Content) -> some View {
        content
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: alignment)
    }
}

extension View {
    func maximize(alignment: Alignment) -> some View {
        modifier(MaximizeFrame(alignment: alignment))
    }
}
