open class IfNode : NodeType {
  open let variable:Variable
  open let trueNodes:[NodeType]
  open let falseNodes:[NodeType]

  open class func parse(_ parser:TokenParser, token:Token) throws -> NodeType {
    let components = token.components()
    guard components.count == 2 else {
      throw TemplateSyntaxError("'if' statements should use the following 'if condition' `\(token.contents)`.")
    }
    let variable = components[1]
    var trueNodes = [NodeType]()
    var falseNodes = [NodeType]()

    trueNodes = try parser.parse(until(["endif", "else"]))

    guard let token = parser.nextToken() else {
      throw TemplateSyntaxError("`endif` was not found.")
    }

    if token.contents == "else" {
      falseNodes = try parser.parse(until(["endif"]))
      _ = parser.nextToken()
    }

    return IfNode(variable: variable, trueNodes: trueNodes, falseNodes: falseNodes)
  }

  open class func parse_ifnot(_ parser:TokenParser, token:Token) throws -> NodeType {
    let components = token.components()
    guard components.count == 2 else {
      throw TemplateSyntaxError("'ifnot' statements should use the following 'ifnot condition' `\(token.contents)`.")
    }
    let variable = components[1]
    var trueNodes = [NodeType]()
    var falseNodes = [NodeType]()

    falseNodes = try parser.parse(until(["endif", "else"]))

    guard let token = parser.nextToken() else {
      throw TemplateSyntaxError("`endif` was not found.")
    }

    if token.contents == "else" {
      trueNodes = try parser.parse(until(["endif"]))
      _ = parser.nextToken()
    }

    return IfNode(variable: variable, trueNodes: trueNodes, falseNodes: falseNodes)
  }

  public init(variable:String, trueNodes:[NodeType], falseNodes:[NodeType]) {
    self.variable = Variable(variable)
    self.trueNodes = trueNodes
    self.falseNodes = falseNodes
  }

  open func render(_ context: Context) throws -> String {
    let result = try variable.resolve(context)
    var truthy = false

    if let result = result as? [Any] {
      truthy = !result.isEmpty
    } else if let result = result as? [String:Any] {
      truthy = !result.isEmpty
    } else if let result = result as? Bool {
      truthy = result
    } else if result != nil {
      truthy = true
    }

    return try context.push {
      if truthy {
        return try renderNodes(trueNodes, context)
      } else {
        return try renderNodes(falseNodes, context)
      }
    }
  }
}
