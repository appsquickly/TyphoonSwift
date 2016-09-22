////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2016, TyphoonSwift Framework Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

enum SourceLang {
    
    enum Declaration {
        static let instanceMethod   = "source.lang.swift.decl.function.method.instance"
        static let `class`          = "source.lang.swift.decl.class"
        static let varParameter     = "source.lang.swift.decl.var.parameter"
    }
    
    enum Statement {
        static let brace            = "source.lang.swift.stmt.brace"
    }
    
    enum Expr {
        static let call             = "source.lang.swift.expr.call"
    }
}
