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
                
                it("all default options") {
                    let contextOptionsWithDefaults = ContextOptions()
                    
                    expect(contextOptionsWithDefaults.stackType == StackType.SQLite)
                    expect(contextOptionsWithDefaults.managedObjectModelName == nil)
                    expect(contextOptionsWithDefaults.storeOptions == nil)
                }
                
                it("custom options options") {
                    let key = "key"
                    let value = "value"
                    let customStoreOptions = [key : value]
                    let customModelName = "customModelName"
                    let customStackType = StackType.InMemory
                    
                    let contextOptionsWithDefaults = ContextOptions(stackType: customStackType, managedObjectModelName:customModelName, storeOptions:customStoreOptions)
                    
                    expect(contextOptionsWithDefaults.stackType == customStackType)
                    expect(contextOptionsWithDefaults.managedObjectModelName == customModelName)
                    expect(contextOptionsWithDefaults.storeOptions.count == customStoreOptions.count)
                    let storedValue = contextOptionsWithDefaults.storeOptions[key] as? NSString
                    expect(storedValue?.compare(value))
                }
            }
        }
    }
}
