import Foundation
import SwiftData

@MainActor
class sampleFavs {
    static let shared = sampleFavs()

    let modelContainer: ModelContainer

    var context: ModelContext {
        modelContainer.mainContext
    }

    var favorite: Favorite {
        Favorite.sampleFavs.first!
    }

    private init() {
        let schema = Schema([
            Favorite.self

        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

            insertSampleData()

            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private func insertSampleData() {
        for favorite in Favorite.sampleFavs {
            context.insert(favorite)
        }

    }
}
