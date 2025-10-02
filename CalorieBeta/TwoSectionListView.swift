import SwiftUI

// MARK: - Main View
struct TwoSectionListView: View {
    // Sample data for the list
    let fruits = ["Apple", "Banana", "Cherry", "Grape"]
    let vegetables = ["Carrot", "Broccoli", "Spinach", "Pepper"]
    
    var body: some View {
        // Use a NavigationStack to give the list a title bar
        NavigationStack {
            // A List is a container that presents rows of data.
            List {
                // MARK: - First Section
                // A Section groups related content and can have a header.
                Section(header: Text("Fruits").font(.headline)) {
                    // ForEach creates views from a collection of data.
                    ForEach(fruits, id: \.self) { fruit in
                        // Each row in the section
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(.green)
                            Text(fruit)
                        }
                    }
                }
                
                // MARK: - Second Section
                // This creates the second distinct section in the list.
                Section(header: Text("Vegetables").font(.headline)) {
                    ForEach(vegetables, id: \.self) { vegetable in
                        // Each row in the second section
                        HStack {
                            Image(systemName: "leaf")
                                .foregroundStyle(.orange)
                            Text(vegetable)
                        }
                    }
                }
            }
            .navigationTitle("Groceries") // Title for the navigation bar
        }
    }
}

// MARK: - Preview
// The #Preview block allows Xcode to render a live preview of the view.
#Preview {
    TwoSectionListView()
}

