enum GenerateMode: CaseIterable {
    case generate
    case customGenerate

    var index: Int {
        GenerateMode.allCases.firstIndex(of: self) ?? 0
    }

    var title: String {
        switch self {
        case .generate:
            return "Generate"
        case .customGenerate:
            return "Custom Generate"
        }
    }
}
