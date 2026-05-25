//
//  GleanApp.swift
//  Glean
//

import SwiftData
import SwiftUI

@main
struct GleanApp: App {
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .light

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: GleanSchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: GleanMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
