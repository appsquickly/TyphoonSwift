/// A container for template variables.
public class Context {
  var dictionaries: [[String: Any]]
  let namespace: Namespace

  /// Initialise a Context with an optional dictionary and optional namespace
  public init(dictionary: [String: Any]? = nil, namespace: Namespace = Namespace()) {
    if let dictionary = dictionary {
      dictionaries = [dictionary]
    } else {
      dictionaries = []
    }

    self.namespace = namespace
  }

  open subscript(key: String) -> Any? {
    /// Retrieves a variable's value, starting at the current context and going upwards
    get {
      for dictionary in Array(dictionaries.reversed()) {
        if let value = dictionary[key] {
          return value
        }
      }

      return nil
    }

    /// Set a variable in the current context, deleting the variable if it's nil
    set(value) {
      if let dictionary = dictionaries.popLast() {
        var mutable_dictionary = dictionary
        mutable_dictionary[key] = value
        dictionaries.append(mutable_dictionary)
      }
    }
  }

  /// Push a new level into the Context
  fileprivate func push(_ dictionary: [String: Any]? = nil) {
    dictionaries.append(dictionary ?? [:])
  }

  /// Pop the last level off of the Context
  fileprivate func pop() -> [String: Any]? {
    return dictionaries.popLast()
  }

  /// Push a new level onto the context for the duration of the execution of the given closure
  open func push<Result>(dictionary: [String: Any]? = nil, closure: (() throws -> Result)) rethrows -> Result {
    push(dictionary)
    defer { _ = pop() }
    return try closure()
  }
}
