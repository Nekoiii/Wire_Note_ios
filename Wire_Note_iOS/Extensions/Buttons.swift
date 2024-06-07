import SwiftUI

struct PrimaryButton: ViewModifier {
    let maxWidth: Bool
    func body(content: Content) -> some View {
        if maxWidth {
            HStack {
                Spacer()
                content
                Spacer()
            }
            .padding(10)
            .foregroundColor(.white)
            .background(.blue)
            .cornerRadius(10)
        } else {
            content
                .padding(10)
                .foregroundColor(.white)
                .background(.blue)
                .cornerRadius(10)
        }
        
    }
}

struct SecondaryButton: ViewModifier {
    let maxWidth: Bool
    func body(content: Content) -> some View {
        if maxWidth {
            HStack {
                Spacer()
                content
                Spacer()
            }
            .padding(10)
            .foregroundColor(.blue)
            .background(.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.blue, lineWidth: 1)
            )
        } else {
            content
                .padding(10)
                .foregroundColor(.blue)
                .background(.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.blue, lineWidth: 1)
                )
        }
    }
}



extension View {
    func primaryButton(maxWidth: Bool = false) -> some View {
        self.modifier(PrimaryButton(maxWidth: maxWidth))
    }
    
    func secondaryButton(maxWidth: Bool = false) -> some View {
        self.modifier(SecondaryButton(maxWidth: maxWidth))
    }
}

#Preview {
    VStack {
        Button {
            
        } label: {
            Text("Primary button")
        }
        .primaryButton()
        
        Button {
            
        } label: {
            Text("Secondary button")
        }
        .secondaryButton()
    }
}
