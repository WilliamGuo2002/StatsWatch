import SwiftUI

struct ContentView: View {
    @State private var viewModel = PlayerViewModel()

    var body: some View {
        SearchView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
