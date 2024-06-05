---
title: "Fusion/Fracture Specification Language"
author: "Jeff Nye"
date: "2024-06-03"
---

# Fusion/Fracture Specification Language

## Table of contents

1. Document History

1. Introduction to FSL
    1. High Level Operation
    1. FSL Example
    1. Is/Is not

1. Language Description
    1. Scope
    1. Keywords
    1. Identifiers
    1. Literals
    1. FSL Native Types
    1. Operators
        1. Arithmetic Operators
        1. Range Operators
        1. Relational Operators
        1. Logical Operators
        1. Assignment Operators
        1. Concatenation Operator
    1. Comments
    1. Preprocessor Support
        1. Conditional Compilation
        1. Includes
    1. Transform Structure
    1. Transform Specification
    1. Prolog Elements
    1. isa Element
        1. isa Methods
    1. uarch Element
        1. uarch methods
    1. ioput Element
        1. ioput methods
    1. Sequence Clause
        1. Sequence methods
    1. Constraints Clause
        1. Constraints methods
    1. Conversion Clause

1. Tools and Utilities
    1. Condor FSL API
    1. Olympia Performance Model
    1. Mavis
    1. STF Library

1. Appendix
    1. FSL BNF 
    1. FSL style considerations
        1. Encapsulated Style
        1. Library Style
    1. FSL Instruction Types
    1. Syntax Highlight Control File
        1. VIM
1. References

----------------------------------------------------------------
# Document History

| Version |    Date    |  Contact  | Description                           |
|:-------:|:----------:|:---------:|:--------------------------------------|
|  x.3    | 2024.06.03 | Jeff Nye  | resolving all SIG review comments and previous TODOs. 1st draft of user reference in preparation for wider review.
|  x.2    | 2024.03.10 | Jeff Nye  | removed operators, div/mod not needed,++/--/extensive assignment operators violate S
|  x.1    | 2024.03.08 | Jeff Nye  | typos, replace asserts with exceptions, grammar changes
|  x.0    | 2024.03.04 | Jeff Nye  | circulated for comment


### TODOs

- Publish the FSL git repo URL
- Provide a list of related documents, such as the RISC-V ISA documents, the FSL API user reference and doxygen files, etc.

### Future features
- The default uarch methods could be extended using template semantics. Extending the methods through specialization of MachineInfo could also extend the syntax of FSL by some restructure of the grammar to treat ID's as possible known methods.

----------------------------------------------------------------
# Introduction to FSL

Fusion/Fracture Specification Language (FSL) is an interpreted language. FSL is used to express properties, constraints and processes for transformation of microprocessor instructions sequences into alternative instruction sequences. 

The FSL interpreter is linked to the FSL API. The API is a c++/python interface that ties the language constructs with higher level systems, like performance models and RTL generation tools. The API is documented in FSL_API_USER_REF.pdf and also in doxygen form. These documents can be found at <FIXME:publish repo url>

This document focuses on the structure of the domain specific language, FSL, and the expression of instruction sequence transformations.

Generally, the transformation process converts an N-tuple of processor instructions to an M-tuple of processor instructions. 

When N > M holds, this is the marker for a fusion transformation. 

When N < M holds, this is the marker for a fracture transformation. 

When N = M holds, this is marker for binary translation.

Informally, fusion converts simpler operations into more complex operations with the intent of improving execution attributes. Fracture commonly replaces more complex operations with simpler operations, with the same intent of improving execution attributes.

Often N-tuple instructions are elements of a standardized ISA and the M-tuple are customizations of the N-tuple set.  The M-tuple instructions are the result of transformation and are internal to the processor. 

FSL assists the expression of the properties of these transformations and takes advantage of the bounds of the domain to provide an efficient syntax for these expressions.

## High Level Operation

Each N to M tuple mapping is defined in a named FSL transform specification. The input to a transform is a sequence of instructions, and the output is a potentially transformed sequence. Whether a transformation occurs is determined by constraints expressed in FSL.

An FSL transform operates in three phases: sequence matching, constraints evaluation, and conversion. These phases are represented by three clauses in an FSL transform specification:

- Sequence Matching Phase
    - Sequence Clause:
        - Purpose: Declares the matching attributes to be applied to the input sequence. These attributes can be a list of instruction objects, either in assembly language or as a list of UIDs.
        - Process: The sequence clause pattern matches the input sequence against the declared attributes. If a match is found, it updates its internal index and length fields to indicate the position and number of instructions to be transformed.
        - Output: If a match is found, the sequence clause returns an index and a length. If no match is found, it returns fail.
        - Action on Failure: If sequence matching fails control is returned to the FSL API, which continues processing and notifies the system as required.

- Constraints Evaluation Phase
    - Constraints Clause:
        - Purpose: Evaluates the constraints on the matched sequence.
        - Process: The constraints clause is applied to the indicated range from the sequence clause and returns a true or false indication.
        - Output: If the constraints are satisfied, it returns true and passes the sequence indication to the conversion clause. If not, it returns false.
        - Action on Failure: If the constraints clause returns false, control is again returned to the FSL API.

- Conversion Phase
    - Conversion Clause:
        - Purpose: Applies the transformation to the input sequence.
        - Process: If the conversion clause receives true, it transforms the input sequence starting at the specified index. The transformed sequence is then placed in an output sequence or modifies the input sequence in place, as directed by the syntax.
        - Output: The modified or newly created sequence of instructions.

- Summary of Phases

    - Sequence Clause: Identifies the instruction sequence to be transformed.
    - Constraints Clause: Ensures the identified sequence meets the necessary conditions.
    - Conversion Clause: Performs the actual transformation of the instruction sequence.

The FSL API will continue to process all registered FSL transform specifications until the current instruction buffer has been fully transformed or all known transforms have been tested.

## FSL Example

An example of an FSL transform specification written in the encapsulated style is shown below.

In the sample below, the three clauses, sequence, constraints and conversion, are preceded by the variables which declare the instruction set architecture, the micro-architecture of the processor and a sequence container reference.


```
transform uf10
{
  // Prolog elements
  isa   rv64g     // ISA definition object
  uarch oly1      // Microarchitecture definition object
  ioput iop1      // API interface object

  // Variables at transform scope
  gpr  g1,g2,g3,g4
  u5   c1
  s12  c2

  // Example of an abstracted instruction sequence
  sequence seq_uf10 {
    sd  g1,c1(g2)
    sd  g3,c2(g4)
  }
  
  // Example of a constraints specification
  constraints cns_uf10 { 
    g1 != g2
    g3 != g4
    g1 != g4
  }
  
  // Example of a conversion clause using abstract morphing
  conversion cnv_uf10 {
    instr instr_uf10
    instr_uf10.morph(seq_uf1)  // merge sequence into 1 object
    iop.input.replace(seq_uf10,instr_uf10) // update the input buffer
}
```

## Is/Is not

FSL is not a programming language; it is a "constrained transformation expression language". FSL operates on stylized or symbolic microprocessor instructions, within this domain, many aspects of a general programming languages are not required by FSL.

The FSL syntax style is a reduced boilerplate style of C. e.g. braces are 
used, no semi-colons, indentation is not a syntax element.

There are no user defined functions. However see the `define.

There are a limited number of data types unique to FSL.

The standard C native types are not required by the FSL syntax.

This is no need for container types. 

The typical native types such as float, double are not required by FSL and  therefore not inferred. 

Integer constant types are signed or unsigned and have an explicit bit width.

FSL uses single assignment for variables.

There are no console or file I/O mechanisms.

Expression operations are limited.

Arithmetic expressions are limited.

const'ness is not a feature of FSL.

There is a support library called fsl, which provides utility functions. This is the only true namespace in FSL.

----------------------------------------------------------------
# Language Description

This is the language specification section. Discussion of usage follows in the <FIXME: give it a name> Section.

The (E)BNF for the language is in Section FSL BNF found in the Appendix.

## Scope

There is global scope for named tranforms and a local scoping 
convention.  Variable scoping is lexical.

Anonymous block scoping, { ...scope... }, is not necessary for FSL operation.

## Keywords

The set of keywords is small. Some objects have process/method names
where legal use is indicated by context and are not keywords.

```
FIXME: RECREATE THE KEYWORD LIST
```

## Identifiers

Legal variable names are conventional. 

```
^[a-zA-Z_][a-zA-Z0-9_]*$
```

----------------------------------------------------------------
## Literals

Numeric literals are expressed as decimal, hexadecimal or the verilog style.

```
123
0x456
8'b10101010
4'hF
```

For Verilog style constants the '?' value indicates a match all or
don't care element. The width of '?' is relative to the width of 
native elements within the constant's base.

```
 8'b1010101?      bit 0 is a don't care
12'h45?           bits [3:0] are a don't care
```

String literal syntax is conventional using double quotes.

```
"spill_store_merge"
```

----------------------------------------------------------------
## FSL Native Types

The native integer type equivalents in FSL are signed and unsigned with an explicit width specified in the type name.

```
u10 varA    //varA will hold unsigned values up to 10 bits in width
s10 varB    //varB will hold signed values up to 9 bits + sign

u3 varA = 0x7  // legal example 
s3 varB = 0x17 // warning or exception
```

For math operations on these types the internal representation is uint64_t by default. A control is provided in the FSL API to select 32,64,128. uint64_t is the default.

Assigning a value that will overflow the range of a variable will generate a warning or throw an Fsl::Exception, depending on the configuration of the FSL interpreter. See <FIXME: FSL API USER REF> for interpreter controls. The default is to throw an exception.

In addition to the FSL integer types the language supports the gpr (General Purpose Register) and csr (Control/Status Register) types. Use of these types is unique to FSL. The contents of gpr or csr variable is the index of the respective register rather then a general value.
```
gpr g1 = 2    // This specifies X2 in the RISC-V domain
csr s1 = 768  // This specifies the mstatus register in the RISC-V domain
```
<FIXME: a mechanism to allow use of the API names, how to do this without
assuming RISC-V>

The range and boolean operators are not valid for the gpr and csr types.
```
gpr g1
gpr g2 = g1[1]  // syntax error, range is not valie for gpr/csr
gpr g2 = ~g1    // syntax error, boolean ops are not valid for gpr/csr
```

----------------------------------------------------------------
## Operators

The list of operators and their support in FSL is listed below. FSL adds
the range selection operators to the standard C style operators. The syntax is similar to Verilog.

These operators are unnecessary in FSL: 
- Divide, modulus, size_of, pointer operations, type conversions cast/implicit/explicit.

Within the supported operators FSL uses conventional operator precedence.

### Arithmetic Operators

```
    + (Addition)
    - (Subtraction)
    * (Multiplication)
```
### Boolean Operators

```
    & (AND)
    | (OR)
    ^ (XOR)
    ~ (Bitwise NOT)
```
### Range Operators

```
    [M:N] (range select)
    [M]   (index)
```
### Relational Operators

```
    ==  (Equal to)
    !=  (Not equal to)
    >   (Greater than)
    <   (Less than)
    >=  (Greater than or equal to)
    <=  (Less than or equal to)
```
### Logical Operators

```
    &&  (Logical AND)
    ||  (Logical OR)
    !   (Logical NOT)
```

### Assignment Operator

```
    =    (Simple assignment)
```

### Concatenation Operator

Concatenation expressions use a style similar to verilog, {a,b,c};

```
  xyz = { 3'b00, 4'h3,8'd10 }
  abc = { a, b, c }
  
```

## Comments

Comments use '//' for single line comments or '/*' and '*/' as 
the delimiters for comment blocks.

```
//  single line comment
/*  my multi line
    comment 
    end of ML comment */*
```

## Preprocessor Support

The FSL parser uses a pre-processor with features similar to that found
in the C pre-processor.  Within the constraints of the FSL language most 
pre-processor operations found in C will be available in FSL with slight
changes for FSL syntax choices.
 
Note that the typical # indicator, as in #include, is replaced with
'`' as in `include.


### Conditional Inclusion

FSL supports a typical set of conditional inclusion directives.

```
`ifdef X
`ifndef X
`if X == Y
`if Z != 2

`endif
`endif
`endif
`endif
```

### Includes

The include keyword declares external files. The parser handles included files by expanding them into the current position in the current translation unit. Include recursion is illegal.

The syntax is:
```
`include myfile.fh
```
The .fh extension is preferred but not enforced by the parser. Quotes around the file name are not used.

The single inclusion pragma is declared as:
```
`once
```
This pragma must be expressed before any other non-comment statement.

### Defines

Use of pre-processor defines is close to conventional, the pragma marker is the back tick and an explicit equal sign is required.

```
`define A = 7 
`define B = A+1
```
These are conventional text replacement macros. Syntax checking is done at the point of insertion within the translation unit.

## Transform Structure

FSL transform specifications are read at runtime. The FSL file list is passed to the FSL API constructor. The API invokes the FSL parser.

A transform's internal structure consists of the sequence, constraints, and conversion clauses, along with a number elements in the prolog which specify the context of the fusion operation, ISA, microarchitecture and hooks into the performance model, and finally any local variables used by the principle clauses.

## Transform Specification 

The transform statement is a top level structure.  Each transform statement is named. The name must be unique across all translation units.

The generic form is shown below. The order of the sections and clauses is arbitrary. What is shown is the recommended convention.

```
transform <name> {
  <prolog section>
  <sequence clause>
  <constraints clause>
  <conversion clause>
}
```

### Transform Methods

The transform object has no internal methods accessible through FSL syntax Operations which use the transform element do so implicitly during FSL parsing.

## Prolog Elements

The prolog elements provide the necessary context for the transform operation and they are commonly referred to as a group.  The common elements are shown:

```
  isa    myIsa
  uarch  myImplementation
  ioput  iop1
```

During parsing the FSL interpreter uses the prolog elements to determine the pertinence of a given registered transform to the current context. Transform specifications which do not match the current context are ignored.

The FSL API contains methods used to specify the current context to the interpreter. This is discussed in the FSL API

It is common to group the prolog elements into a top level structure and reference that structure by name in transform specifications. This is an abbreviated example:

```
prolog plog1
{
    isa myIsa
    uarch myImplementation
    ioput iop1
}

transform prolog_example
{
    prolog plog1
    ...etc...
}
```

## isa Element

The isa element name is used by the FSL API to match an instruction set description API to the transform specification. The API looks up the  'myIsa' string to find the associated object pointer.

The FSL API will throw an exception if the named isa element does not have an associated object.

The ISA description API is used to validate instruction references in the transform specification.

Mavis is the instruction set description API supported in this release.

### isa Methods

The isa object has no internal methods accessible through FSL syntax. Operations which use the isa element do so implicitly during FSL parsing.

## uarch Element

The uarch element name is used by the FSL API to match a micro-architecture description class instance to the transform specification.

```
uarch myArch
```

The FSL API will throw an exception if the named uarch element, myArch as shown, does not have an associated object.

The microarchitecture description class is used to validate processor implementation queries made in the constraints and conversion clauses.

### uarch methods

The default uarch methods are documented in MachineInfo.hpp as part of the
FSL API doxygen documentation. 

The default uarch methods can be extended using template semantics. Extending the methods through specialization of MachineInfo also extends the syntax of FSL.

This is discussed in the <FIXME: FSL API USER REFERENCE>

The syntax shown below is the FSL domain specific syntax for the default methods. 

```
.maxIntWrPorts()  // returns the maximum available write ports as
                  // implemented in the machine and reported to
                  // the FSL runtime by the MachineInfo interface
.maxIntRdPorts()  // max write ports for the integer register file
.maxFpWrPorts()   // max write ports for the FP register file
.maxFpRdPorts()   // max read ports for the FP register file
.maxVecWrPorts()  // max write ports for the vector register file
.maxVecWrPorts()  // max read ports for the vector register file
.maxIssueWidth()  // maximum number of instructions issued per cycle
.maxDecodeWidth() // maximum number of instructions decoded per cycle
.maxFetchWidth()  // maximum number of instructions fetched per cycle
```

Example usage:
```
uarch cam
if (cam.maxIntWrPorts() < 4)
{
...etc...
}
```

## ioput Element

The FSL API links references to C++ buffers containing instruction representations to the FSL parser. This linkage is done through a similar name matching scheme as the other prolog elements.

ioput is the keyword. Within ioput are two objects representing two instruction buffers, by name they are simply .input and .output.

During construction the FSL API maps ioput.input and ioput.output to the appropriate model containers. 'input' and 'output' are indexes into a map containing references to the model's instruction buffers.

The FSL API will throw an exception if it can not match the elements in ioput to STL container objects.  Using Olympia as an example, the Fusion  API will attempt to match the specified name, ioput.input, to a  Fusion::InstQueue reference.

Note: The FSL syntax implies a copy-on-write idiom. However by mapping the ioput.input and ioput.output objects to the same buffer a modification in-place idiom can be implemented. This isolates the style used in the conversion clause from these external mechanics.

### ioput methods

ioput elements have these methods available. 

```
.clear()                 empties the associated container
.input                   reference to the input instruction container
.output                  reference to the output instruction container
.erase(index,size)       removes size elements begining with index,
                         size is inclusive of the index position.
.insert(index,instr)     insert an instr object before index. 
                         instr is an FSL type
.replace(sequence,instr) removes sequence.length objects beginning
                         at sequence.index, and inserts instr 
```

## Sequence clause

The sequence clause is used to match the incoming instructions to the current transform. 

The optional arguments to the sequence clause are the input sequence name and the ISA definition API facade name, declared using ioput and isa, respectively. When the arguments are unspecified the interpreter will attempt to find unambigous references to an ioput and isa object within the scope of the transform. If either reference fails to resolve the interpreter will issue an exception.

Naming the sequence is optional when using sequence clause arguments are implicit. A sequence clause name is required when explicit arguments are used.

```
  sequence {     // Valid
    ...
  }

  sequence seq1(iop,myIsa) {  // Valid
    ...
  }

  sequence (iop,myIsa) { // Invalid. The clause name must be provided when explicit
     ...                 // arguments are also specified.
  }
```

The ioput and isa objects used by the sequence clause to access the instruction containers and known instruction definitions. This access is used for validation of the sequence and for matching.

The sequence clause implicitly uses the 1st element of ioput, the input container. The sequence clause does not modify the ioput containers.

```
ioput iop1
isa myISA

sequence seq1(iop1,myISA) {
   # sequence of instructions
}
```

The FSL parser uses the FSL API and access to the isa object to validate the instruction sequence. An exception is thrown if a problem is detected, for example if the FSL API is unable to determine the intended syntax from the abstract instruction in the sequence. 

The specified sequence of instructions is pattern matched against the contents of the input container.  If a match is detected the sequence object, in this case seq1, will update its internal index field and length field. This information is passed to the constraints clause. On a match the sequence clause returns \_pass\_ to the FSL API.

The index field is the zero-referenced position of the start of the match  within ioput. The length is the number of instructions, inclusive of the starting instruction.

An instruction sequence is expressed as a simple list of Mavis-assigned unique identifiers, or as a set of assembly language instructions with abstracted operands. The choice is based on the constraints.

Abstract operands are operands specified by the FSL native types. For example an explicit three register add instruction might look like
```
add  x1,x2,x3
```
The abstract form matching this instruction would be as shown
```
gpr GA,GB,GC
...snip...
add GA,GB,GC
```
Three gpr type operands are declared and the abstract form of the instruction uses those declarations. Subsequent contraints clause references could then be used to restrict the values that GA, GB, GC can take meet the requirements of the transform.

Note simple declaration of the operand types is a form of implicit or implied constraint. For example the FSL API will not match add gpr,gpr,gpr to an instruction that requires an immediate operand.

A UID list is sufficient if there are no constraints on the values of operands. If the target conversion of the transform does not require constraints on the operands and therefore has no need to refer to the operands by name and type, you can simply specify the UIDs as a list, one per line.

These two instructions are a frequent sequence in compiled C. The comment is the Mavis unique identifier for each instruction. The Mavis UID is independent of the operands.
```
c.slli x10,4    // 0xf
c.srli x10,4    // 0x13
```
 
The UIDs are supplied by the ISA definition API. Note: sequences specified using UIDs will be specific to the ISA definition API. The UIDs listed in this documentation are Mavis assigned UIDs. There is a tradeoff between ease of specification and portability across ISA definition APIs.

```
ioput iop1

sequence seq1(iop1,rv64g) {
  0xf
  0x13
}
```
With the UID sequence expression there are no operand specific constraints and therefore the conversion clause must handle any legal combinations of the two rd and two constants.

This results in a transform to a generalized fusion op of shift-left followed by shift-right.

If the constraints clause implements operand restrictions, the instruction sequence should be expressed using the abstract assembly syntax which allows the operands to be referenced by name.

The expression below takes advantage of another implicit constraints, called positional constraints:

```
ioput iop1

sequence seq1(iop1,rv64g) {
  c.slli g1,c1
  c.srli g1,c1
}
```

In this case the operands labeled g1 are, by association, required to be the same value, similarly with the constant operands.

Another option would be to fully enumerate the operands and let the constraints clause enforce the required limits on operands.

```
ioput iop1

sequence seq1(iop1,rv64g) {
  c.slli g1,c1
  c.srli g2,c2
}
```

Note both the later two cases can be made equivalent by construction of the equivalent constraints in that clause.

Now the transformation expresses a fusion operation for zero extention of the common rd register by the common constant.

```
g1 = g2
c1 = c2
```

In some cases positional constraints can save development time at no expense to simulation performance.

The example sequences above have an implied strict ordering. There are sequence keywords to relax the strictness of sequence matching. 

The required keyword, \_req\_, indicates that an unspecified instruction is required in that position. The \_req\_ case does not constrain what instruction can be present in the gap. A trailing integer can specify more than one required instruction, \_req\_ 3.

The optional keyword, \_opt\_, indicates that the match will not be rejected if there is an instruction or not in this position. A trailing integer can be used to specify up to N optional instructions.

```
_opt_ 2    indicates 0 - 2 instructions will match
_req_ 2    indicates there must be 2 instructions in this position
           in the sequence. 
```

The trailing integer is optional in the syntax:
```
_opt_ and _opt_ 1 are equivalent
_req_ and _req_ 1 are equivalent
```

This example shows \_req\_ and \_opt\_ in a larger context:

```
ioput iop1

sequence seq1(iop1,rv64g) {
  c.lui    g1, c1
  c.addi   g1, g1, c2
  _req_ 2
  c.xor    g2, g2, g1
  c.slli   g2, g2, c3
  _opt_ 2
  c.srli   g2,     c3
}
```

Notes: The sequence pragmas are also supported for the UID case.  Mixing UID  and abstract operand sequences is also supported. 

### Sequence methods

sequence objects have implicit data members

```
.state        This is _pass_ or _fail_ match status
.length       number of matching instructions, if non-zero this is
              the number of UIDs or instruction object epxress in the
              sequence. length is 0 if no match is found.
 
.index        if length is non-zero this index of the first matching
              instruction

```

## Constraints clause

The constraints clause defines relationships between operands, the
machine implementation and known transformable sequences.

The sequence clause name is provided to give the constraints clause access to 
the operand abstractions and UID list. As with the sequence clause, arguments to the constraints clause are optional. The FSL API will attempt to find unambiguous
references for an ioput object, uarch object and a sequence object. 

The ioput object is used so the constraints clause can query the encoding of the instructions in the input buffer. The isa object is used to validate field widths etc used in the constraints declarations. Finally the uarch object provides
the constraints clause access to machine implementatain details.

When the sequence object contains only UIDs there can be no operand
specific constraints, and the constraints clause can simply return
\_pass\_.

```
constraints cons1() {
  _pass_
}
```

This is a contrived example unsed in the explanation that follows.

```
prolog p1
{
  ioput iop1
  isa   rv64g
  uarch oly1
}

transform t1
{
  prolog p1

  gpr g1,g2
  u6  c1,c2

  sequence {
    c.slli g1,c1
    c.srli g2,c2
  }  

  constraints {
    g1 != g2
    c1[0] == c2[1]
  }

  ...snip...
}
```
In this example a shared prolog object is declared and then references in transform t1. 

Variables are declared and referenced in the sequence and constraints clauses. g1 and g2 are variables of type gpr. c1 and c2 are variables of unsigned type with field with of 6 bit.  

A sequence clause consisting of two instructions is for reference.

Using RISC-V nomenclature, the constraints clause specifies that, in order to match this transform in this contrived example, the destination register for the first (g1) and second instructions (g2) must not be the same. Further constants u6 contants c1 and c2 have a specific limitation between bit 0 of c1 and bit 1 of c2. 

The explicit arguments for the sequence and constraints clauses are not used. An alternative expression of this transform could use this syntax.

```
  prolog p1

  ...

  sequence seq1(p1.iop1,p1.rv64g) {
       ...
  }  

  constraints cons1(seq1,p1.iop1,p1.rv64g,p1.oly1) {
    ...
  }

```
This is functionally identical to the previous example but provides the explicit arguments to the the sequence and constraints clauses.

The FSL syntax is designed to minimize boiler plate. 

In the former case the FSL interpreter will look for unambiguous reference to an ioput object, and a isa object for the sequence clause. For the sequence clause the interpreter will perform the same look up for reference objects, the ioput object, the isa object and the uarch object.

### Constraints methods

The constraints clause has a single method.

```
.state        This is _pass_ or _fail_ constraints status
```

In addition to the .state method, the constraints clause declarations
are made available without prefix to the conversion clause. This is
described in the next section.

### Conversion clause

The conversion clause performs the instruction morphing operation(s) to create
the new instruction(s). 


The conversion clause takes a reference to the sequence clause for 
access to the named operands or for access to the UID lists.

The conversion clause takes a reference to the ioput object for
reading the input instruction list as a destination for converted
instructions.

The constraints clause is provided to the conversion clause for 
access to operand relationships and types.

The conversion clause can modify the ioput object's input field 
in place with converted instructions or it can place modified
instructions in the output field of the ioput object.

instr objects are used to hold the newly created instructions.  The 
annotation fields for a new instruction are assigned to the instr
object.

In the example presume the sequence match has returned an index of 2 and a
length of 3. In this conversion the 3 unfused instructions are replaced
by 1 fusion created instruction.

The new instruction attributes are assigned. The ioput container
is modifed to remove the unfused instructions and insert the
fusion replacement.

```
ioput iop1

conversion conv1(seq1,iop1,cons1) {
  instr newInstr

  newInstr(opc=0x1234,uid=0x3)
  newInstr(src={g1},dst={g2},imm={c1,c1})
  newInstr(type="fused")

  iop1.input.replace(seq1,newInstr)
}
```

There are a large number of fields available in the instr object. Not
all are required by all models. Inclusion of these fields is implementation
dependent.

### Conversion methods

The conversion clause has a single method.

```
.state        This is _pass_ or _fail_ constraints status
```

The instr type is valid within a conversion clause.

----------------------------------------------------------------
# Tools and Utilities

A summary of tools and utilities useful for instruction transform work. 

## Condor FSL API

FSL domain specific language is a component of a larger C++ API. With this API
it is possible to directly create instruction transforms in C++, or through
the FSL domain specific language or other ad hoc schemes. The API has 
been tested with the Condor Performance Model and the Olympia 
performance model.

The FSL API shares a repository with the Olympia performance model.  The
shared URL is contained here:
https://github.com/riscv-software-src/riscv-perf-model/tree/master/fusion.
Doxygen documentation is available for this API.

## Olympia Performance Model

Olympia is a performance model written in C++ for the RISC-V community as an 
example of an Out-of-Order RISC-V CPU Performance Model based on the Sparta 
Modeling Framework.

The repository URL is https://github.com/riscv-software-src/riscv-perf-model/tree/master.

## Mavis 

Mavis is a header only framework designed for decoding the RISC-V ISA into 
custom instruction class types, along with custom extensions to those 
class types.

The repository URL is https://github.com/sparcians/mavis/tree/main. Doxygen
documentation is available for this API.

## STF Library 

The STF (Simulation Tracing Format) library provides an API for 
reading and generation of STF trace files.

The repository URL is https://github.com/sparcians/stf_lib. Doxygen
documentation is available for this API.

----------------------------------------------------------------
# Appendix

## FSL BNF

```
<top> ::= <source_line> | <top> <source_line>

<source_line> ::= <transform_definition> | <prolog_definition> | <declaration>

<transform_definition> ::= TRANSFORM <id> '{' '}' | TRANSFORM <id> '{' <transform_statements> '}'

<transform_statements> ::= <transform_statement> | <transform_statements> <transform_statement>

<transform_statement> ::= PROLOG <id> | <isa_decl> | <uarch_decl> | <ioput_decl> | <variable_decl> | <selection_statement> | <constraints_definition> | <conversion_definition> | <setof_definition>

<setof_definition> ::= SETOF <id> '=' <chained_id_list> '.' <chained_method_list>

<chained_method_list> ::= <chained_method_list> '.' <known_method_decl> | <known_method_decl>

<known_method_decl> ::= <known_method> '(' <opt_arg> ')'

<opt_arg> ::= /* empty */ | <id> | <constant> | '{' '}' | '*' | '{' <concatenate_list> '}'

<prolog_definition> ::= PROLOG <id> '{' '}' | PROLOG <id> '{' <prolog_statements> '}'

<prolog_statements> ::= <prolog_statement> | <prolog_statements> <prolog_statement>

<prolog_statement> ::= ISA <id> | UARCH <id> | IOPUT <id>

<isa_decl> ::= ISA <id>

<uarch_decl> ::= UARCH <id>

<ioput_decl> ::= IOPUT <id>

<variable_definition> ::= <type_specifier> <id> '=' <assignment_expression> | <type_specifier> <id> '=' '{' <concatenate_list> '}'

<variable_decl> ::= <type_specifier> <arg_expr_list> | <variable_definition>

<constraints_definition> ::= CONSTRAINTS <opt_id> '{' <constraints_statements> '}' | CONSTRAINTS <id> '(' <arg_expr_list> ')' '{' <constraints_statements> '}'

<opt_id> ::= /* empty */ | <id>

<constraints_statements> ::= <constraints_statement> | <constraints_statements> <constraints_statement>

<constraints_statement> ::= <pass_fail_statement> | <chained_id_list> <comparison_operator> <chained_id_list> | <chained_id_list> <comparison_operator> <constant> | <chained_id_list> <comparison_operator> <chained_id_list> LEFT_OP <constant> | <chained_id_list> '.' <known_method_decl> <comparison_operator> <chained_id_list> '.' <known_method_decl> | <chained_id_list> '.' <known_method_decl> <comparison_operator> <constant> | <selection_statement>

<comparison_operator> ::= LE_OP | GE_OP | EQ_OP | NE_OP

<conversion_definition> ::= CONVERSION <opt_id> '{' <conversion_statements> '}' | CONVERSION <id> '(' <arg_expr_list> ')' '{' <conversion_statements> '}'

<conversion_statements> ::= <conversion_statement> | <conversion_statements> <conversion_statement>

<conversion_statement> ::= <pass_fail_statement> | <variable_decl> | <encoding_decl> | <encoding_definition> | <instr_decl> | <instr_definition> | <chained_id_list> '.' <known_method_decl> | <chained_id_list> '.' REPLACE '(' <comma_sep_list> ')'

<concatenate_list> ::= <concatenate_elem> | <concatenate_list> ',' <concatenate_elem>

<concatenate_elem> ::= <id> | <id> <range_list> <opt_dot_id> | OPC | <constant> | <known_method> '=' <constant>

<opt_dot_id> ::= /* empty */ | '.' <id>

<comma_sep_list> ::= <id> | <comma_sep_list> ',' <id>

<range_list> ::= '[' <constant> ']' | '[' <constant> ':' <constant> ']' | <range_list> '[' <constant> ']' | <range_list> '[' <constant> ':' <constant> ']'

<chained_id_list> ::= <id> | <chained_id_list> '.' <id>

<known_method> ::= MNEMONIC | ENCODE_ORDER | WRITEPORTS | READPORTS | REQUIREDBITS | ENCODING | OPC | SRC | DST | RSX | IMM | TYPE | HASATTR | MORPH

<instr_decl> ::= INSTR <id>

<instr_definition> ::= INSTR <id> '(' <arg_assignment_list> ')' | INSTR <id> '(' '{' <concatenate_list> '}' ')' | INSTR <id> '(' '{' <encode_list> '}' ')' | INSTR <id> '(' <chained_id_list> '.' <known_method> '(' <id> ')' ')' | INSTR <id> '(' <known_method> '(' <id> ')' ')'

<encode_list> ::= <encode_elem> | <encode_list> ',' <encode_elem>

<encode_elem> ::= <id> '[' <constant> ']' '.' ENCODING

<encoding_decl> ::= ENCODING <id>

<encoding_definition> ::= ENCODING <id> '(' <arg_assignment_list> ')' | ENCODING <id> '(' '{' <concatenate_list> '}' ')'

<arg_assignment_list> ::= <arg_assignment> | <arg_assignment_list> ',' <arg_assignment>

<arg_assignment> ::= <known_method> '=' <constant> | <known_method> '=' '{' <arg_expr_list> '}' | <id> '=' '{' <arg_expr_list> '}'

<pass_fail_statement> ::= PASS | FAIL

<primary_expression> ::= <id> | <constant> | STRING_LITERAL | '(' <expression> ')'

<postfix_expression> ::= <primary_expression> | <postfix_expression> '[' <expression> ']' | <postfix_expression> '(' <opt_arg_expr_list> ')' | <postfix_expression> '.' <id> | <postfix_expression> INC_OP | <postfix_expression> DEC_OP | <postfix_expression> '.' ENCODING '(' ')'

<opt_arg_expr_list> ::= /* empty */ | <arg_expr_list>

<arg_expr_list> ::= <assignment_expression> | <arg_expr_list> ',' <assignment_expression>

<unary_expression> ::= <postfix_expression> | INC_OP <unary_expression> | DEC_OP <unary_expression> | <unary_operator> <cast_expression>

<unary_operator> ::= '&' | '*' | '+' | '-' | '~' | '!'

<cast_expression> ::= <unary_expression> | '(' <type_name> ')' <cast_expression>

<multiplicative_expression> ::= <cast_expression> | <multiplicative_expression> '*' <cast_expression> | <multiplicative_expression> '/' <cast_expression> | <multiplicative_expression> '%' <cast_expression>

<additive_expression> ::= <multiplicative_expression> | <additive_expression> '+' <multiplicative_expression> | <additive_expression> '-' <multiplicative_expression>

<shift_expression> ::= <additive_expression> | <shift_expression> LEFT_OP <additive_expression> | <shift_expression> RIGHT_OP <additive_expression>

<relational_expression> ::= <shift_expression> | <relational_expression> '<' <shift_expression> | <relational_expression> '>' <shift_expression> | <relational_expression> LE_OP <shift_expression> | <relational_expression> GE_OP <shift_expression>

<equality_expression> ::= <relational_expression> | <equality_expression> EQ_OP <relational_expression> | <equality_expression> NE_OP <relational_expression>

<and_expression> ::= <equality_expression> | <and_expression> '&' <equality_expression>

<exclusive_or_expression> ::= <and_expression> | <exclusive_or_expression> '^' <and_expression>

<inclusive_or_expression> ::= <exclusive_or_expression> | <inclusive_or_expression> '|' <exclusive_or_expression>

<logical_and_expression> ::= <inclusive_or_expression> | <logical_and_expression> AND_OP <inclusive_or_expression>

<logical_or_expression> ::= <logical_and_expression> | <logical_or_expression> OR_OP <logical_and_expression>

<conditional_expression> ::= <logical_or_expression> | <logical_or_expression> '?' <expression> ':' <conditional_expression>

<assignment_expression> ::= <conditional_expression> | <unary_expression> <assignment_operator> <assignment_expression>

<expression> ::= <assignment_expression> | <expression> ',' <assignment_expression>

<assignment_operator> ::= '='

<declaration> ::= <declaration_specifiers> ';' | <declaration_specifiers> <init_declarator_list> ';'

<declaration_specifiers> ::= <storage_class_specifier> | <storage_class_specifier> <declaration_specifiers> | <type_specifier> | <type_specifier> <declaration_specifiers>

<init_declarator_list> ::= <init_declarator> | <init_declarator_list> ',' <init_declarator>

<init_declarator> ::= <declarator> | <declarator> '=' <initializer>

<storage_class_specifier> ::= EXTERN | AUTO

<type_specifier> ::= GPR | CSR | UN_CONST | S_CONST | STRING

<declarator> ::= <direct_declarator>

<direct_declarator> ::= <id> | '(' <declarator> ')' | <direct_declarator> '[' '*' ']' | <direct_declarator> '[' <constant> ']' | <direct_declarator> '[' <constant> ':' <constant> ']' | <direct_declarator> '[' ']' | <direct_declarator> '(' <parameter_list> ')' | <direct_declarator> '(' <identifier_list> ')' | <direct_declarator> '(' ')'

<parameter_list> ::= <parameter_declaration> | <parameter_list> ',' <parameter_declaration>

<parameter_declaration> ::= <declaration_specifiers> <declarator> | <declaration_specifiers>

<identifier_list> ::= <id> | <identifier_list> ',' <id>

<type_name> ::= <specifier_qualifier_list>

<specifier_qualifier_list> ::= <type_specifier> | <type_specifier> <specifier_qualifier_list>

<initializer> ::= <assignment_expression> | '{' <initializer_list> '}' | '{' <initializer_list> ',' '}'

<initializer_list> ::= <initializer> | <initializer_list> ',' <initializer>

<statement> ::= <pass_fail_statement> | <compound_statement> | <expression_statement> | <selection_statement> | <iteration_statement>

<compound_statement> ::= '{' '}' | '{' <block_item_list> '}'

<block_item_list> ::= <block_item> | <block_item_list> <block_item>

<block_item> ::= <declaration> | <statement>

<expression_statement> ::= ';' | <expression> ';'

<selection_statement> ::= IF '(' <expression> ')' <statement> %prec NO_ELSE | IF '(' <expression> ')' <statement> ELSE <statement>

<iteration_statement> ::= FOR '(' <expression_statement> <expression_statement> ')' <statement> | FOR '(' <expression_statement> <expression_statement> <expression> ')' <statement> | FOR '(' <declaration> <expression_statement> ')' <statement> | FOR '(' <declaration> <expression_statement> <expression> ')' <statement>

<id> ::= ID

<constant> ::= CONSTANT | HEX_CONST | VLOG_CONST | QSTRING
```



## FSL Instruction Types

Instruction types have a mapping to the ISA description API. The
lower case strings here are mapped to an equivalent type in the ISA
API. When assigning a type to an FSL instr object use the lower
case strings below, without quotes.

```
"int"                INT
"float"              FLOAT
"arith"              ARITH
"mul"                MULTIPLY
"div"                DIVIDE
"branch"             BRANCH
"pc"                 PC
"cond"               CONDITIONAL
"jal"                JAL
"jalr"               JALR
"load"               LOAD
"store"              STORE
"mac"                MAC
"sqrt"               SQRT
"convert"            CONVERT
"compare"            COMPARE
"move"               MOVE
"classify"           CLASSIFY
"vector"             VECTOR
"maskable"           MASKABLE
"unit_stride"        UNIT_STRIDE
"stride"             STRIDE
"ordered_indexed"    ORDERED_INDEXED
"unordered_indexed"  UNORDERED_INDEXED
"segment"            SEGMENT
"faultfirst"         FAULTFIRST
"whole"              WHOLE
"mask"               MASK
"widening"           WIDENING
"hypervisor"         HYPERVISOR
"crypto"             CRYPTO
"prefetch"           PREFETCH
"ntl"                NTL
"hint"               HINT
"cache"              CACHE
"atomic"             ATOMIC
"fence"              FENCE
"system"             SYSTEM
"csr"                CSR
```

## Syntax Highlight Control Files

### VIM
```
<FIXME: publish the path to this file as found in the git repo>
```

1. References

[1] Celio, Christopher, et al. "The renewed case for the reduced instruction
    set computer: Avoiding isa bloat with macro-op fusion for risc-v." arXiv
    preprint arXiv:1607.02318 (2016).