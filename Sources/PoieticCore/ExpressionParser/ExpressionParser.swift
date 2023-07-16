//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 27/05/2022.
//

// https://craftinginterpreters.com/parsing-expressions.html
// https://stackoverflow.com/questions/2245962/writing-a-parser-like-flex-bison-that-is-usable-on-8-bit-embedded-systems/2336769#2336769


/// Parser for arithmetic expressions.
///
/// The parses takes a string as an input and creates an unbound arithmetic
/// expression.
///
public class ExpressionParser {
    let lexer: Lexer
    var currentToken: Token?
    
    /// Creates a new parser using an expression lexer.
    ///
    public init(lexer: Lexer) {
        self.lexer = lexer
        advance()
    }
    
    /// Creates a new parser for an expression source string.
    ///
    public convenience init(string: String) {
        self.init(lexer: Lexer(string: string))
    }
    
    /// True if the parser is at the end of the source.
    public var atEnd: Bool {
        if let token = currentToken {
            return token.type == .empty
        }
        else {
            return true
        }
    }
    
    /// Advance to the next token.
    ///
    func advance() {
        currentToken = lexer.next()
    }
    
    /// Accent a token a type ``type``.
    ///
    /// - Returns: A token if the token matches the expected type, ``nil`` if
    ///     the token does not match the expected type.
    ///
    func accept(_ type: TokenType) -> Token? {
        guard let token = currentToken else {
            return nil
        }
        if token.type == type {
            advance()
            return token
        }
        else {
            return nil
        }
    }

    // ----------------------------------------------------------------
    
    /// Parse an operator.
    func `operator`(_ op: String) -> Token? {
        guard let token = currentToken else {
            return nil
        }
        if token.type == .operator && token.text == op {
            advance()
            return token
        }
        else {
            return nil
        }

    }
    
    /// Parse an identifier - a variable name or a function name.
    ///
    func identifier() -> Token? {
        if let token = accept(.identifier) {
            return token
        }
        else {
            return nil
        }
    }

    /// Parse an integer or a float.
    ///
    func number() -> (any ExpressionSyntax)? {
        if let token = accept(.int) {
            return LiteralSyntax(type: .int, literal: token)
        }
        else if let token = accept(.double) {
            return LiteralSyntax(type: .double, literal: token)
        }
        else {
            return nil
        }
    }
    
    /// Rule:
    ///
    ///     variable_call -> IDENTIFIER ["(" ARGUMENTS ")"]
    ///
    func variable_or_call() throws -> (any ExpressionSyntax)? {
        guard let ident = identifier() else {
            return nil
        }

        if let lparen = accept(.leftParen) {
            var arguments: [FunctionArgumentSyntax] = []
            repeat {
                guard let expr = try expression() else {
                    break
                }
                
                if let comma = accept(.comma) {
                    let arg = FunctionArgumentSyntax(argument: expr,
                                                     trailingComma: comma)
                    arguments.append(arg)
                }
                else {
                    let arg = FunctionArgumentSyntax(argument: expr,
                                                     trailingComma: nil)
                    arguments.append(arg)
                    break
                }
            } while true

            let argList = FunctionArgumentListSyntax(arguments: arguments)
            
            guard let rparen = accept(.rightParen) else {
                throw SyntaxError.missingRightParenthesis
            }

            return FunctionCallSyntax(name: ident,
                                      leftParen: lparen,
                                      arguments: argList,
                                      rightParen: rparen)
        }
        else {
            // We got a variable
            return VariableSyntax(variable: ident)
        }
    }
    
    /// Rule:
    ///
    ///     primary -> NUMBER | STRING | VARIABLE_OR_CALL | "(" expression ")" ;
    ///
    func primary() throws -> (any ExpressionSyntax)? {
        // TODO: true, false, nil
        if let node = number() {
            return node
        }
        else if let node = try variable_or_call() {
            return node
        }

        else if let lparen = accept(.leftParen) {
            if let expr = try expression() {
                guard let rparen = accept(.rightParen) else {
                    throw SyntaxError.missingRightParenthesis
                }
                return ParenthesisSyntax(leftParen: lparen,
                                         expression: expr,
                                         rightParen: rparen)
            }
        }
        return nil
    }
    
    /// Rule:
    ///
    ///     unary -> "-" unary | primary ;
    ///
    func unary() throws -> (any ExpressionSyntax)? {
        // TODO: Add '!'
        if let op = `operator`("-") {
            guard let right = try unary() else {
                throw SyntaxError.expressionExpected
            }
            return UnaryOperatorSyntax(op: op,
                                       operand: right)
        }
        else {
            return try primary()
        }
        
    }

    /// Rule:
    ///
    ///     factor -> unary ( ( "/" | "*" ) unary )* ;
    ///
    func factor() throws -> (any ExpressionSyntax)? {
        guard var left: any ExpressionSyntax = try unary() else {
            return nil
        }
        
        while let op = `operator`("*") ?? `operator`("/") ?? `operator`("%"){
            guard let right = try unary() else {
                throw SyntaxError.expressionExpected
            }
            left = BinaryOperatorSyntax(leftOperand: left,
                                         op: op,
                                         rightOperand: right)
        }
        
        return left
    }

    /// Rule:
    ///
    ///     term -> factor ( ( "-" | "+" ) factor )* ;
    ///
    func term() throws -> (any ExpressionSyntax)? {
        guard var left: any ExpressionSyntax = try factor() else {
            return nil
        }
        
        while let op = `operator`("+") ?? `operator`("-") {
            guard let right = try factor() else {
                throw SyntaxError.expressionExpected
            }
            left = BinaryOperatorSyntax(leftOperand: left,
                                         op: op,
                                         rightOperand: right)
        }
        
        return left
    }
    
    func expression() throws -> ExpressionSyntax? {
        return try term()
    }
    
    
    /// Parse the expression and return an unbound arithmetic expression.
    ///
    /// - Throws: `SyntaxError` when there is an issue with the expression.
    public func parse() throws -> UnboundExpression {
        guard let expr = try expression() else {
            throw SyntaxError.expressionExpected
        }
        
        if currentToken?.type != .empty {
            throw SyntaxError.unexpectedToken
        }
        return expr.toExpression()
    }
    
}
