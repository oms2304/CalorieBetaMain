import SwiftUI

struct FavoriteDetail: View {
    @Bindable var favorite: Favorite
    let isNew: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    init(favorite: Favorite, isNew: Bool = false) {
        self.favorite = favorite
        self.isNew = isNew
    }
    
    var body: some View {
        Form {
            TextField("\(favorite.name)", text: $favorite.name)
            
            
        }
        .navigationTitle(isNew ? "New Favorite Exercise" : "Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        context.delete(favorite)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FavoriteDetail(favorite: sampleFavs.shared.favorite)
    }
}

#Preview("New Favorite") {
    NavigationStack {
        FavoriteDetail(favorite: sampleFavs.shared.favorite)
    }
}
