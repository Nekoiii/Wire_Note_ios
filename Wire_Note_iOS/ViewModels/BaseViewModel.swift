import Combine
import SwiftUI

class BaseViewModel: ObservableObject {
    @Published var loadingState: LoadingState?
}
