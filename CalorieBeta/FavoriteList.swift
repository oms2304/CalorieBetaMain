import SwiftUI
import SwiftData

struct FavoriteList: View {
    @Query(sort: \Favorite.name) var favorites: [Favorite]
    @Environment(\.modelContext) var context
    @State var newFavorite: Favorite?
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(favorites) { favorite in
                    NavigationLink(favorite.name) {
                        FavoriteDetail(favorite: favorite)
                    }
                }
                .onDelete(perform: deleteFavorite(indexes: ))
            }
            //            .navigationTitle("Favorite Exercises")
            .toolbar {
                ToolbarItem {
//                    Button("Add Favorite exercise", systemImage: "plus", action: addFavorite)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .sheet(item: $newFavorite) { favorite in
                NavigationStack {
                    FavoriteDetail(favorite: favorite, isNew: true)
                }
                .interactiveDismissDisabled()
            }
        } detail: {
            Text("Add a favorite")
                .navigationTitle("Favorite")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func addFavorite(exerciseName: String) {
        let newFavorite = Favorite(name: "", type: "")
        context.insert(newFavorite)
        self.newFavorite = newFavorite
    }
    
    private func deleteFavorite(indexes: IndexSet) {
        for index in indexes {
            context.delete(favorites[index])
        }
    }
    
}


#Preview {
     FavoriteList()
        .modelContainer(sampleFavs.shared.modelContainer)
}
