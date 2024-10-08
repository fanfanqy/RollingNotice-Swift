//
//  SafeArray.swift
//  RollingNotice-Swift
//
//  Created by 范庆宇 on 2024/9/29.
//  Copyright © 2024 qm. All rights reserved.
//

import Foundation
/// A thread-safe array.
public class SafeArray<Element> {
    fileprivate let queue = DispatchQueue(label: "Com.BigNerdCoding.SafeArray", attributes: .concurrent)
    fileprivate var array = [Element]()
}
 
// MARK: - Properties
public extension SafeArray {
 
    var first: Element? {
        var result: Element?
        queue.sync { result = self.array.first }
        return result
    }
 
    var last: Element? {
        var result: Element?
        queue.sync { result = self.array.last }
        return result
    }
 
    var count: Int {
        var result = 0
        queue.sync { result = self.array.count }
        return result
    }

    var isEmpty: Bool {
        var result = false
        queue.sync { result = self.array.isEmpty }
        return result
    }
    
    var description: String {
        var result = ""
        queue.sync { result = self.array.description }
        return result
    }
}
 
// MARK: - 读操作
public extension SafeArray {
    func first(where predicate: (Element) -> Bool) -> Element? {
        var result: Element?
        queue.sync { result = self.array.first(where: predicate) }
        return result
    }
    
    func filter(_ isIncluded: (Element) -> Bool) -> [Element] {
        var result = [Element]()
        queue.sync { result = self.array.filter(isIncluded) }
        return result
    }
    
    func index(where predicate: (Element) -> Bool) -> Int? {
        var result: Int?
        queue.sync { result = self.array.index(where: predicate) }
        return result
    }
    
    func sorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> [Element] {
        var result = [Element]()
        queue.sync { result = self.array.sorted(by: areInIncreasingOrder) }
        return result
    }
    
    func flatMap<ElementOfResult>(_ transform: (Element) -> ElementOfResult?) -> [ElementOfResult] {
        var result = [ElementOfResult]()
        queue.sync { result = self.array.flatMap(transform) }
        return result
    }
 
    func forEach(_ body: (Element) -> Void) {
        queue.sync { self.array.forEach(body) }
    }
    
    func contains(where predicate: (Element) -> Bool) -> Bool {
        var result = false
        queue.sync { result = self.array.contains(where: predicate) }
        return result
    }
}
 
// MARK: - 写操作
public extension SafeArray {
 
    func append( _ element: Element) {
        queue.async(flags: .barrier) {
            self.array.append(element)
        }
    }
 
    func append( _ elements: [Element]) {
        queue.async(flags: .barrier) {
            self.array += elements
        }
    }
 
    func insert( _ element: Element, at index: Int) {
        queue.async(flags: .barrier) {
            self.array.insert(element, at: index)
        }
    }
 
    func remove(at index: Int, completion: ((Element) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let element = self.array.remove(at: index)
            
            DispatchQueue.main.async {
                completion?(element)
            }
        }
    }
    
    func remove(where predicate: @escaping (Element) -> Bool, completion: ((Element) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            guard let index = self.array.index(where: predicate) else { return }
            let element = self.array.remove(at: index)
            
            DispatchQueue.main.async {
                completion?(element)
            }
        }
    }
 
    func removeAll(completion: (([Element]) -> Void)? = nil) {
        queue.async(flags: .barrier) {
            let elements = self.array
            self.array.removeAll()
            
            DispatchQueue.main.async {
                completion?(elements)
            }
        }
    }
}
 
public extension SafeArray {

    subscript(index: Int) -> Element? {
        get {
            var result: Element?
            
            queue.sync {
                guard self.array.startIndex..<self.array.endIndex ~= index else { return }
                result = self.array[index]
            }
            
            return result
        }
        set {
            guard let newValue = newValue else { return }
            
            queue.async(flags: .barrier) {
                self.array[index] = newValue
            }
        }
    }
}
 
 
// MARK: - Equatable
public extension SafeArray where Element: Equatable {

    func contains(_ element: Element) -> Bool {
        var result = false
        queue.sync { result = self.array.contains(element) }
        return result
    }
}
 
// MARK: - 自定义操作符
public extension SafeArray {
 
    static func +=(left: inout SafeArray, right: Element) {
        left.append(right)
    }
 
    static func +=(left: inout SafeArray, right: [Element]) {
        left.append(right)
    }
}
