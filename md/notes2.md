An update on the latest version of the proposed syntax, this
version includes some detail on how the transform would be expressed and
some support for non-adjacent sequences.

The grammar is simple enough to be parsed using LALR, which is good enough
to begin testing interaction w/ Mavis and the model.

I'll have an update to the document that covers explanation.

I'm focusing on the matching scheme, interaction with Mavis or some 
package that can be used to extract information from the encodings. 

```
keyword constraints
keyword encoding
keyword fusion
keyword inseq
keyword isa
keyword sequence
keyword transform
keyword uarch

funcproto sequence     _id_(inseq,isa)
funcproto constraints  _id_(sequence,inseq,isa,uarch)
funcproto transform    _id_(sequence,constraints)
funcproto encoding     _id_(sequence,...)

funcproto encode_order(...)
funcproto emit(encoding)

```
 1. fusion fs1 {
 2. 
 3.   isa   rv64g
 4.   uarch oly1
 5.   inseq in_seq
 6. 
 7.   sequence seq1(in_seq,rv64g) {
 8.     c.lui    g1, c1
 9.     c.addi   g1, g1, c2
10.     _req_
11.     c.xor    g2, g2, g1
12.     c.slli   g2, g2, c3
13.     _opt_
14.     c.srli   g2,     c3
15.   }
16. 
17.   constraints cons1(seq1,in_seq,rv64g,oly1) {
18.     gpr g1,g2
19.     s20 c1
20.     s12 c2
21.     u6  c3
22. 
23.     g1 != g2
24.   }
25. 
26.   transform t1(seq1,cons1) {
27.     encoding word1(seq1,opc) {
28.       u10 opc    //57:48   unsigned 10b
29.       u6  c3     //47:42   unsigned 6b
30.       s12 c2     //41:30   signed 12b
31.       s20 c1     //29:10   signed 20b
32.       gpr g1     //9:5     gpr 5b
33.       gpr g2     //4:0     gpr 5b
34.       encode_order(opc,c3,c2,c1,g1,g2)
35.     }
36.     emit(word1(seq1,opc=0x234))
37.   }
38. }
```

The free function form is as you would expect. This improves the 
opportunity for re-use.
```
  sequence seq1 {
    ...etc...
  }
  
  constraints cons1(sequence s) {
    ...etc...
  }
  
  encoding word1(...varargs...,sequence s) {
    ...etc...
  }
  
  transform t1(constraints c,sequence s) {
    encoding word1(...varargs...,s)
  }
  
  fusion fs1 {
    sequence seq1
    constraints cons1(seq1)
    transform t1(seq1)
  }
```

