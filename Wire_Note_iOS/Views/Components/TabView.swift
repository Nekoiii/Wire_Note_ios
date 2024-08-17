import SwiftUI

struct TabView<Content: View>: View {
    @Binding var selectedIndex: Int
    var tabs: [String]
    var content: Content
    var tabHeight: CGFloat = 60

    init(selectedIndex: Binding<Int>, tabs: [String], @ViewBuilder content: () -> Content) {
        _selectedIndex = selectedIndex
        self.tabs = tabs
        self.content = content()
    }

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                ForEach(0 ..< tabs.count, id: \.self) { index in
                    TabButton(title: tabs[index], tabHeight: tabHeight, isSelected: selectedIndex == index) {
                        selectedIndex = index
                    }

                    if index < tabs.count - 1 {
                        Divider()
                            .frame(width: 1, height: tabHeight)
                            .background(Color.gray3)
                    }
                }
            }
            .background(Color.white)

            content
                .padding()
        }
    }
}

struct TabButton: View {
    var title: String
    var tabHeight: CGFloat
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Text(title)
                    .frame(maxWidth: .infinity, minHeight: tabHeight)
                    .foregroundColor(isSelected ? .accent : .gray)
                Rectangle()
                    .fill(isSelected ? .gray : .clear)
                    .frame(height: 2)
            }
        }
    }
}

struct ExampleUsageView: View {
    @State private var selectedIndex = 0

    var body: some View {
        TabView(selectedIndex: $selectedIndex, tabs: ["Tab 1", "Tab 2", "Tab 3"]) {
            if selectedIndex == 0 {
                Text("Content for Tab 1")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if selectedIndex == 1 {
                Text("Content for Tab 2")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Content for Tab 3")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
}

struct TabView_Previews: PreviewProvider {
    static var previews: some View {
        ExampleUsageView()
            .previewLayout(.sizeThatFits)
    }
}
