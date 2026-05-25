//
//  GleanSchema.swift
//  Glean
//

import SwiftData

enum GleanSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Note.self, ActionItem.self, OpenQuestion.self]
    }
}

enum GleanMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [GleanSchemaV1.self]
    }

    static var stages: [MigrationStage] { [] }
}
