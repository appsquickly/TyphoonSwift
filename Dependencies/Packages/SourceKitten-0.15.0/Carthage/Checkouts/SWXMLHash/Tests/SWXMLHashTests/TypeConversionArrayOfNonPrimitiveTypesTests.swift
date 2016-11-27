//
//  TypeConversionArrayOfNonPrimitiveTypesTests.swift
//
//  Copyright (c) 2016 David Mohundro
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import SWXMLHash
import XCTest

// swiftlint:disable force_try
// swiftlint:disable line_length
// swiftlint:disable type_name

class TypeConversionArrayOfNonPrimitiveTypesTests: XCTestCase {
    var parser: XMLIndexer?
    let xmlWithArraysOfTypes = "<root>" +
        "<arrayOfGoodBasicItems>" +
        "   <basicItem>" +
        "      <name>item 1</name>" +
        "      <price>1</price>" +
        "   </basicItem>" +
        "   <basicItem>" +
        "      <name>item 2</name>" +
        "      <price>2</price>" +
        "   </basicItem>" +
        "   <basicItem>" +
        "      <name>item 3</name>" +
        "      <price>3</price>" +
        "   </basicItem>" +
        "</arrayOfGoodBasicItems>" +
        "<arrayOfBadBasicItems>" +
        "   <basicItem>" +
        "      <name>item 1</name>" +
        "      <price>1</price>" +
        "   </basicItem>" +
        "   <basicItem>" +  // it's missing the name node
        "      <price>2</price>" +
        "   </basicItem>" +
        "   <basicItem>" +
        "      <name>item 3</name>" +
        "      <price>3</price>" +
        "   </basicItem>" +
        "</arrayOfBadBasicItems>" +
        "<arrayOfGoodAttributeItems>" +
        "   <attributeItem name=\"attr 1\" price=\"1.1\"/>" +
        "   <attributeItem name=\"attr 2\" price=\"2.2\"/>" +
        "   <attributeItem name=\"attr 3\" price=\"3.3\"/>" +
        "</arrayOfGoodAttributeItems>" +
        "<arrayOfBadAttributeItems>" +
        "   <attributeItem name=\"attr 1\" price=\"1.1\"/>" +
        "   <attributeItem price=\"2.2\"/>" + // it's missing the name attribute
        "   <attributeItem name=\"attr 3\" price=\"3.3\"/>" +
        "</arrayOfBadAttributeItems>" +
    "</root>"

    let correctBasicItems = [
        BasicItem(name: "item 1", price: 1),
        BasicItem(name: "item 2", price: 2),
        BasicItem(name: "item 3", price: 3)
    ]

    let correctAttributeItems = [
        AttributeItem(name: "attr 1", price: 1.1),
        AttributeItem(name: "attr 2", price: 2.2),
        AttributeItem(name: "attr 3", price: 3.3)
    ]

    override func setUp() {
        parser = SWXMLHash.parse(xmlWithArraysOfTypes)
    }

    func testShouldConvertArrayOfGoodBasicitemsItemsToNonOptional() {
        do {
            let value: [BasicItem] = try parser!["root"]["arrayOfGoodBasicItems"]["basicItem"].value()
            XCTAssertEqual(value, correctBasicItems)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testShouldConvertArrayOfGoodBasicitemsItemsToOptional() {
        do {
            let value: [BasicItem]? = try parser!["root"]["arrayOfGoodBasicItems"]["basicItem"].value()
            XCTAssertNotNil(value)
            if let value = value {
                XCTAssertEqual(value, correctBasicItems)
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func testShouldConvertArrayOfGoodBasicitemsItemsToArrayOfOptionals() {
        do {
            let value: [BasicItem?] = try parser!["root"]["arrayOfGoodBasicItems"]["basicItem"].value()
            XCTAssertEqual(value.flatMap({ $0 }), correctBasicItems)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testShouldThrowWhenConvertingArrayOfBadBasicitemsToNonOptional() {
        XCTAssertThrowsError(try (parser!["root"]["arrayOfBadBasicItems"]["basicItem"].value() as [BasicItem])) { error in
            guard error is XMLDeserializationError else {
                XCTFail("Wrong type of error")
                return
            }
        }
    }

    func testShouldThrowWhenConvertingArrayOfBadBasicitemsToOptional() {
        XCTAssertThrowsError(try (parser!["root"]["arrayOfBadBasicItems"]["basicItem"].value() as [BasicItem]?)) { error in
            guard error is XMLDeserializationError else {
                XCTFail("Wrong type of error")
                return
            }
        }
    }

    func testShouldThrowWhenConvertingArrayOfBadBasicitemsToArrayOfOptionals() {
        XCTAssertThrowsError(try (parser!["root"]["arrayOfBadBasicItems"]["basicItem"].value() as [BasicItem?])) { error in
            guard error is XMLDeserializationError else {
                XCTFail("Wrong type of error")
                return
            }
        }
    }

    func testShouldConvertArrayOfGoodAttributeItemsToNonOptional() {
        do {
            let value: [AttributeItem] = try parser!["root"]["arrayOfGoodAttributeItems"]["attributeItem"].value()
            XCTAssertEqual(value, correctAttributeItems)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testShouldConvertArrayOfGoodAttributeItemsToOptional() {
        do {
            let value: [AttributeItem]? = try parser!["root"]["arrayOfGoodAttributeItems"]["attributeItem"].value()
            XCTAssertNotNil(value)
            if let value = value {
                XCTAssertEqual(value, correctAttributeItems)
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func testShouldConvertArrayOfGoodAttributeItemsToArrayOfOptionals() {
        do {
            let value: [AttributeItem?] = try parser!["root"]["arrayOfGoodAttributeItems"]["attributeItem"].value()
            XCTAssertEqual(value.flatMap({ $0 }), correctAttributeItems)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testShouldThrowWhenConvertingArrayOfBadAttributeItemsToNonOptional() {
        XCTAssertThrowsError(try (parser!["root"]["arrayOfBadAttributeItems"]["attributeItem"].value() as [AttributeItem])) { error in
            guard error is XMLDeserializationError else {
                XCTFail("Wrong type of error")
                return
            }
        }
    }

    func testShouldThrowWhenConvertingArrayOfBadAttributeItemsToOptional() {
        XCTAssertThrowsError(try (parser!["root"]["arrayOfBadAttributeItems"]["attributeItem"].value() as [AttributeItem]?)) { error in
            guard error is XMLDeserializationError else {
                XCTFail("Wrong type of error")
                return
            }
        }
    }

    func testShouldThrowWhenConvertingArrayOfBadAttributeItemsToArrayOfOptionals() {
        XCTAssertThrowsError(try (parser!["root"]["arrayOfBadAttributeItems"]["attributeItem"].value() as [AttributeItem?])) { error in
            guard error is XMLDeserializationError else {
                XCTFail("Wrong type of error")
                return
            }
        }
    }
}

extension TypeConversionArrayOfNonPrimitiveTypesTests {
    static var allTests: [(String, (TypeConversionArrayOfNonPrimitiveTypesTests) -> () throws -> Void)] {
        return [
            ("testShouldConvertArrayOfGoodBasicitemsItemsToNonOptional", testShouldConvertArrayOfGoodBasicitemsItemsToNonOptional),
            ("testShouldConvertArrayOfGoodBasicitemsItemsToOptional", testShouldConvertArrayOfGoodBasicitemsItemsToOptional),
            ("testShouldConvertArrayOfGoodBasicitemsItemsToArrayOfOptionals", testShouldConvertArrayOfGoodBasicitemsItemsToArrayOfOptionals),
            ("testShouldThrowWhenConvertingArrayOfBadBasicitemsToNonOptional", testShouldThrowWhenConvertingArrayOfBadBasicitemsToNonOptional),
            ("testShouldThrowWhenConvertingArrayOfBadBasicitemsToOptional", testShouldThrowWhenConvertingArrayOfBadBasicitemsToOptional),
            ("testShouldThrowWhenConvertingArrayOfBadBasicitemsToArrayOfOptionals", testShouldThrowWhenConvertingArrayOfBadBasicitemsToArrayOfOptionals),
            ("testShouldConvertArrayOfGoodAttributeItemsToNonOptional", testShouldConvertArrayOfGoodAttributeItemsToNonOptional),
            ("testShouldConvertArrayOfGoodAttributeItemsToOptional", testShouldConvertArrayOfGoodAttributeItemsToOptional),
            ("testShouldConvertArrayOfGoodAttributeItemsToArrayOfOptionals", testShouldConvertArrayOfGoodAttributeItemsToArrayOfOptionals),
            ("testShouldThrowWhenConvertingArrayOfBadAttributeItemsToNonOptional", testShouldThrowWhenConvertingArrayOfBadAttributeItemsToNonOptional),
            ("testShouldThrowWhenConvertingArrayOfBadAttributeItemsToOptional", testShouldThrowWhenConvertingArrayOfBadAttributeItemsToOptional),
            ("testShouldThrowWhenConvertingArrayOfBadAttributeItemsToArrayOfOptionals", testShouldThrowWhenConvertingArrayOfBadAttributeItemsToArrayOfOptionals),
        ]
    }
}
