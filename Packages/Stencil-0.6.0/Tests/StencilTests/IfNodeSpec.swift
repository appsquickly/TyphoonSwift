import Spectre
import Stencil


func testIfNode() {
  describe("IfNode") {
    $0.describe("parsing") {
      $0.it("can parse an if block") {
        let tokens: [Token] = [
          .block(value: "if value"),
          .text(value: "true"),
          .block(value: "else"),
          .text(value: "false"),
          .block(value: "endif")
        ]

        let parser = TokenParser(tokens: tokens, namespace: Namespace())
        let nodes = try parser.parse()
        let node = nodes.first as? IfNode
        let trueNode = node?.trueNodes.first as? TextNode
        let falseNode = node?.falseNodes.first as? TextNode

        try expect(nodes.count) == 1
        try expect(node?.variable.variable) == "value"
        try expect(node?.trueNodes.count) == 1
        try expect(trueNode?.text) == "true"
        try expect(node?.falseNodes.count) == 1
        try expect(falseNode?.text) == "false"
      }

      $0.it("can parse an ifnot block") {
        let tokens: [Token] = [
          .block(value: "ifnot value"),
          .text(value: "false"),
          .block(value: "else"),
          .text(value: "true"),
          .block(value: "endif")
        ]

        let parser = TokenParser(tokens: tokens, namespace: Namespace())
        let nodes = try parser.parse()
        let node = nodes.first as? IfNode
        let trueNode = node?.trueNodes.first as? TextNode
        let falseNode = node?.falseNodes.first as? TextNode

        try expect(nodes.count) == 1
        try expect(node?.variable.variable) == "value"
        try expect(node?.trueNodes.count) == 1
        try expect(trueNode?.text) == "true"
        try expect(node?.falseNodes.count) == 1
        try expect(falseNode?.text) == "false"
      }

      $0.it("throws an error when parsing an if block without an endif") {
        let tokens: [Token] = [
          .block(value: "if value"),
        ]

        let parser = TokenParser(tokens: tokens, namespace: Namespace())
        let error = TemplateSyntaxError("`endif` was not found.")
        try expect(try parser.parse()).toThrow(error)
      }

      $0.it("throws an error when parsing an ifnot without an endif") {
        let tokens: [Token] = [
            .block(value: "ifnot value"),
        ]

        let parser = TokenParser(tokens: tokens, namespace: Namespace())
        let error = TemplateSyntaxError("`endif` was not found.")
        try expect(try parser.parse()).toThrow(error)
      }
    }

    $0.describe("rendering") {
      $0.it("renders the truth when expression evaluates to true") {
        let context = Context(dictionary: ["items": true])
        let node = IfNode(variable: "items", trueNodes: [TextNode(text: "true")], falseNodes: [TextNode(text: "false")])
        try expect(try node.render(context)) == "true"
      }

      $0.it("renders the false when expression evaluates to false") {
        let context = Context(dictionary: ["items": false])
        let node = IfNode(variable: "items", trueNodes: [TextNode(text: "true")], falseNodes: [TextNode(text: "false")])
        try expect(try node.render(context)) == "false"
      }

      $0.it("renders the truth when expression is not nil") {
        let context = Context(dictionary: ["known": "known"])
        let node = IfNode(variable: "known", trueNodes: [TextNode(text: "true")], falseNodes: [TextNode(text: "false")])
        try expect(try node.render(context)) == "true"
      }

      $0.it("renders the false when expression is nil") {
        let context = Context(dictionary: [:])
        let node = IfNode(variable: "unknown", trueNodes: [TextNode(text: "true")], falseNodes: [TextNode(text: "false")])
        try expect(try node.render(context)) == "false"
      }

      $0.it("renders the truth when array expression is not empty") {
        let items: [[String: Any]] = [["key":"key1","value":42],["key":"key2","value":1337]]
        let arrayContext = Context(dictionary: ["items": [items]])
        let node = IfNode(variable: "items", trueNodes: [TextNode(text: "true")], falseNodes: [TextNode(text: "false")])
        try expect(try node.render(arrayContext)) == "true"
      }

      $0.it("renders the false when array expression is empty") {
        let emptyItems = [[String: Any]]()
        let arrayContext = Context(dictionary: ["items": emptyItems])
        let node = IfNode(variable: "items", trueNodes: [TextNode(text: "true")], falseNodes: [TextNode(text: "false")])
        try expect(try node.render(arrayContext)) == "false"
      }

      $0.it("renders the false when dictionary expression is empty") {
        let emptyItems = [String:Any]()
        let arrayContext = Context(dictionary: ["items": emptyItems])
        let node = IfNode(variable: "items", trueNodes: [TextNode(text: "true")], falseNodes: [TextNode(text: "false")])
        try expect(try node.render(arrayContext)) == "false"
      }

      $0.it("renders the false when Array<Any> variable is empty") {
        let arrayContext = Context(dictionary: ["items": ([] as [Any])])
        let node = IfNode(variable: "items", trueNodes: [TextNode(text: "true")], falseNodes: [TextNode(text: "false")])
        try expect(try node.render(arrayContext)) == "false"
      }
    }
  }
}
