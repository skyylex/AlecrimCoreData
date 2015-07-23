//
//  ContextOptionsSpec.swift
//  AlecrimCoreData
//
//  Created by Yury Lapitsky on 7/23/15.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Quick
import Nimble
import AlecrimCoreData

private let dataContext = DataContext()!

private class DataContext: Context {
    var people: Table<Account> { return Table<Account>(context: self) }
}

private class Account: NSManagedObject {
    @NSManaged var title: String?
}

class ContextOptionsSpec: QuickSpec {
    override func spec() {
        describe("ContextOptionsSpec") {
            context("initialization") {
                it("all default options") {
                    let contextOptionsWithDefaults = ContextOptions()
                    
                    expect(contextOptionsWithDefaults.stackType == StackType.SQLite)
                    expect(contextOptionsWithDefaults.managedObjectModelName == nil)
                    expect(contextOptionsWithDefaults.storeOptions == nil)
                }
            }
        }
    }
}
