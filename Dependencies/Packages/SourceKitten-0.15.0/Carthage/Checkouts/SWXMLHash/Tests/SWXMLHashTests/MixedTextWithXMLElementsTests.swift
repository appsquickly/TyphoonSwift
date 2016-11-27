//
//  MixedTextWithXMLElementsTests.swift
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

// swiftlint:disable line_length

class MixedTextWithXMLElementsTests: XCTestCase {
    var xml: XMLIndexer?

    override func setUp() {
        let xmlContent = "<everything><news><content>Here is a cool thing <a href=\"google.com\">A</a> and second cool thing <a href=\"fb.com\">B</a></content></news></everything>"
        xml = SWXMLHash.parse(xmlContent)
    }

    func testShouldBeAbleToGetAllContentsInsideOfAnElement() {
        XCTAssertEqual(xml!["everything"]["news"]["content"].description, "<content>Here is a cool thing <a href=\"google.com\">A</a> and second cool thing <a href=\"fb.com\">B</a></content>")
    }
}

extension MixedTextWithXMLElementsTests {
    static var allTests: [(String, (MixedTextWithXMLElementsTests) -> () throws -> Void)] {
        return [
            ("testShouldBeAbleToGetAllContentsInsideOfAnElement", testShouldBeAbleToGetAllContentsInsideOfAnElement),
        ]
    }
}
