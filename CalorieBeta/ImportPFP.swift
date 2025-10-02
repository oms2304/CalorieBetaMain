import SwiftUI

struct ImportPFP: View {
    @State private var showingOptions = false
    @State private var selection = "None"

    var body: some View {
        VStack {
            Text(selection)

            Button("Confirm paint color") {
                showingOptions = true
            }
            .confirmationDialog("Select a color", isPresented: $showingOptions, titleVisibility: .visible) {
                Button("Red") {
                    selection = "Red"
                }

                Button("Green") {
                    selection = "Green"
                }

                Button("Blue") {
                    selection = "Blue"
                }
            }
        }
    }
}

#Preview {
    ImportPFP()
}
