//
//  CoreDataStack.swift
//  FloorPlanner
//
//  Core Data stack with NSPersistentCloudKitContainer
//

import CoreData
import CloudKit

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()

    let container: NSPersistentCloudKitContainer

    init() {
        // Load the model explicitly from the bundle containing this class
        let bundle: Bundle
        #if SWIFT_PACKAGE
        bundle = Bundle.module
        #else
        bundle = Bundle(for: CoreDataStack.self)
        #endif

        // Find the compiled model
        guard let modelURL = bundle.url(forResource: "FloorPlanner", withExtension: "momd") else {
            fatalError("Failed to find data model in bundle: \(bundle.bundlePath)")
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to create model from file: \(modelURL)")
        }

        container = NSPersistentCloudKitContainer(name: "FloorPlanner", managedObjectModel: model)

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store description found")
        }

        // Enable CloudKit
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.keithjasper83.FloorPlanner" // This should match entitlements
        )

        // Enable history tracking for deduplication/sync handling
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
                // In a real app we might want to handle this better (e.g., delete store and retry)
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving Core Data context: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Core Data Entities (Manual Definition)

@objc(ProjectEntity)
public class ProjectEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var materialType: String?
    @NSManaged public var wasteFactor: Double
    @NSManaged public var currency: String?

    @NSManaged public var roomSettings: RoomSettingsEntity?
    @NSManaged public var stockItems: NSSet?
    @NSManaged public var laminateSettings: LaminateSettingsEntity?
    @NSManaged public var tileSettings: TileSettingsEntity?
}

@objc(StockItemEntity)
public class StockItemEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var lengthMm: Double
    @NSManaged public var widthMm: Double
    @NSManaged public var quantity: Int64
    @NSManaged public var pricePerUnit: Double

    @NSManaged public var project: ProjectEntity?
}

@objc(RoomSettingsEntity)
public class RoomSettingsEntity: NSManagedObject {
    @NSManaged public var shape: String?
    @NSManaged public var lengthMm: Double
    @NSManaged public var widthMm: Double
    @NSManaged public var expansionGapMm: Double
    @NSManaged public var patternType: String?
    @NSManaged public var angleDegrees: Double

    @NSManaged public var project: ProjectEntity?
    @NSManaged public var polygonPoints: NSOrderedSet?
}

@objc(RoomPointEntity)
public class RoomPointEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var x: Double
    @NSManaged public var y: Double
    @NSManaged public var orderIndex: Int64

    @NSManaged public var roomSettings: RoomSettingsEntity?
}

@objc(LaminateSettingsEntity)
public class LaminateSettingsEntity: NSManagedObject {
    @NSManaged public var minStaggerMm: Double
    @NSManaged public var minOffcutLengthMm: Double
    @NSManaged public var plankDirection: String?
    @NSManaged public var defaultPlankLengthMm: Double
    @NSManaged public var defaultPlankWidthMm: Double
    @NSManaged public var defaultPricePerPlank: Double

    @NSManaged public var project: ProjectEntity?
}

@objc(TileSettingsEntity)
public class TileSettingsEntity: NSManagedObject {
    @NSManaged public var tileSizeMm: Double
    @NSManaged public var pattern: String?
    @NSManaged public var orientation: String?
    @NSManaged public var reuseEdgeOffcuts: Bool
    @NSManaged public var tilesPerBox: Int64
    @NSManaged public var defaultPricePerTile: Double

    @NSManaged public var project: ProjectEntity?
}

// MARK: - Accessors

extension ProjectEntity {
    @objc(addStockItemsObject:)
    @NSManaged public func addToStockItems(_ value: StockItemEntity)

    @objc(removeStockItemsObject:)
    @NSManaged public func removeFromStockItems(_ value: StockItemEntity)

    @objc(addStockItems:)
    @NSManaged public func addToStockItems(_ values: NSSet)

    @objc(removeStockItems:)
    @NSManaged public func removeFromStockItems(_ values: NSSet)
}

extension RoomSettingsEntity {
    @objc(insertObject:inPolygonPointsAtIndex:)
    @NSManaged public func insertIntoPolygonPoints(_ value: RoomPointEntity, at idx: Int)

    @objc(removeObjectFromPolygonPointsAtIndex:)
    @NSManaged public func removeFromPolygonPoints(at idx: Int)

    @objc(insertPolygonPoints:atIndexes:)
    @NSManaged public func insertIntoPolygonPoints(_ values: [RoomPointEntity], at indexes: NSIndexSet)

    @objc(removePolygonPointsAtIndexes:)
    @NSManaged public func removeFromPolygonPoints(at indexes: NSIndexSet)

    @objc(replaceObjectInPolygonPointsAtIndex:withObject:)
    @NSManaged public func replacePolygonPoints(at idx: Int, with value: RoomPointEntity)

    @objc(replacePolygonPointsAtIndexes:withPolygonPoints:)
    @NSManaged public func replacePolygonPoints(at indexes: NSIndexSet, with values: [RoomPointEntity])

    @objc(addPolygonPointsObject:)
    @NSManaged public func addToPolygonPoints(_ value: RoomPointEntity)

    @objc(removePolygonPointsObject:)
    @NSManaged public func removeFromPolygonPoints(_ value: RoomPointEntity)

    @objc(addPolygonPoints:)
    @NSManaged public func addToPolygonPoints(_ values: NSOrderedSet)

    @objc(removePolygonPoints:)
    @NSManaged public func removeFromPolygonPoints(_ values: NSOrderedSet)
}
