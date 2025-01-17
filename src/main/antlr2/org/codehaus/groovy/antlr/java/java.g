/*
 *  Licensed to the Apache Software Foundation (ASF) under one
 *  or more contributor license agreements.  See the NOTICE file
 *  distributed with this work for additional information
 *  regarding copyright ownership.  The ASF licenses this file
 *  to you under the Apache License, Version 2.0 (the
 *  "License"); you may not use this file except in compliance
 *  with the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

// Note: Please don't use physical tabs.  Logical tabs for indent are width 4.
header {
package org.codehaus.groovy.antlr.java;
import org.codehaus.groovy.antlr.*;
import org.codehaus.groovy.antlr.parser.*;
import java.util.*;
import java.io.InputStream;
import java.io.Reader;
import antlr.InputBuffer;
import antlr.LexerSharedInputState;
}
 
/** Java 1.5 Recognizer
 *
 * Run 'java Main [-showtree] directory-full-of-java-files'
 *
 * [The -showtree option pops up a Swing frame that shows
 *  the AST constructed from the parser.]
 *
 * Run 'java Main <directory full of java files>'
 *
 * Contributing authors:
 *      Jeremy Rayner       groovy@ross-rayner.com
 *		John Mitchell		johnm@non.net
 *		Terence Parr		parrt@magelang.com
 *		John Lilley		jlilley@empathy.com
 *		Scott Stanchfield	thetick@magelang.com
 *		Markus Mohnen		mohnen@informatik.rwth-aachen.de
 *		Peter Williams		pete.williams@sun.com
 *		Allan Jacobs		Allan.Jacobs@eng.sun.com
 *		Steve Messick		messick@redhills.com
 *		John Pybus		john@pybus.org
 *
 * Version 1.00 December 9, 1997 -- initial release
 * Version 1.01 December 10, 1997
 *		fixed bug in octal def (0..7 not 0..8)
 * Version 1.10 August 1998 (parrt)
 *		added tree construction
 *		fixed definition of WS,comments for mac,pc,unix newlines
 *		added unary plus
 * Version 1.11 (Nov 20, 1998)
 *		Added "shutup" option to turn off last ambig warning.
 *		Fixed inner class def to allow named class defs as statements
 *		synchronized requires compound not simple statement
 *		add [] after builtInType DOT class in primaryExpression
 *		"const" is reserved but not valid..removed from modifiers
 * Version 1.12 (Feb 2, 1999)
 *		Changed LITERAL_xxx to xxx in tree grammar.
 *		Updated java.g to use tokens {...} now for 2.6.0 (new feature).
 *
 * Version 1.13 (Apr 23, 1999)
 *		Didn't have (stat)? for else clause in tree parser.
 *		Didn't gen ASTs for interface extends.  Updated tree parser too.
 *		Updated to 2.6.0.
 * Version 1.14 (Jun 20, 1999)
 *		Allowed final/abstract on local classes.
 *		Removed local interfaces from methods
 *		Put instanceof precedence where it belongs...in relationalExpr
 *			It also had expr not type as arg; fixed it.
 *		Missing ! on SEMI in classBlock
 *		fixed: (expr) + "string" was parsed incorrectly (+ as unary plus).
 *		fixed: didn't like Object[].class in parser or tree parser
 * Version 1.15 (Jun 26, 1999)
 *		Screwed up rule with instanceof in it. :(  Fixed.
 *		Tree parser didn't like (expr).something; fixed.
 *		Allowed multiple inheritance in tree grammar. oops.
 * Version 1.16 (August 22, 1999)
 *		Extending an interface built a wacky tree: had extra EXTENDS.
 *		Tree grammar didn't allow multiple superinterfaces.
 *		Tree grammar didn't allow empty var initializer: {}
 * Version 1.17 (October 12, 1999)
 *		ESC lexer rule allowed 399 max not 377 max.
 *		java.tree.g didn't handle the expression of synchronized
 *		statements.
 * Version 1.18 (August 12, 2001)
 *	  	Terence updated to Java 2 Version 1.3 by
 *		observing/combining work of Allan Jacobs and Steve
 *		Messick.  Handles 1.3 src.  Summary:
 *		o  primary didn't include boolean.class kind of thing
 *	  	o  constructor calls parsed explicitly now:
 * 		   see explicitConstructorInvocation
 *		o  add strictfp modifier
 *	  	o  missing objBlock after new expression in tree grammar
 *		o  merged local class definition alternatives, moved after declaration
 *		o  fixed problem with ClassName.super.field
 *	  	o  reordered some alternatives to make things more efficient
 *		o  long and double constants were not differentiated from int/float
 *		o  whitespace rule was inefficient: matched only one char
 *		o  add an examples directory with some nasty 1.3 cases
 *		o  made Main.java use buffered IO and a Reader for Unicode support
 *		o  supports UNICODE?
 *		   Using Unicode charVocabulay makes code file big, but only
 *		   in the bitsets at the end. I need to make ANTLR generate
 *		   unicode bitsets more efficiently.
 * Version 1.19 (April 25, 2002)
 *		Terence added in nice fixes by John Pybus concerning floating
 *		constants and problems with super() calls.  John did a nice
 *		reorg of the primary/postfix expression stuff to read better
 *		and makes f.g.super() parse properly (it was METHOD_CALL not
 *		a SUPER_CTOR_CALL).  Also:
 *
 *		o  "finally" clause was a root...made it a child of "try"
 *		o  Added stuff for asserts too for Java 1.4, but *commented out*
 *		   as it is not backward compatible.
 *
 * Version 1.20 (October 27, 2002)
 *
 *	  Terence ended up reorging John Pybus' stuff to
 *	  remove some nondeterminisms and some syntactic predicates.
 *	  Note that the grammar is stricter now; e.g., this(...) must
 *	be the first statement.
 *
 *	  Trinary ?: operator wasn't working as array name:
 *		  (isBig ? bigDigits : digits)[i];
 *
 *	  Checked parser/tree parser on source for
 *		  Resin-2.0.5, jive-2.1.1, jdk 1.3.1, Lucene, antlr 2.7.2a4,
 *		and the 110k-line jGuru server source.
 *
 * Version 1.21 (October 17, 2003)
 *  Fixed lots of problems including:
 *  Ray Waldin: add typeDefinition to interfaceBlock in java.tree.g
 *  He found a problem/fix with floating point that start with 0
 *  Ray also fixed problem that (int.class) was not recognized.
 *  Thorsten van Ellen noticed that \n are allowed incorrectly in strings.
 *  TJP fixed CHAR_LITERAL analogously.
 *
 * Version 1.21.2 (March, 2003)
 *	  Changes by Matt Quail to support generics (as per JDK1.5/JSR14)
 *	  Notes:
 *	  o We only allow the "extends" keyword and not the "implements"
 *		keyword, since thats what JSR14 seems to imply.
 *	  o Thanks to Monty Zukowski for his help on the antlr-interest
 *		mail list.
 *	  o Thanks to Alan Eliasen for testing the grammar over his
 *		Fink source base
 *
 * Version 1.22 (July, 2004)
 *	  Changes by Michael Studman to support Java 1.5 language extensions
 *	  Notes:
 *	  o Added support for annotations types
 *	  o Finished off Matt Quail's generics enhancements to support bound type arguments
 *	  o Added support for new for statement syntax
 *	  o Added support for static import syntax
 *	  o Added support for enum types
 *	  o Tested against JDK 1.5 source base and source base of jdigraph project
 *	  o Thanks to Matt Quail for doing the hard part by doing most of the generics work
 *
 * Version 1.22.1 (July 28, 2004)
 *	  Bug/omission fixes for Java 1.5 language support
 *	  o Fixed tree structure bug with classOrInterface - thanks to Pieter Vangorpto for
 *		spotting this
 *	  o Fixed bug where incorrect handling of SR and BSR tokens would cause type
 *		parameters to be recognised as type arguments.
 *	  o Enabled type parameters on constructors, annotations on enum constants
 *		and package definitions
 *	  o Fixed problems when parsing if ((char.class.equals(c))) {} - solution by Matt Quail at Cenqua
 *
 * Version 1.22.2 (July 28, 2004)
 *	  Slight refactoring of Java 1.5 language support
 *	  o Refactored for/"foreach" productions so that original literal "for" literal
 *	    is still used but the for sub-clauses vary by token type
 *	  o Fixed bug where type parameter was not included in generic constructor's branch of AST
 *
 * Version 1.22.3 (August 26, 2004)
 *	  Bug fixes as identified by Michael Stahl; clean up of tabs/spaces
 *        and other refactorings
 *	  o Fixed typeParameters omission in identPrimary and newStatement
 *	  o Replaced GT reconcilliation code with simple semantic predicate
 *	  o Adapted enum/assert keyword checking support from Michael Stahl's java15 grammar
 *	  o Refactored typeDefinition production and field productions to reduce duplication
 *
 * Version 1.22.4 (October 21, 2004)
 *    Small bux fixes
 *    o Added typeArguments to explicitConstructorInvocation, e.g. new <String>MyParameterised()
 *    o Added typeArguments to postfixExpression productions for anonymous inner class super
 *      constructor invocation, e.g. new Outer().<String>super()
 *    o Fixed bug in array declarations identified by Geoff Roy
 *
 * Version 1.22.4.j.1
 *	  Changes by Jeremy Rayner to support java2groovy tool
 *    o I have taken java.g for Java1.5 from Michael Studman (1.22.4)
 *      and have made some changes to enable use by java2groovy tool (Jan 2007)
 *
 * Based on an original grammar released in the PUBLIC DOMAIN
 */

class JavaRecognizer extends Parser;
options {
	k = 2;							// two token lookahead
	exportVocab=Java;				// Call its vocabulary "Java"
	codeGenMakeSwitchThreshold = 2;	// Some optimizations
	codeGenBitsetTestThreshold = 3;
	defaultErrorHandler = false;	// Don't generate parser error handlers
	buildAST = true;
}

tokens {
	BLOCK; MODIFIERS; OBJBLOCK; SLIST; METHOD_DEF; VARIABLE_DEF;
	INSTANCE_INIT; STATIC_INIT; TYPE; CLASS_DEF; INTERFACE_DEF;
	PACKAGE_DEF; ARRAY_DECLARATOR; EXTENDS_CLAUSE; IMPLEMENTS_CLAUSE;
	PARAMETERS; PARAMETER_DEF; LABELED_STAT; TYPECAST; INDEX_OP;
	POST_INC; POST_DEC; METHOD_CALL; EXPR; ARRAY_INIT;
	IMPORT; UNARY_MINUS; UNARY_PLUS; CASE_GROUP; ELIST; FOR_INIT; FOR_CONDITION;
	FOR_ITERATOR; EMPTY_STAT; FINAL="final"; ABSTRACT="abstract";
	STRICTFP="strictfp"; SUPER_CTOR_CALL; CTOR_CALL; VARIABLE_PARAMETER_DEF;
	STATIC_IMPORT; ENUM_DEF; ENUM_CONSTANT_DEF; FOR_EACH_CLAUSE; ANNOTATION_DEF; ANNOTATIONS;
	ANNOTATION; ANNOTATION_MEMBER_VALUE_PAIR; ANNOTATION_FIELD_DEF; ANNOTATION_ARRAY_INIT;
	TYPE_ARGUMENTS; TYPE_ARGUMENT; TYPE_PARAMETERS; TYPE_PARAMETER; WILDCARD_TYPE;
	TYPE_UPPER_BOUNDS; TYPE_LOWER_BOUNDS;
}

{
    /** This factory is the correct way to wire together a Groovy parser and lexer. */
    public static JavaRecognizer make(JavaLexer lexer) {
        JavaRecognizer parser = new JavaRecognizer(lexer.plumb());
        // TODO: set up a common error-handling control block, to avoid excessive tangle between these guys
        parser.lexer = lexer;
        lexer.parser = parser;
        parser.setASTNodeClass("org.codehaus.groovy.antlr.GroovySourceAST");
        return parser;
    }
    // Create a scanner that reads from the input stream passed to us...
    public static JavaRecognizer make(InputStream in) { return make(new JavaLexer(in)); }
    public static JavaRecognizer make(Reader in) { return make(new JavaLexer(in)); }
    public static JavaRecognizer make(InputBuffer in) { return make(new JavaLexer(in)); }
    public static JavaRecognizer make(LexerSharedInputState in) { return make(new JavaLexer(in)); }
    
    private static GroovySourceAST dummyVariableToforceClassLoaderToFindASTClass = new GroovySourceAST();
    
    JavaLexer lexer;
    public JavaLexer getLexer() { return lexer; }
    public void setFilename(String f) { super.setFilename(f); lexer.setFilename(f); }
    private SourceBuffer sourceBuffer;
    public void setSourceBuffer(SourceBuffer sourceBuffer) {
        this.sourceBuffer = sourceBuffer;
    }

    /** Create an AST node with the token type and text passed in, but
     *  with the same background information as another supplied Token (e.g. line numbers)
     * to be used in place of antlr tree construction syntax,
     * i.e. #[TOKEN,"text"]  becomes  create(TOKEN,"text",anotherToken)
     *
     * todo - change antlr.ASTFactory to do this instead...
     */
    public AST create(int type, String txt, Token first, Token last) {
        AST t = astFactory.create(type,txt);
        if ( t != null && first != null) {
            // first copy details from first token
            t.initialize(first);
            // then ensure that type and txt are specific to this new node
            t.initialize(type,txt);
        }

        if ((t instanceof GroovySourceAST) && last != null) {
            GroovySourceAST node = (GroovySourceAST)t;
            node.setLast(last);
            // This is a good point to call node.setSnippet(),
            // but it bulks up the AST too much for production code.
        }
        return t;
    }

    
    /**
	 * Counts the number of LT seen in the typeArguments production.
	 * It is used in semantic predicates to ensure we have seen
	 * enough closing '>' characters; which actually may have been
	 * either GT, SR or BSR tokens.
	 */
	private int ltCounter = 0;
}

// Compilation Unit: In Java, this is a single file. This is the start
// rule for this parser
compilationUnit
	:	// A compilation unit starts with an optional package definition
		(	(annotations "package")=> packageDefinition
		|	/* nothing */
		)

		// Next we have a series of zero or more import statements
		( importDefinition )*

		// Wrapping things up with any number of class or interface
		// definitions
		( typeDefinition )*

		EOF!
	;


// Package statement: optional annotations followed by "package" then the package identifier.
packageDefinition
	options {defaultErrorHandler = true;} // let ANTLR handle errors
	:	annotations p:"package"^ {#p.setType(PACKAGE_DEF);} identifier SEMI!
	;


// Import statement: import followed by a package or class name
importDefinition
	options {defaultErrorHandler = true;}
	{ boolean isStatic = false; }
	:	i:"import"^ {#i.setType(IMPORT);} ( "static"! {#i.setType(STATIC_IMPORT);} )? identifierStar SEMI!
	;

// A type definition is either a class, interface, enum or annotation with possible additional semis.
typeDefinition
	options {defaultErrorHandler = true;}
	:	m:modifiers!
		typeDefinitionInternal[#m]
	|	SEMI!
	;

// Protected type definitions production for reuse in other productions
protected typeDefinitionInternal[AST mods]
	:	classDefinition[#mods]		// inner class
	|	interfaceDefinition[#mods]	// inner interface
	|	enumDefinition[#mods]		// inner enum
	|	annotationDefinition[#mods]	// inner annotation
	;

// A declaration is the creation of a reference or primitive-type variable
// Create a separate Type/Var tree for each var in the var list.
declaration!
	:	m:modifiers t:typeSpec[false] v:variableDefinitions[#m,#t]
		{#declaration = #v;}
	;

// A type specification is a type name with possible brackets afterwards
// (which would make it an array type).
typeSpec[boolean addImagNode]
	:	classTypeSpec[addImagNode]
	|	builtInTypeSpec[addImagNode]
	;

// A class type specification is a class type with either:
// - possible brackets afterwards
//   (which would make it an array type).
// - generic type arguments after
classTypeSpec[boolean addImagNode]  {Token first = LT(1);}
	:	classOrInterfaceType[false]
		(options{greedy=true;}: // match as many as possible
			lb:LBRACK^ {#lb.setType(ARRAY_DECLARATOR);} RBRACK!
		)*
		{
			if ( addImagNode ) {
				#classTypeSpec = #(create(TYPE,"TYPE",first,LT(1)), #classTypeSpec);
			}
		}
	;

// A non-built in type name, with possible type parameters
classOrInterfaceType[boolean addImagNode]  {Token first = LT(1);}
	:	IDENT^ (typeArgumentsOrDiamond)?
		(options{greedy=true;}: // match as many as possible
			DOT^
			IDENT (typeArgumentsOrDiamond)?
		)*
		{
			if ( addImagNode ) {
				#classOrInterfaceType = #(create(TYPE,"TYPE",first,LT(1)), #classOrInterfaceType);
			}
		}
	;

// A specialised form of typeSpec where built in types must be arrays
typeArgumentSpec
	:	classTypeSpec[true]
	|	builtInTypeArraySpec[true]
	;

// A generic type argument is a class type, a possibly bounded wildcard type or a built-in type array
typeArgument  {Token first = LT(1);}
	:	(	typeArgumentSpec
		|	wildcardType
		)
		{#typeArgument = #(create(TYPE_ARGUMENT,"TYPE_ARGUMENT",first,LT(1)), #typeArgument);}
	;

// Wildcard type indicating all types (with possible constraint)
wildcardType
	:	q:QUESTION^ {#q.setType(WILDCARD_TYPE);}
		(("extends" | "super")=> typeArgumentBounds)?
	;

typeArgumentsOrDiamond
    :   LT! GT!
    |   typeArguments
    ;

// Type arguments to a class or interface type
typeArguments
{int currentLtLevel = 0;  Token first = LT(1);}
	:
		{currentLtLevel = ltCounter;}
		LT! {ltCounter++;}
		typeArgument
		(options{greedy=true;}: // match as many as possible
			{inputState.guessing !=0 || ltCounter == currentLtLevel + 1}?
			COMMA! typeArgument
		)*

		(	// turn warning off since Antlr generates the right code,
			// plus we have our semantic predicate below
			options{generateAmbigWarnings=false;}:
			typeArgumentsOrParametersEnd
		)?

		// make sure we have gobbled up enough '>' characters
		// if we are at the "top level" of nested typeArgument productions
		{(currentLtLevel != 0) || ltCounter == currentLtLevel}?

		{#typeArguments = #(create(TYPE_ARGUMENTS,"TYPE_ARGUMENTS",first,LT(1)), #typeArguments);}
	;

// this gobbles up *some* amount of '>' characters, and counts how many
// it gobbled.
protected typeArgumentsOrParametersEnd
	:	GT! {ltCounter-=1;}
	|	SR! {ltCounter-=2;}
	|	BSR! {ltCounter-=3;}
	;

// Restriction on wildcard types based on super class or derrived class
typeArgumentBounds
	{boolean isUpperBounds = false;  Token first = LT(1);}
	:
		( "extends"! {isUpperBounds=true;} | "super"! ) classOrInterfaceType[false]
		{
			if (isUpperBounds)
			{
				#typeArgumentBounds = #(create(TYPE_UPPER_BOUNDS,"TYPE_UPPER_BOUNDS",first,LT(1)), #typeArgumentBounds);
			}
			else
			{
				#typeArgumentBounds = #(create(TYPE_LOWER_BOUNDS,"TYPE_LOWER_BOUNDS",first,LT(1)), #typeArgumentBounds);
			}
		}
	;

// A builtin type array specification is a builtin type with brackets afterwards
builtInTypeArraySpec[boolean addImagNode]  {Token first = LT(1);}
	:	builtInType
		(options{greedy=true;}: // match as many as possible
			lb:LBRACK^ {#lb.setType(ARRAY_DECLARATOR);} RBRACK!
		)+

		{
			if ( addImagNode ) {
				#builtInTypeArraySpec = #(create(TYPE,"TYPE",first,LT(1)), #builtInTypeArraySpec);
			}
		}
	;

// A builtin type specification is a builtin type with possible brackets
// afterwards (which would make it an array type).
builtInTypeSpec[boolean addImagNode]  {Token first = LT(1);}
	:	builtInType
		(options{greedy=true;}: // match as many as possible
			lb:LBRACK^ {#lb.setType(ARRAY_DECLARATOR);} RBRACK!
		)*
		{
			if ( addImagNode ) {
				#builtInTypeSpec = #(create(TYPE,"TYPE",first,LT(1)), #builtInTypeSpec);
			}
		}
	;

// A type name. which is either a (possibly qualified and parameterized)
// class name or a primitive (builtin) type
type
	:	classOrInterfaceType[false]
	|	builtInType
	;

// The primitive types.
builtInType
	:	"void"
	|	"boolean"
	|	"byte"
	|	"char"
	|	"short"
	|	"int"
	|	"float"
	|	"long"
	|	"double"
	;

// A (possibly-qualified) java identifier. We start with the first IDENT
// and expand its name by adding dots and following IDENTS
identifier
	:	IDENT ( DOT^ IDENT )*
	;

identifierStar
	:	IDENT
		( DOT^ IDENT )*
		( DOT^ STAR )?
	;

// A list of zero or more modifiers. We could have used (modifier)* in
// place of a call to modifiers, but I thought it was a good idea to keep
// this rule separate so they can easily be collected in a Vector if
// someone so desires
modifiers {Token first = LT(1);}
	:
		(
			//hush warnings since the semantic check for "@interface" solves the non-determinism
			options{generateAmbigWarnings=false;}:

			modifier
			|
			//Semantic check that we aren't matching @interface as this is not an annotation
			//A nicer way to do this would be nice
			{LA(1)==AT && !LT(2).getText().equals("interface")}? annotation
		)*

		{#modifiers = #(create(MODIFIERS, "MODIFIERS",first,LT(1)), #modifiers);}
	;

// modifiers for Java classes, interfaces, class/instance vars and methods
modifier
	:	"private"
	|	"public"
	|	"protected"
	|	"static"
	|	"transient"
	|	"final"
	|	"abstract"
	|	"native"
	|	"threadsafe"
	|	"synchronized"
	|	"volatile"
	|	"strictfp"
	;

annotation!  {Token first = LT(1);}
	:	AT! i:identifier ( LPAREN! ( args:annotationArguments )? RPAREN! )?
		{#annotation = #(create(ANNOTATION,"ANNOTATION",first,LT(1)), i, args);}
	;

annotations  {Token first = LT(1);}
    :   (annotation)*
		{#annotations = #([ANNOTATIONS, "ANNOTATIONS"], #annotations);}
    ;

annotationArguments
	:	annotationMemberValueInitializer | anntotationMemberValuePairs
	;

anntotationMemberValuePairs
	:	annotationMemberValuePair ( COMMA! annotationMemberValuePair )*
	;

annotationMemberValuePair!  {Token first = LT(1);}
	:	i:IDENT ASSIGN! v:annotationMemberValueInitializer
		{#annotationMemberValuePair = #(create(ANNOTATION_MEMBER_VALUE_PAIR,"ANNOTATION_MEMBER_VALUE_PAIR",first,LT(1)), i, v);}
	;

annotationMemberValueInitializer
	:
		conditionalExpression | annotation | annotationMemberArrayInitializer
	;

// This is an initializer used to set up an annotation member array.
annotationMemberArrayInitializer
	:	lc:LCURLY^ {#lc.setType(ANNOTATION_ARRAY_INIT);}
			(	annotationMemberArrayValueInitializer
				(
					// CONFLICT: does a COMMA after an initializer start a new
					// initializer or start the option ',' at end?
					// ANTLR generates proper code by matching
					// the comma as soon as possible.
					options {
						warnWhenFollowAmbig = false;
					}
				:
					COMMA! annotationMemberArrayValueInitializer
				)*
				(COMMA!)?
			)?
		RCURLY!
	;

// The two things that can initialize an annotation array element are a conditional expression
// and an annotation (nested annotation array initialisers are not valid)
annotationMemberArrayValueInitializer
	:	conditionalExpression
	|	annotation
	;

superClassClause!  {Token first = LT(1);}
	:	( "extends" c:classOrInterfaceType[false] )?
		{#superClassClause = #(create(EXTENDS_CLAUSE,"EXTENDS_CLAUSE",first,LT(1)),c);}
	;

// Definition of a Java class
classDefinition![AST modifiers] {Token first = LT(1);}
	:	"class" IDENT
		// it _might_ have type paramaters
		(tp:typeParameters)?
		// it _might_ have a superclass...
		sc:superClassClause
		// it might implement some interfaces...
		ic:implementsClause
		// now parse the body of the class
		cb:classBlock
		{#classDefinition = #(create(CLASS_DEF,"CLASS_DEF",first,LT(1)),
								modifiers,IDENT,tp,sc,ic,cb);}
	;

// Definition of a Java Interface
interfaceDefinition![AST modifiers]  {Token first = LT(1);}
	:	"interface" IDENT
		// it _might_ have type paramaters
		(tp:typeParameters)?
		// it might extend some other interfaces
		ie:interfaceExtends
		// now parse the body of the interface (looks like a class...)
		ib:interfaceBlock
		{#interfaceDefinition = #(create(INTERFACE_DEF,"INTERFACE_DEF",first,LT(1)),
									modifiers,IDENT,tp,ie,ib);}
	;

enumDefinition![AST modifiers]  {Token first = LT(1);}
	:	"enum" IDENT
		// it might implement some interfaces...
		ic:implementsClause
		// now parse the body of the enum
		eb:enumBlock
		{#enumDefinition = #(create(ENUM_DEF,"ENUM_DEF",first,LT(1)),
								modifiers,IDENT,ic,eb);}
	;

annotationDefinition![AST modifiers]  {Token first = LT(1);}
	:	AT "interface" IDENT
		// now parse the body of the annotation
		ab:annotationBlock
		{#annotationDefinition = #(create(ANNOTATION_DEF,"ANNOTATION_DEF",first,LT(1)),
									modifiers,IDENT,ab);}
	;

typeParameters
{int currentLtLevel = 0; Token first = LT(1);}
	:
		{currentLtLevel = ltCounter;}
		LT! {ltCounter++;}
		typeParameter (COMMA! typeParameter)*
		(typeArgumentsOrParametersEnd)?

		// make sure we have gobbled up enough '>' characters
		// if we are at the "top level" of nested typeArgument productions
		{(currentLtLevel != 0) || ltCounter == currentLtLevel}?

		{#typeParameters = #(create(TYPE_PARAMETERS,"TYPE_PARAMETERS",first,LT(1)), #typeParameters);}
	;

typeParameter   {Token first = LT(1);}
	:
		// I'm pretty sure Antlr generates the right thing here:
		(id:IDENT) ( options{generateAmbigWarnings=false;}: typeParameterBounds )?
		{#typeParameter = #(create(TYPE_PARAMETER,"TYPE_PARAMETER",first,LT(1)), #typeParameter);}
	;

typeParameterBounds  {Token first = LT(1);}
	:
		"extends"! classOrInterfaceType[false]
		(BAND! classOrInterfaceType[false])*
		{#typeParameterBounds = #(create(TYPE_UPPER_BOUNDS,"TYPE_UPPER_BOUNDS",first,LT(1)), #typeParameterBounds);}
	;

// This is the body of a class. You can have classFields and extra semicolons.
classBlock
	:	LCURLY!
			( classField | SEMI! )*
		RCURLY!
		{#classBlock = #([OBJBLOCK, "OBJBLOCK"], #classBlock);}
	;

// This is the body of an interface. You can have interfaceField and extra semicolons.
interfaceBlock
	:	LCURLY!
			( interfaceField | SEMI! )*
		RCURLY!
		{#interfaceBlock = #([OBJBLOCK, "OBJBLOCK"], #interfaceBlock);}
	;
	
// This is the body of an annotation. You can have annotation fields and extra semicolons,
// That's about it (until you see what an annoation field is...)
annotationBlock
	:	LCURLY!
		( annotationField | SEMI! )*
		RCURLY!
		{#annotationBlock = #([OBJBLOCK, "OBJBLOCK"], #annotationBlock);}
	;

// This is the body of an enum. You can have zero or more enum constants
// followed by any number of fields like a regular class
enumBlock
	:	LCURLY!
			( enumConstant ( options{greedy=true;}: COMMA! enumConstant )* ( COMMA! )? )?
			( SEMI! ( classField | SEMI! )* )?
		RCURLY!
		{#enumBlock = #([OBJBLOCK, "OBJBLOCK"], #enumBlock);}
	;

// An annotation field
annotationField!  {Token first = LT(1);}
	:	mods:modifiers
		(	td:typeDefinitionInternal[#mods]
			{#annotationField = #td;}
		|	t:typeSpec[false]		// annotation field
			(	i:IDENT				// the name of the field

				LPAREN! RPAREN!

				rt:declaratorBrackets[#t]

				( "default" amvi:annotationMemberValueInitializer )?

				SEMI

				{#annotationField =
					#(create(ANNOTATION_FIELD_DEF,"ANNOTATION_FIELD_DEF",first,LT(1)),
						 mods,
						 #(create(TYPE,"TYPE",first,LT(1)),rt),
						 i,amvi
						 );}
			|	v:variableDefinitions[#mods,#t] SEMI	// variable
				{#annotationField = #v;}
			)
		)
	;

//An enum constant may have optional parameters and may have a
//a class body
enumConstant!
	:	an:annotations
		i:IDENT
		(	LPAREN!
			a:argList
			RPAREN!
		)?
		( b:enumConstantBlock )?
		{#enumConstant = #([ENUM_CONSTANT_DEF, "ENUM_CONSTANT_DEF"], an, i, a, b);}
	;

//The class-like body of an enum constant
enumConstantBlock
	:	LCURLY!
		( enumConstantField | SEMI! )*
		RCURLY!
		{#enumConstantBlock = #([OBJBLOCK, "OBJBLOCK"], #enumConstantBlock);}
	;

//An enum constant field is just like a class field but without
//the posibility of a constructor definition or a static initializer
enumConstantField! {Token first = LT(1);}
	:	mods:modifiers
		(	td:typeDefinitionInternal[#mods]
			{#enumConstantField = #td;}

		|	// A generic method has the typeParameters before the return type.
			// This is not allowed for variable definitions, but this production
			// allows it, a semantic check could be used if you wanted.
			(tp:typeParameters)? t:typeSpec[false]		// method or variable declaration(s)
			(	IDENT									// the name of the method

				// parse the formal parameter declarations.
				LPAREN! param:parameterDeclarationList RPAREN!

				rt:declaratorBrackets[#t]

				// get the list of exceptions that this method is
				// declared to throw
				(tc:throwsClause)?

				( s2:compoundStatement | SEMI )
				{#enumConstantField = #(create(METHOD_DEF,"METHOD_DEF",first,LT(1)),
							 mods,
							 tp,
							 #(create(TYPE,"TYPE",first,LT(1)),rt),
							 IDENT,
							 param,
							 tc,
							 s2);}
			|	v:variableDefinitions[#mods,#t] SEMI
				{#enumConstantField = #v;}
			)
		)

	// "{ ... }" instance initializer
	|	s4:compoundStatement
		{#enumConstantField = #(create(INSTANCE_INIT,"INSTANCE_INIT",first,LT(1)), s4);}
	;

// An interface can extend several other interfaces...
interfaceExtends  {Token first = LT(1);}
	:	(
		e:"extends"!
		classOrInterfaceType[false] ( COMMA! classOrInterfaceType[false] )*
		)?
		{#interfaceExtends = #(create(EXTENDS_CLAUSE,"EXTENDS_CLAUSE",first,LT(1)),
								#interfaceExtends);}
	;

// A class can implement several interfaces...
implementsClause  {Token first = LT(1);}
	:	(
			i:"implements"! classOrInterfaceType[false] ( COMMA! classOrInterfaceType[false] )*
		)?
		{#implementsClause = #(create(IMPLEMENTS_CLAUSE,"IMPLEMENTS_CLAUSE",first,LT(1)),
								 #implementsClause);}
	;

// Now the various things that can be defined inside a class
classField!   {Token first = LT(1);}
	:	// method, constructor, or variable declaration
		mods:modifiers
		(	td:typeDefinitionInternal[#mods]
			{#classField = #td;}

		|	(tp:typeParameters)?
			(
				h:ctorHead s:constructorBody // constructor
				// just treat CTOR_DEF like METHOD_DEF for java2groovy
				{#classField = #(create(METHOD_DEF,"METHOD_DEF",first,LT(1)), mods, tp, h, s);}

				|	// A generic method/ctor has the typeParameters before the return type.
					// This is not allowed for variable definitions, but this production
					// allows it, a semantic check could be used if you wanted.
					t:typeSpec[false]		// method or variable declaration(s)
					(	IDENT				// the name of the method

						// parse the formal parameter declarations.
						LPAREN! param:parameterDeclarationList RPAREN!

						rt:declaratorBrackets[#t]

						// get the list of exceptions that this method is
						// declared to throw
						(tc:throwsClause)?

						( s2:compoundStatement | SEMI )
						{#classField = #(create(METHOD_DEF,"METHOD_DEF",first,LT(1)),
									 mods,
									 tp,
									 #(create(TYPE,"TYPE",first,LT(1)),rt),
									 IDENT,
									 param,
									 tc,
									 s2);}
					|	v:variableDefinitions[#mods,#t] SEMI
						{#classField = #v;}
					)
			)
		)

	// "static { ... }" class initializer
	|	"static" s3:compoundStatement
		{#classField = #(create(STATIC_INIT,"STATIC_INIT",first,LT(1)), s3);}

	// "{ ... }" instance initializer
	|	s4:compoundStatement
		{#classField = #(create(INSTANCE_INIT,"INSTANCE_INIT",first,LT(1)), s4);}
	;

// Now the various things that can be defined inside a interface
interfaceField!    {Token first = LT(1);}
	:	// method, constructor, or variable declaration
		mods:modifiers
		(	td:typeDefinitionInternal[#mods]
			{#interfaceField = #td;}

		|	(tp:typeParameters)?
			// A generic method has the typeParameters before the return type.
			// This is not allowed for variable definitions, but this production
			// allows it, a semantic check could be used if you want a more strict
			// grammar.
			("default"!)?          // just to keep groovydoc parsing happy
			t:typeSpec[false]		// method or variable declaration(s)
			(	IDENT				// the name of the method

				// parse the formal parameter declarations.
				LPAREN! param:parameterDeclarationList RPAREN!

				rt:declaratorBrackets[#t]

				// get the list of exceptions that this method is
				// declared to throw
				(tc:throwsClause)?

				SEMI
				
				{#interfaceField = #(create(METHOD_DEF,"METHOD_DEF",first,LT(1)),
							 mods,
							 tp,
							 #(create(TYPE,"TYPE",first,LT(1)),rt),
							 IDENT,
							 param,
							 tc);}
			|	v:variableDefinitions[#mods,#t] SEMI
				{#interfaceField = #v;}
			)
		)
	;

constructorBody
	:	lc:LCURLY^ {#lc.setType(SLIST);}
			( options { greedy=true; } : explicitConstructorInvocation)?
			(statement)*
		RCURLY!
	;

/** Catch obvious constructor calls, but not the expr.super(...) calls */
explicitConstructorInvocation
	:	(typeArguments)?
		(	"this"! lp1:LPAREN^ argList RPAREN! SEMI!
			{#lp1.setType(CTOR_CALL);}
		|	"super"! lp2:LPAREN^ argList RPAREN! SEMI!
			{#lp2.setType(SUPER_CTOR_CALL);}
		)
	;

variableDefinitions[AST mods, AST t]
	:	variableDeclarator[getASTFactory().dupTree(mods),
							getASTFactory().dupTree(t)]
		(	COMMA!
			variableDeclarator[getASTFactory().dupTree(mods),
							getASTFactory().dupTree(t)]
		)*
	;

/** Declaration of a variable. This can be a class/instance variable,
 *  or a local variable in a method
 *  It can also include possible initialization.
 */
variableDeclarator![AST mods, AST t] { Token first = LT(1);}
	:	id:IDENT d:declaratorBrackets[t] v:varInitializer
		{#variableDeclarator = #(create(VARIABLE_DEF,"VARIABLE_DEF",first,LT(1)), mods, #(create(TYPE,"TYPE",first,LT(1)),d), id, v);}
	;

declaratorBrackets[AST typ]
	:	{#declaratorBrackets=typ;}
		(lb:LBRACK^ {#lb.setType(ARRAY_DECLARATOR);} RBRACK!)*
	;

varInitializer
	:	( ASSIGN^ initializer )?
	;

// This is an initializer used to set up an array.
arrayInitializer
	:	lc:LCURLY^ {#lc.setType(ARRAY_INIT);}
			(	initializer
				(
					// CONFLICT: does a COMMA after an initializer start a new
					// initializer or start the option ',' at end?
					// ANTLR generates proper code by matching
					// the comma as soon as possible.
					options {
						warnWhenFollowAmbig = false;
					}
				:
					COMMA! initializer
				)*
				(COMMA!)?
			)?
		RCURLY!
	;

// The two "things" that can initialize an array element are an expression
// and another (nested) array initializer.
initializer
	:	expression
	|	arrayInitializer
	;

// This is the header of a method. It includes the name and parameters
// for the method.
// This also watches for a list of exception classes in a "throws" clause.
ctorHead
	:	IDENT // the name of the method

		// parse the formal parameter declarations.
		LPAREN! parameterDeclarationList RPAREN!

		// get the list of exceptions that this method is declared to throw
		(throwsClause)?
	;

// This is a list of exception classes that the method is declared to throw
throwsClause
	:	"throws"^ identifier ( COMMA! identifier )*
	;

// A list of formal parameters
//	 Zero or more parameters
//	 If a parameter is variable length (e.g. String... myArg) it is the right-most parameter
parameterDeclarationList {Token first = LT(1);}
	// The semantic check in ( .... )* block is flagged as superfluous, and seems superfluous but
	// is the only way I could make this work. If my understanding is correct this is a known bug
	:	(	( parameterDeclaration )=> parameterDeclaration
			( options {warnWhenFollowAmbig=false;} : ( COMMA! parameterDeclaration ) => COMMA! parameterDeclaration )*
			( COMMA! variableLengthParameterDeclaration )?
		|
			variableLengthParameterDeclaration
		)?
		{#parameterDeclarationList = #(create(PARAMETERS,"PARAMETERS",first,LT(1)),
                						#parameterDeclarationList);}
	;

// A formal parameter.
parameterDeclaration! {Token first = LT(1);}
	:	pm:parameterModifier t:typeSpec[false] id:IDENT
		pd:declaratorBrackets[#t]
		{#parameterDeclaration = #(create(PARAMETER_DEF,"PARAMETER_DEF",first,LT(1)),
									pm, #(create(TYPE,"TYPE",first,LT(1)),pd), id);}
	;

variableLengthParameterDeclaration!  {Token first = LT(1);}
	:	pm:parameterModifier t:typeSpec[false] TRIPLE_DOT! id:IDENT
		pd:declaratorBrackets[#t]
		{#variableLengthParameterDeclaration = #(create(VARIABLE_PARAMETER_DEF,"VARIABLE_PARAMETER_DEF",first,LT(1)),
												pm, #(create(TYPE,"TYPE",first,LT(1)),pd), id);}
	;

parameterModifier  {Token first = LT(1);}
	//final can appear amongst annotations in any order - greedily consume any preceding
	//annotations to shut nond-eterminism warnings off
	:	(options{greedy=true;} : annotation)* (f:"final")? (annotation)*
		{#parameterModifier = #(create(MODIFIERS,"MODIFIERS",first,LT(1)), #parameterModifier);}
	;

// Compound statement. This is used in many contexts:
// Inside a class definition prefixed with "static":
// it is a class initializer
// Inside a class definition without "static":
// it is an instance initializer
// As the body of a method
// As a completely indepdent braced block of code inside a method
// it starts a new scope for variable definitions

compoundStatement
	:	lc:LCURLY^ {#lc.setType(SLIST);}
			// include the (possibly-empty) list of statements
			(statement)*
		RCURLY!
	;


statement
	// A list of statements in curly braces -- start a new scope!
	:	compoundStatement

	// declarations are ambiguous with "ID DOT" relative to expression
	// statements. Must backtrack to be sure. Could use a semantic
	// predicate to test symbol table to see what the type was coming
	// up, but that's pretty hard without a symbol table ;)
	|	(declaration)=> declaration SEMI!

	// An expression statement. This could be a method call,
	// assignment statement, or any other expression evaluated for
	// side-effects.
	|	expression SEMI!

	//TODO: what abour interfaces, enums and annotations
	// class definition
	|	m:modifiers! classDefinition[#m]

	// Attach a label to the front of a statement
	|	IDENT c:COLON^ {#c.setType(LABELED_STAT);} statement

	// If-else statement
	|	"if"^ LPAREN! expression RPAREN! statement
		(
			// CONFLICT: the old "dangling-else" problem...
			// ANTLR generates proper code matching
			// as soon as possible. Hush warning.
			options {
				warnWhenFollowAmbig = false;
			}
		:
			"else"! statement
		)?

	// For statement
	|	forStatement

	// While statement
	|	"while"^ LPAREN! expression RPAREN! statement

	// do-while statement
	|	"do"^ statement "while"! LPAREN! expression RPAREN! SEMI!

	// get out of a loop (or switch)
	|	"break"^ (IDENT)? SEMI!

	// do next iteration of a loop
	|	"continue"^ (IDENT)? SEMI!

	// Return an expression
	|	"return"^ (expression)? SEMI!

	// switch/case statement
	|	"switch"^ LPAREN! expression RPAREN! LCURLY!
			( casesGroup )*
		RCURLY!

	// exception try-catch block
	|	tryBlock

	// throw an exception
	|	"throw"^ expression SEMI!

	// synchronize a statement
	|	"synchronized"^ LPAREN! expression RPAREN! compoundStatement

	// asserts (uncomment if you want 1.4 compatibility)
	|	"assert"^ expression ( COLON! expression )? SEMI!

	// empty statement
	|	s:SEMI {#s.setType(EMPTY_STAT);}
	;

forStatement
	:	f:"for"^
		LPAREN!
			(	(forInit SEMI)=>traditionalForClause
			|	forEachClause
			)
		RPAREN!
		statement					 // statement to loop over
	;

traditionalForClause
	:
		forInit SEMI!	// initializer
		forCond SEMI!	// condition test
		forIter			// updater
	;

forEachClause  {Token first = LT(1);}
	:
		p:parameterDeclaration COLON! expression
		{#forEachClause = #(create(FOR_EACH_CLAUSE,"FOR_EACH_CLAUSE",first,LT(1)), #forEachClause);}
	;

casesGroup
	:	(	// CONFLICT: to which case group do the statements bind?
			// ANTLR generates proper code: it groups the
			// many "case"/"default" labels together then
			// follows them with the statements
			options {
				greedy = true;
			}
			:
			aCase
		)+
		caseSList
		{#casesGroup = #([CASE_GROUP, "CASE_GROUP"], #casesGroup);}
	;

aCase
	:	("case"^ expression | "default") COLON!
	;

caseSList  {Token first = LT(1);}
	:	(statement)*
		{#caseSList = #(create(SLIST,"SLIST",first,LT(1)),#caseSList);}
	;

// The initializer for a for loop
forInit  {Token first = LT(1);}
		// if it looks like a declaration, it is
	:	((declaration)=> declaration
		// otherwise it could be an expression list...
		|	expressionList
		)?
		{#forInit = #(create(FOR_INIT,"FOR_INIT",first,LT(1)),#forInit);}
	;

forCond  {Token first = LT(1);}
	:	(expression)?
		{#forCond = #(create(FOR_CONDITION,"FOR_CONDITION",first,LT(1)),#forCond);}
	;

forIter  {Token first = LT(1);}
	:	(expressionList)?
		{#forIter = #(create(FOR_ITERATOR,"FOR_ITERATOR",first,LT(1)),#forIter);}
	;

// an exception handler try/catch block
// TODO currently handles try-with-resources only enough for groovydoc, not java2groovy
// plan is to switch java2groovy over to using parrot parser (or some other alternative)
tryBlock
	:	"try"^ ((LPAREN) => resources!)? compoundStatement
		(handler)*
		( finallyClause )?
	;

resources
    :   LPAREN! resourceList (SEMI!)? RPAREN!
    ;

resourceList
    :   resource (SEMI! resource)*
    ;

resource
    : (declaration) => declaration
	| expression
    ;

finallyClause
	:	"finally"^ compoundStatement
	;

// an exception handler borrowed from groovy.g to handle Java7+ multi-catch
handler {Token first = LT(1);}
    :   "catch"! LPAREN! pd:multicatch! RPAREN! handlerCs:compoundStatement!
        {#handler = #(create(LITERAL_catch,"catch",first,LT(1)),pd,handlerCs);}
    ;

multicatch_types
{Token first = LT(1);}
    :
        classOrInterfaceType[false]
        (
            BOR! classOrInterfaceType[false]
        )*
    ;

multicatch
{Token first = LT(1);}
    :   (FINAL)? (m:multicatch_types) id:IDENT!
    ;


// expressions
// Note that most of these expressions follow the pattern
//   thisLevelExpression :
//	   nextHigherPrecedenceExpression
//		   (OPERATOR nextHigherPrecedenceExpression)*
// which is a standard recursive definition for a parsing an expression.
// The operators in java have the following precedences:
//	lowest  (13)  = *= /= %= += -= <<= >>= >>>= &= ^= |=
//			(12)  ?:
//			(11)  ||
//			(10)  &&
//			( 9)  |
//			( 8)  ^
//			( 7)  &
//			( 6)  == !=
//			( 5)  < <= > >=
//			( 4)  << >>
//			( 3)  +(binary) -(binary)
//			( 2)  * / %
//			( 1)  ++ -- +(unary) -(unary)  ~  !  (type)
//				  []   () (method call)  . (dot -- identifier qualification)
//				  new   ()  (explicit parenthesis)
//
// the last two are not usually on a precedence chart; I put them in
// to point out that new has a higher precedence than '.', so you
// can validy use
//	 new Frame().show()
//
// Note that the above precedence levels map to the rules below...
// Once you have a precedence chart, writing the appropriate rules as below
//   is usually very straightfoward



// the mother of all expressions
expression  {Token first = LT(1);}
	:	assignmentExpression
		{#expression = #(create(EXPR,"EXPR",first,LT(1)),#expression);}
	;


// This is a list of expressions.
expressionList  {Token first = LT(1);}
	:	expression (COMMA! expression)*
		{#expressionList = #(create(ELIST,"ELIST",first,LT(1)), #expressionList);}
	;


// assignment expression (level 13)
assignmentExpression
	:	conditionalExpression
		(	(	ASSIGN^
			|	PLUS_ASSIGN^
			|	MINUS_ASSIGN^
			|	STAR_ASSIGN^
			|	DIV_ASSIGN^
			|	MOD_ASSIGN^
			|	SR_ASSIGN^
			|	BSR_ASSIGN^
			|	SL_ASSIGN^
			|	BAND_ASSIGN^
			|	BXOR_ASSIGN^
			|	BOR_ASSIGN^
			)
			assignmentExpression
		)?
	;


// conditional test (level 12)
conditionalExpression
	:	logicalOrExpression
		( QUESTION^ assignmentExpression COLON! conditionalExpression )?
	;


// logical or (||) (level 11)
logicalOrExpression
	:	logicalAndExpression (LOR^ logicalAndExpression)*
	;


// logical and (&&) (level 10)
logicalAndExpression
	:	inclusiveOrExpression (LAND^ inclusiveOrExpression)*
	;


// bitwise or non-short-circuiting or (|) (level 9)
inclusiveOrExpression
	:	exclusiveOrExpression (BOR^ exclusiveOrExpression)*
	;


// exclusive or (^) (level 8)
exclusiveOrExpression
	:	andExpression (BXOR^ andExpression)*
	;


// bitwise or non-short-circuiting and (&) (level 7)
andExpression
	:	equalityExpression (BAND^ equalityExpression)*
	;


// equality/inequality (==/!=) (level 6)
equalityExpression
	:	relationalExpression ((NOT_EQUAL^ | EQUAL^) relationalExpression)*
	;


// boolean relational expressions (level 5)
relationalExpression
	:	shiftExpression
		(	(	(	LT^
				|	GT^
				|	LE^
				|	GE^
				)
				shiftExpression
			)*
		|	"instanceof"^ typeSpec[true]
		)
	;


// bit shift expressions (level 4)
shiftExpression
	:	additiveExpression ((SL^ | SR^ | BSR^) additiveExpression)*
	;


// binary addition/subtraction (level 3)
additiveExpression
	:	multiplicativeExpression ((PLUS^ | MINUS^) multiplicativeExpression)*
	;


// multiplication/division/modulo (level 2)
multiplicativeExpression
	:	unaryExpression ((STAR^ | DIV^ | MOD^ ) unaryExpression)*
	;

unaryExpression
	:	INC^ unaryExpression
	|	DEC^ unaryExpression
	|	MINUS^ {#MINUS.setType(UNARY_MINUS);} unaryExpression
	|	PLUS^ {#PLUS.setType(UNARY_PLUS);} unaryExpression
	|	unaryExpressionNotPlusMinus
	;

unaryExpressionNotPlusMinus
	:	BNOT^ unaryExpression
	|	LNOT^ unaryExpression
	|	(	// subrule allows option to shut off warnings
			options {
				// "(int" ambig with postfixExpr due to lack of sequence
				// info in linear approximate LL(k). It's ok. Shut up.
				generateAmbigWarnings=false;
			}
		:	// If typecast is built in type, must be numeric operand
			// Have to backtrack to see if operator follows
		(LPAREN builtInTypeSpec[true] RPAREN unaryExpression)=>
		lpb:LPAREN^ {#lpb.setType(TYPECAST);} builtInTypeSpec[true] RPAREN!
		unaryExpression

		// Have to backtrack to see if operator follows. If no operator
		// follows, it's a typecast. No semantic checking needed to parse.
		// if it _looks_ like a cast, it _is_ a cast; else it's a "(expr)"
	|	(LPAREN classTypeSpec[true] RPAREN unaryExpressionNotPlusMinus)=>
		lp:LPAREN^ {#lp.setType(TYPECAST);} classTypeSpec[true] RPAREN!
		unaryExpressionNotPlusMinus

	|	postfixExpression
	)
	;

// qualified names, array expressions, method invocation, post inc/dec
postfixExpression
	:
		primaryExpression

		(
			/*
			options {
				// the use of postfixExpression in SUPER_CTOR_CALL adds DOT
				// to the lookahead set, and gives loads of false non-det
				// warnings.
				// shut them off.
				generateAmbigWarnings=false;
			}
		:	*/
			//type arguments are only appropriate for a parameterized method/ctor invocations
			//semantic check may be needed here to ensure that this is the case
			DOT^ (typeArguments)?
				(	IDENT
					(	lp:LPAREN^ {#lp.setType(METHOD_CALL);}
						argList
						RPAREN!
					)?
				|	"super"
					(	// (new Outer()).super() (create enclosing instance)
						lp3:LPAREN^ argList RPAREN!
						{#lp3.setType(SUPER_CTOR_CALL);}
					|	DOT^ (typeArguments)? IDENT
						(	lps:LPAREN^ {#lps.setType(METHOD_CALL);}
							argList
							RPAREN!
						)?
					)
				)
		|	DOT^ "this"
		|	DOT^ newExpression
		|	lb:LBRACK^ {#lb.setType(INDEX_OP);} expression RBRACK!
		)*

		(	// possibly add on a post-increment or post-decrement.
			// allows INC/DEC on too much, but semantics can check
			in:INC^ {#in.setType(POST_INC);}
	 	|	de:DEC^ {#de.setType(POST_DEC);}
		)?
 	;

// the basic element of an expression
primaryExpression
	:	identPrimary ( options {greedy=true;} : DOT^ "class" )?
	|	constant
	|	"true"
	|	"false"
	|	"null"
	|	newExpression
	|	"this"
	|	"super"
	|	LPAREN! assignmentExpression RPAREN!
		// look for int.class and int[].class
	|	builtInType
		( lbt:LBRACK^ {#lbt.setType(ARRAY_DECLARATOR);} RBRACK! )*
		DOT^ "class"
	;

/** Match a, a.b.c refs, a.b.c(...) refs, a.b.c[], a.b.c[].class,
 *  and a.b.c.class refs. Also this(...) and super(...). Match
 *  this or super.
 */
identPrimary
	:	(ta1:typeArguments!)?
		IDENT
		// Syntax for method invocation with type arguments is
		// <String>foo("blah")
		(
			options {
				// .ident could match here or in postfixExpression.
				// We do want to match here. Turn off warning.
				greedy=true;
				// This turns the ambiguity warning of the second alternative
				// off. See below. (The "false" predicate makes it non-issue)
				warnWhenFollowAmbig=false;
			}
			// we have a new nondeterminism because of
			// typeArguments... only a syntactic predicate will help...
			// The problem is that this loop here conflicts with
			// DOT typeArguments "super" in postfixExpression (k=2)
			// A proper solution would require a lot of refactoring...
		:	(DOT (typeArguments)? IDENT) =>
				DOT^ (ta2:typeArguments!)? IDENT
		|	{false}?	// FIXME: this is very ugly but it seems to work...
						// this will also produce an ANTLR warning!
				// Unfortunately a syntactic predicate can only select one of
				// multiple alternatives on the same level, not break out of
				// an enclosing loop, which is why this ugly hack (a fake
				// empty alternative with always-false semantic predicate)
				// is necessary.
		)*
		(
			options {
				// ARRAY_DECLARATOR here conflicts with INDEX_OP in
				// postfixExpression on LBRACK RBRACK.
				// We want to match [] here, so greedy. This overcomes
				// limitation of linear approximate lookahead.
				greedy=true;
			}
		:	(	lp:LPAREN^ {#lp.setType(METHOD_CALL);}
				// if the input is valid, only the last IDENT may
				// have preceding typeArguments... rather hacky, this is...
				{if (#ta2 != null) astFactory.addASTChild(currentAST, #ta2);}
				{if (#ta2 == null) astFactory.addASTChild(currentAST, #ta1);}
				argList RPAREN!
			)
		|	( options {greedy=true;} :
				lbc:LBRACK^ {#lbc.setType(ARRAY_DECLARATOR);} RBRACK!
			)+
		)?
	;

/** object instantiation.
 *  Trees are built as illustrated by the following input/tree pairs:
 *
 *  new T()
 *
 *  new
 *   |
 *   T --  ELIST
 *		   |
 *		  arg1 -- arg2 -- .. -- argn
 *
 *  new int[]
 *
 *  new
 *   |
 *  int -- ARRAY_DECLARATOR
 *
 *  new int[] {1,2}
 *
 *  new
 *   |
 *  int -- ARRAY_DECLARATOR -- ARRAY_INIT
 *								  |
 *								EXPR -- EXPR
 *								  |	  |
 *								  1	  2
 *
 *  new int[3]
 *  new
 *   |
 *  int -- ARRAY_DECLARATOR
 *				|
 *			  EXPR
 *				|
 *				3
 *
 *  new int[1][2]
 *
 *  new
 *   |
 *  int -- ARRAY_DECLARATOR
 *			   |
 *		 ARRAY_DECLARATOR -- EXPR
 *			   |			  |
 *			 EXPR			 1
 *			   |
 *			   2
 *
 */
newExpression
	:	"new"^ (typeArguments)? type
		(	LPAREN! argList RPAREN! (classBlock)?

			//java 1.1
			// Note: This will allow bad constructs like
			//	new int[4][][3] {exp,exp}.
			//	There needs to be a semantic check here...
			// to make sure:
			//   a) [ expr ] and [ ] are not mixed
			//   b) [ expr ] and an init are not used together

		|	newArrayDeclarator (arrayInitializer)?
		)
	;

argList {Token first = LT(1);}
	:	(	expressionList
		|	/*nothing*/
			{#argList = create(ELIST,"ELIST",first,LT(1));}
		)
	;

newArrayDeclarator
	:	(
			// CONFLICT:
			// newExpression is a primaryExpression which can be
			// followed by an array index reference. This is ok,
			// as the generated code will stay in this loop as
			// long as it sees an LBRACK (proper behavior)
			options {
				warnWhenFollowAmbig = false;
			}
		:
			lb:LBRACK^ {#lb.setType(ARRAY_DECLARATOR);}
				(expression)?
			RBRACK!
		)+
	;

constant
	:	NUM_INT
	|	CHAR_LITERAL
	|	STRING_LITERAL
	|	NUM_FLOAT
	|	NUM_LONG
	|	NUM_DOUBLE
	;


//----------------------------------------------------------------------------
// The Java scanner
//----------------------------------------------------------------------------
class JavaLexer extends Lexer;

options {
	exportVocab=Java;		// call the vocabulary "Java"
	testLiterals=false;		// don't automatically test for literals
	k=4;					// four characters of lookahead
	charVocabulary='\u0003'..'\uFFFF';
	// without inlining some bitset tests, couldn't do unicode;
	// I need to make ANTLR generate smaller bitsets; see
	// bottom of JavaLexer.java
	codeGenBitsetTestThreshold=20;
}

{
    protected static final int SCS_TYPE = 3, SCS_VAL = 4, SCS_LIT = 8, SCS_LIMIT = 16;
    protected static final int SCS_SQ_TYPE = 0, SCS_TQ_TYPE = 1, SCS_RE_TYPE = 2;
    protected int stringCtorState = 0;  // hack string and regexp constructor boundaries
    protected int lastSigTokenType = EOF;  // last returned non-whitespace token

    /** flag for enabling the "assert" keyword */
	private boolean assertEnabled = true;
	/** flag for enabling the "enum" keyword */
	private boolean enumEnabled = true;
    /** flag for including whitespace tokens (for IDE preparsing) */
    private boolean whitespaceIncluded = false;

	/** Enable the "assert" keyword */
	public void enableAssert(boolean shouldEnable) { assertEnabled = shouldEnable; }
	/** Query the "assert" keyword state */
	public boolean isAssertEnabled() { return assertEnabled; }
	/** Enable the "enum" keyword */
	public void enableEnum(boolean shouldEnable) { enumEnabled = shouldEnable; }
	/** Query the "enum" keyword state */
	public boolean isEnumEnabled() { return enumEnabled; }

    /** This is a bit of plumbing which resumes collection of string constructor bodies,
     *  after an embedded expression has been parsed.
     *  Usage:  new JavaRecognizer(new JavaLexer(in).plumb()).
     */
    public TokenStream plumb() {
        return new TokenStream() {
            public Token nextToken() throws TokenStreamException {
                if (stringCtorState >= SCS_LIT) {
                    // This goo is modeled upon the ANTLR code for nextToken:
                    int quoteType = (stringCtorState & SCS_TYPE);
                    stringCtorState = 0;  // get out of this mode, now
                    resetText();
/*                    try {
                        switch (quoteType) {
                        case SCS_SQ_TYPE:
//todo: suitable replacement???     mSTRING_CTOR_END(true, false, false); 
                        	break;
                        case SCS_TQ_TYPE:
//                            mSTRING_CTOR_END(true, false, true); 
                        	break;
                        case SCS_RE_TYPE:
//                            mREGEXP_CTOR_END(true, false); 
                        	break;
                        default:  throw new AssertionError(false);
                        }
                        lastSigTokenType = _returnToken.getType();
                        return _returnToken;
                    }*//* catch (RecognitionException e) {
                        throw new TokenStreamRecognitionException(e);
                    }*/ /*catch (CharStreamException cse) {
                        if ( cse instanceof CharStreamIOException ) {
                            throw new TokenStreamIOException(((CharStreamIOException)cse).io);
                        }
                        else {
                            throw new TokenStreamException(cse.getMessage());
                        }
                    }*/
                }
                Token token = JavaLexer.this.nextToken();
                int lasttype = token.getType();
                if (whitespaceIncluded) {
                    switch (lasttype) {  // filter out insignificant types
                    case WS:
                    case SL_COMMENT:
                    case ML_COMMENT:
                        lasttype = lastSigTokenType;  // back up!
                    }
                }
                lastSigTokenType = lasttype;
                return token;
            }
        };
    }
    
    protected JavaRecognizer parser;  // little-used link; TODO: get rid of
}

// OPERATORS
QUESTION		:	'?'		;
LPAREN			:	'('		;
RPAREN			:	')'		;
LBRACK			:	'['		;
RBRACK			:	']'		;
LCURLY			:	'{'		;
RCURLY			:	'}'		;
COLON			:	':'		;
COMMA			:	','		;
//DOT			:	'.'		;
ASSIGN			:	'='		;
EQUAL			:	"=="	;
LNOT			:	'!'		;
BNOT			:	'~'		;
NOT_EQUAL		:	"!="	;
DIV				:	'/'		;
DIV_ASSIGN		:	"/="	;
PLUS			:	'+'		;
PLUS_ASSIGN		:	"+="	;
INC				:	"++"	;
MINUS			:	'-'		;
MINUS_ASSIGN	:	"-="	;
DEC				:	"--"	;
STAR			:	'*'		;
STAR_ASSIGN		:	"*="	;
MOD				:	'%'		;
MOD_ASSIGN		:	"%="	;
SR				:	">>"	;
SR_ASSIGN		:	">>="	;
BSR				:	">>>"	;
BSR_ASSIGN		:	">>>="	;
GE				:	">="	;
GT				:	">"		;
SL				:	"<<"	;
SL_ASSIGN		:	"<<="	;
LE				:	"<="	;
LT				:	'<'		;
BXOR			:	'^'		;
BXOR_ASSIGN		:	"^="	;
BOR				:	'|'		;
BOR_ASSIGN		:	"|="	;
LOR				:	"||"	;
BAND			:	'&'		;
BAND_ASSIGN		:	"&="	;
LAND			:	"&&"	;
SEMI			:	';'		;


// Whitespace -- ignored
WS	:	(	' '
		|	'\t'
		|	'\f'
			// handle newlines
		|	(	options {generateAmbigWarnings=false;}
			:	"\r\n"	// Evil DOS
			|	'\r'	// Macintosh
			|	'\n'	// Unix (the right way)
			)
			{ newline(); }
		)+
		{ _ttype = Token.SKIP; }
	;

// Single-line comments
SL_COMMENT
	:	"//"
        (
            options {  greedy = true;  }:
            // '\uffff' means the EOF character.
            ~('\n'|'\r'|'\uffff')
        )*
		{$setType(Token.SKIP);}
	;

// multiple-line comments
ML_COMMENT
	:	"/*"
		(	/*	'\r' '\n' can be matched in one alternative or by matching
				'\r' in one iteration and '\n' in another. I am trying to
				handle any flavor of newline that comes in, but the language
				that allows both "\r\n" and "\r" and "\n" to all be valid
				newline is ambiguous. Consequently, the resulting grammar
				must be ambiguous. I'm shutting this warning off.
			 */
			options {
				generateAmbigWarnings=false;
			}
		:
			{ LA(2)!='/' }? '*'
		|	'\r' '\n'		{newline();}
		|	'\r'			{newline();}
		|	'\n'			{newline();}
		|	~('*'|'\n'|'\r')
		)*
		"*/"
		{$setType(Token.SKIP);}
	;


//	 character literals
	CHAR_LITERAL
		:	'\'' ( ESC | ~('\''|'\n'|'\r'|'\\') ) '\''
		;

//	 string literals
	STRING_LITERAL
		:	'"' (ESC|~('"'|'\\'|'\n'|'\r'))* '"'
		;


// escape sequence -- note that this is protected; it can only be called
// from another lexer rule -- it will not ever directly return a token to
// the parser
// There are various ambiguities hushed in this rule. The optional
// '0'...'9' digit matches should be matched here rather than letting
// them go back to STRING_LITERAL to be matched. ANTLR does the
// right thing by matching immediately; hence, it's ok to shut off
// the FOLLOW ambig warnings.
protected
ESC
	:	'\\'
		(	'n'
		|	'r'
		|	't'
		|	'b'
		|	'f'
		|	'"'
		|	'\''
		|	'\\'
		|	('u')+ HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
		|	'0'..'3'
			(
				options {
					warnWhenFollowAmbig = false;
				}
			:	'0'..'7'
				(
					options {
						warnWhenFollowAmbig = false;
					}
				:	'0'..'7'
				)?
			)?
		|	'4'..'7'
			(
				options {
					warnWhenFollowAmbig = false;
				}
			:	'0'..'7'
			)?
		)
	;


// hexadecimal digit (again, note it's protected!)
protected
HEX_DIGIT
	:	('0'..'9'|'A'..'F'|'a'..'f')
	;


// a dummy rule to force vocabulary to be all characters (except special
// ones that ANTLR uses internally (0 to 2)
protected
VOCAB
	:	'\3'..'\377'
	;


// an identifier. Note that testLiterals is set to true! This means
// that after we match the rule, we look in the literals table to see
// if it's a literal or really an identifer
IDENT
	options {testLiterals=true;}
	:	('a'..'z'|'A'..'Z'|'_'|'$') ('a'..'z'|'A'..'Z'|'_'|'0'..'9'|'$')*
		{
			// check if "assert" keyword is enabled
			if (assertEnabled && "assert".equals($getText)) {
				$setType(LITERAL_assert); // set token type for the rule in the parser
			}
			// check if "enum" keyword is enabled
			if (enumEnabled && "enum".equals($getText)) {
				$setType(LITERAL_enum); // set token type for the rule in the parser
			}
		}
	;

protected
DIGIT
options {
    paraphrase="a digit";
}
    :   '0'..'9'
    // TODO:  Recognize all the Java identifier parts here (except '$').
    ;

protected
DIGITS_WITH_UNDERSCORE
options {
    paraphrase="a sequence of digits and underscores, bordered by digits";
}
    :   DIGIT (DIGITS_WITH_UNDERSCORE_OPT)?
    ;

protected
DIGITS_WITH_UNDERSCORE_OPT
options {
    paraphrase="a sequence of digits and underscores with maybe underscore starting";
}
    :   (DIGIT | '_')* DIGIT
    ;

// a numeric literal
NUM_INT
	{boolean isDecimal=false; Token t=null;}
	:	'.' {_ttype = DOT;}
			(
				(('0'..'9')+ (EXPONENT)? (f1:FLOAT_SUFFIX {t=f1;})?
				{
				if (t != null && t.getText().toUpperCase().indexOf('F')>=0) {
					_ttype = NUM_FLOAT;
				}
				else {
					_ttype = NUM_DOUBLE; // assume double
				}
				})
				|
				// JDK 1.5 token for variable length arguments
				(".." {_ttype = TRIPLE_DOT;})
			)?

	|	(	'0' {isDecimal = true;} // special case for just '0'
			(	('x'|'X')
				(											// hex
					// the 'e'|'E' and float suffix stuff look
					// like hex digits, hence the (...)+ doesn't
					// know when to stop: ambig. ANTLR resolves
					// it correctly by matching immediately. It
					// is therefor ok to hush warning.
					options {
						warnWhenFollowAmbig=false;
					}
				:	HEX_DIGIT
				)+

			|	//float or double with leading zero
                (   DIGITS_WITH_UNDERSCORE
                    ( '.' DIGITS_WITH_UNDERSCORE | EXPONENT | FLOAT_SUFFIX)
                ) => DIGITS_WITH_UNDERSCORE

			|	('0'..'7')+									// octal
			)?
		|	('1'..'9') (DIGITS_WITH_UNDERSCORE_OPT)?  {isDecimal=true;}		// non-zero decimal
		)
		(	('l'|'L') { _ttype = NUM_LONG; }

		// only check to see if it's a float if looks like decimal so far
		|	{isDecimal}?
			(	'.' DIGITS_WITH_UNDERSCORE (EXPONENT)? (f2:FLOAT_SUFFIX {t=f2;})?
			|	EXPONENT (f3:FLOAT_SUFFIX {t=f3;})?
			|	f4:FLOAT_SUFFIX {t=f4;}
			)
			{
			if (t != null && t.getText().toUpperCase() .indexOf('F') >= 0) {
				_ttype = NUM_FLOAT;
			}
			else {
				_ttype = NUM_DOUBLE; // assume double
			}
			}
		)?
	;

// JDK 1.5 token for annotations and their declarations
AT
	:	'@'
	;

// a couple protected methods to assist in matching floating point numbers
protected
EXPONENT
	:	('e'|'E') ('+'|'-')? ('0'..'9')+
	;


protected
FLOAT_SUFFIX
	:	'f'|'F'|'d'|'D'
	;
			

//			 Note: Please don't use physical tabs.  Logical tabs for indent are width 4.
//			 Here's a little hint for you, Emacs:
//			 Local Variables:
//			 tab-width: 4
//			 mode: antlr-mode
//			 indent-tabs-mode: nil
//			 End:
