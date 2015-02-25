//
//  Table.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class Table<T: NSManagedObject> {
    
    internal let defaultFetchBatchSize = 20
    internal lazy var underlyingFetchRequest = NSFetchRequest(entityName: T.entityName)
    internal let context: Context
    
    public init(context: Context) {
        self.context = context
    }
    
}

// MARK: - partitioning

extension Table {
    
    public func skip(count: Int) -> Self {
        self.underlyingFetchRequest.fetchOffset = count
        return self
    }
    
    public func take(count: Int) -> Self {
        self.underlyingFetchRequest.fetchLimit = count
        return self
    }
    
}

// MARK - ordering

extension Table {
    
    public func orderBy(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func orderByAscending(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func orderByDescending(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: false)
    }
    
    public func thenBy(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: true)
    }

    public func thenByAscending(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func thenByDescending(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: false)
    }
    
    public func sortBy(sortTerm: String, ascending: Bool = true) -> Self {
        let addedSortDescriptors = self.sortDescriptorsFromString(sortTerm, defaultAscendingValue: ascending)
        
        if var sortDescriptors = self.underlyingFetchRequest.sortDescriptors as? [NSSortDescriptor] {
            sortDescriptors += addedSortDescriptors
        }
        else {
            self.underlyingFetchRequest.sortDescriptors = addedSortDescriptors
        }
        
        return self
    }

}

// MARK - restriction

extension Table {

    public func filterBy(#predicate: NSPredicate) -> Self {
        if self.underlyingFetchRequest.predicate == nil {
            self.underlyingFetchRequest.predicate = predicate
        }
        else if let compoundPredicate = self.underlyingFetchRequest.predicate as? NSCompoundPredicate {
            var subpredicates = compoundPredicate.subpredicates as! [NSPredicate]
            subpredicates.append(predicate)
            self.underlyingFetchRequest.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(subpredicates)
        }
        else {
            let subpredicates = [self.underlyingFetchRequest.predicate!, predicate]
            self.underlyingFetchRequest.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(subpredicates)
        }
        
        return self
    }
    
    public func filterBy(attribute attributeName: String, value: AnyObject?) -> Self {
        var predicate: NSPredicate
        if let v: AnyObject = value {
            predicate = NSPredicate(format: "%K == %@", argumentArray: [attributeName, v])
        }
        else {
            predicate = NSPredicate(format: "%K == nil", argumentArray: [attributeName])
        }
        
        return self.filterBy(predicate: predicate)
    }
    
    public func filterBy(#predicateFormat: String, argumentArray arguments: [AnyObject]?) -> Self {
        let predicate = NSPredicate(format: predicateFormat, argumentArray: arguments)
        return self.filterBy(predicate: predicate)
    }
    
    public func filterBy(#predicateFormat: String, arguments: AnyObject...) -> Self {
        let predicate = NSPredicate(format: predicateFormat, argumentArray: arguments)
        return self.filterBy(predicate: predicate)
    }
    
    public func filterBy(#predicateFormat: String, arguments: CVaListPointer) -> Self {
        let predicate = NSPredicate(format: predicateFormat, arguments: arguments)
        return self.filterBy(predicate: predicate)
    }
    
}

// MARK: - conversion

extension Table {
    
    public func toFetchRequest() -> NSFetchRequest {
        return self.underlyingFetchRequest.copy() as! NSFetchRequest
    }
    
}

extension Table {
    
    public func toArray() -> [T] {
        return self.toArray(fetchRequest: self.toFetchRequest())
    }
    
}

// MARK: - aggregate

extension Table {
    
    public func count() -> Int {
        return self.count(fetchRequest: self.toFetchRequest())
    }

}

// MARK: - quantifiers

extension Table {

    public func any() -> Bool {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.fetchLimit = 1
        
        let result = self.count(fetchRequest: fetchRequest) > 0
        
        return result
    }
    
}

// MARK: - element

extension Table {
    
    public func first() -> T? {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.fetchLimit = 1
        
        let results = self.toArray(fetchRequest: fetchRequest)
        
        return (results.isEmpty ? nil : results[0])
    }
    
}

// MARK: create, delete and refresh entities

extension Table {
    
    public func createEntity() -> T {
        let entityDescription = NSEntityDescription.entityForName(T.entityName, inManagedObjectContext: self.context.managedObjectContext)!
        let managedObject = T(entity: entityDescription, insertIntoManagedObjectContext: self.context.managedObjectContext)
        
        return managedObject
    }
    
    public func createOrGetFirstEntity(whereAttribute attributeName: String, isEqualTo value: AnyObject?) -> T {
        if let entity = self.filterBy(attribute: attributeName, value: value).first() {
            return entity
        }
        else {
            let entity = self.createEntity()
            entity.setValue(value, forKey: attributeName)
            
            return entity
        }
    }
    
    public func deleteEntity(managedObject: T) -> (Bool, NSError?) {
        var retrieveExistingObjectError: NSError? = nil
        
        if let managedObjectInContext = self.context.managedObjectContext.existingObjectWithID(managedObject.objectID, error: &retrieveExistingObjectError) {
            self.context.managedObjectContext.deleteObject(managedObjectInContext)
            return (managedObject.deleted || managedObject.managedObjectContext == nil, nil)
        }
        else {
            return (false, retrieveExistingObjectError)
        }
    }
    
    public func refreshEntity(managedObject: T) {
        if let moc = managedObject.managedObjectContext {
            moc.refreshObject(managedObject, mergeChanges: true)
        }
    }
    
}

extension Table {
    
    public func delete() {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.returnsObjectsAsFaults = true
        fetchRequest.includesPropertyValues = false
        
        let entities = self.toArray(fetchRequest: fetchRequest)
        for entity in entities {
            self.deleteEntity(entity)
        }
    }
    
}

// MARK: - sequence

extension Table: SequenceType {
    
    public typealias GeneratorType = IndexingGenerator<[T]>
    
    public func generate() -> GeneratorType {
        return self.toArray().generate()
    }
    
}

// MARK: - private methods

extension Table {
    
    private func sortDescriptorsFromString(string: String, defaultAscendingValue: Bool) -> [NSSortDescriptor] {
        var sortDescriptors = [NSSortDescriptor]()
        
        let sortKeys = string.componentsSeparatedByString(",") as [NSString]
        for sortKey in sortKeys {
            var effectiveSortKey = sortKey
            var effectiveAscending = defaultAscendingValue
            var effectiveOptionalParameter: NSString? = nil
            
            let sortComponents = sortKey.componentsSeparatedByString(":") as! [NSString]
            if sortComponents.count > 1 {
                effectiveSortKey = sortComponents[0]
                effectiveAscending = sortComponents[1].boolValue
                
                if (sortComponents.count > 2) {
                    effectiveOptionalParameter = sortComponents[2]
                }
            }
            
            if effectiveOptionalParameter != nil && effectiveOptionalParameter!.rangeOfString("cd").location != NSNotFound {
                sortDescriptors.append(NSSortDescriptor(key: effectiveSortKey as! String, ascending: effectiveAscending, selector: Selector("localizedCaseInsensitiveCompare:")))
            }
            else {
                sortDescriptors.append(NSSortDescriptor(key: effectiveSortKey as! String, ascending: effectiveAscending))
            }
        }
        
        return sortDescriptors
    }
    
}

extension Table {
    
    private func toArray(#fetchRequest: NSFetchRequest) -> [T] {
        fetchRequest.fetchBatchSize = self.defaultFetchBatchSize
        
        var results = [T]()
        
        self.context.managedObjectContext.performBlockAndWait { [weak self] in
            if let s = self {
                var error: NSError? = nil
                if let objects = s.context.managedObjectContext.executeFetchRequest(fetchRequest, error: &error) as? [T] {
                    results += objects
                }
            }
        }
        
        return results
    }
    
    private func count(#fetchRequest: NSFetchRequest) -> Int {
        var c = 0
        
        self.context.managedObjectContext.performBlockAndWait { [weak self] in
            if let s = self {
                var error: NSError? = nil
                c += s.context.managedObjectContext.countForFetchRequest(fetchRequest, error: &error)
            }
        }
        
        return c
    }
    
}

// SWIFT_BUG: Error -> Linker error if these extensions are outside this source file. Workaround -> Put the extensions here.

#if os(iOS)

extension Table {
    
    public func toFetchedResultsController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> FetchedResultsController<T> {
        return FetchedResultsController<T>(fetchRequest: self.toFetchRequest(), managedObjectContext: self.context.managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }
    
}

#endif
