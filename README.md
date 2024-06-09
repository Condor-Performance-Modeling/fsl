# Fusion/Fracture Specification Language

# Brief
Repo for FSL Interpreter, FSL API and a fusion implementation

- fsl/api    - API source and stand alone tests
- fsl/docs   - API and interpreter documentation
- fsl/interp - Interpreter source and stand alone tests
- fsl/fusion - Instruction fusion implementation for Olympia
- fsl/test   - Combined API and interpreter tests 

# Pre-req 

To customize for alternate build environments, edit Vars.mk.

- Doxygen should be in your path
- GCC/G++ should be in your path

# Documentation - fsl/docs

Some of the references to docs below are forward looking to future docs. 

```
  docs/md/FSL_USER_REF.md           -- Fusion/Fracture Specification Language
                                       user reference guide, see also the
                                       interp doxygen files

  docs/md/FSL_API_USER_REF.md       -- Fusion/Fracture C++ API user reference,
                                       see also the API doxygen files
                                       (Planned)

  docs/md/FSL_APPLICATION_REF.md    -- A walk through of the Olympia fusion
                                       implementation using FSL.
                                       (Planned)

  docs/md/RISCV_ENCODING_FORMATS.md -- Self created encoding formats.
                                       You should consult the official RV
                                       documents for critical uses.

  docs/interp/html/index.html       -- Doxygen generated implementation
                                       documents for the interpreter.
                                       Generate with the make build system

  docs/api/html/index.html          -- Doxygen generated implementation
                                       documents for the C++ API.
                                       Generate with the make build system
```

# FSL Examples

```
  docs/fsl_examples                 -- FSL syntax examples

  test/interp/syntax_tests          -- Syntax example used as part of the
                                       regression.
```

