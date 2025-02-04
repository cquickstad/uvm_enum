# uvm_enum
### An object-oriented alternative to SystemVerilog's native enumerated types.
## SystemVerilog's Enums
The SystemVerilog language (IEEE Std 1800™-2023), like most other languages, offers enumerated types.  For example:
```
typedef enum {
    red,
    green,
    blue
} color;
```
### Advantages
Enumerated types can be defined with an 'enum base type' and the individual name declarations can be assigned integral numerical values. This, along with static type casting, makes enums an attractive solution for assigning meaning to signal values, allowing programmers to feel good about eliminating Magic Number code smells. For example:
```
typedef enum logic [1:0] {
    OKAY = 2'b00,
    EXOKAY = 2'b01,
    SLVERR = 2'b10,
    DECERR = 2'b11
} xRESP_t;

function xRESP_t decode_xRESP(logic [1:0] field);
    return xRESP_t'(field);
endfunction
```
Additionally, SystemVerilog's randomization works natively with enumerated types, making them indispensable in the test-bench.  For example:
```
class axi_item extends uvm_item;
    ...
    rand xRESP_t xRESP;
    constraint xRESP_c {xRESP inside {OKAY, EXOKAY};}
    ...
endclass
```
Finally, SystemVerilog offers built-in methods for enums, such as as `.name()`, which returns the string representation of the value.  For example:
```
function void check_for_error(xRESP_t xRESP);
    if (!(xRESP inside {OKAY, EXOKAY})) begin
        `uvm_error("XRESP_ERROR", {"The following error occurred: ",
            xRESP.name()})
    end
endfunction
```
### Problems
Upon encountering an enum in another package such as a Verification IP (VIP), one finds that they are stuck with that definition. This is because enum definitions are fixed and cannot be changed or expanded. For example, if someone used a software package with `typedef enum {red, green, blue} color;` defined it would be impossible for them to add `purple` or override `red` to `crimson`.  This is violates the 'O' in the SOLID design principles -- the Open-closed principle, which states that _"software entities should be open for extension, but closed for modification."_  This is a major hurdle to reuse. It is not uncommon for a project to need to tweak a behavior or add an opcode to an field that was left with "reserved" space.

Additionally, using SystemVerilog enums tends to lead to several code smells:
- **Switch/Case Statements** - Switch/case statements (or equivalent if/else chains) are almost always a missed opportunity to use polymorphism. They create a dependency fan-out problem that can be solved with a polymorphic abstract base class interface.
- **Primitive Obsession** - Primitive obsession is the use of primitives (e.g.integers, booleans, strings, or arrays) instead of small objects for simple tasks. In particular, enums are really just fancy integers. Often, functionality related to the enum gets scattered around the codebase, often being duplicated. This leads to other code smells and maintainability problems.
- **Shotgun Surgery** - Shotgun surgery is when making a fix or modification to a single concept requires making changes in many different places around the codebase.  It's a sign that the concept was not properly abstracted. A simple concept change suddenly becomes complex in implementation. Some of the needed points of change can be forgotten, leading to bugs.

These problems reveal that, in many use cases, enums are a software design anti-pattern. Verification engineers that use enums are often not using the best tool for the job.

### Solution
All of these problems can be overcome by using objects instead of enums.  However, most digital logic verification engineers find it difficult to give up the advantages that come built-in with SystemVerilog's enums. Furthermore, they often lack the time or skill to develop the object-oriented solution and end up developing code that is hard to maintain and difficult to reuse.

**uvm_enum** is the library that provides the solution.  It...
- implements most of the advantages that enums have natively.
- provides macros to declare classes that represent enumerated types with a similar number of lines of code to the native enums.
- allows methods to be added to the objects so that all of those switch/case statements can be solved with polymorphism and that all of that code scattered around the codebase can be consolidated into an object that encapsulates the concept being abstracted.
- allows new enum-objects to be easily added. Downstream projects can reuse your code without requiring intrusive changes.
- allows the existing and familiar UVM Factory to be used to override an old enum-object with a new enum-object.

## How To Use
### Declaration
Instead of
```
typedef enum {
    red,
    green,
    blue
} color;
```
write
```
`include "uvm_enum_pkg.sv"
import uvm_enum_pkg::*;

`UVM_ENUM_OBJ_DECL(color)
`UVM_ENUM_OBJ_VALUE_DECL(color, red)
`UVM_ENUM_OBJ_VALUE_DECL(color, green)
`UVM_ENUM_OBJ_VALUE_DECL(color, blue)
```
The line `` `UVM_ENUM_OBJ_DECL(color, int)`` will declare the following classes:
- `virtual class color_enum extends uvm_enum#(int, color_enum);` - The abstract base class for the enumerated type.
- `class unimplemented_color extends color_enum;` - Implements the 'null object design pattern' for the error case where the user attempts to set an undeclared value.
- `class color extends uvm_rand_enum#(int, color_enum);` - Implements a randomization wrapper class containing both the scalar value (as `rand`) and a handle to the matching instance of `color_enum`.

The line `` `UVM_ENUM_OBJ_VALUE_DECL(color, blue)`` will declare the following class:
- `class blue extends color_enum;` - Represents the `blue` enumeration and has a `static int` member named `VALUE` that is set to `2`.

The `color_enum` abstract base class and `red`, `green`, and `blue` enumeration implementation classes may be used directly. However, where randomization is required, the `color` container class should be used.

---
### Randomization/Constraints
Instead of
```
class item extends uvm_object;
    ...
    rand color c;
    constraint color_c {c != green;}
    ...
endclass
```
write
```
class item extends uvm_object;
    ...
    rand color c;
    constraint color_c {c.value != green::VALUE;}
    ...
    function new(string name="item");
        super.new(name);
        ...
        c = color::type_id::create("c");
    endfunction
    ...
endclass
```
---
### Accessing the Scalar Representation
Instead of
```
color c = blue;
int i = int'(c);
```
write
```
color c = color::type_id::create("c");
c.set(blue::VALUE);
int i = c.get_value();
```
or
```
blue b = blue::type_id::create("b");
int i = b.get_value();
```
or simply
```
int i = blue::VALUE;
```
---
### Converting a Scalar to the Enumeration
Instead of
```
int i = 2;
color c = color'(i);
```
write
```
int i = 2;
color c = color::type_id::create("c");
c.set(i);
```
or
```
int i = 2;
color_enum c = color_enum::make(i);
```
---
### Built-In Enum Methods
Instead of
```
color c = green;
c = c.next();
$display("%0s is after green", c.name());
```
write
```
color c = color::type_id::create("c");
c.set(green::VALUE);
c.next();
$display("%0s is after green", c.name());
```
or
```
color_enum c = green::type_id::create("c");
c = c.next();
$display("%0s is after green", c.name());
```
---
### Adding Methods
Instead of
```
typedef enum logic [3:0] {
    bird = 0,
    horse = 1,
    dog = 2
} animal;

function int get_num_legs(animal a);
    case (a)
        bird: get_num_legs = 2;
        horse, dog: get_num_legs = 4;
        default: `uvm_fatal("UNDEFINED_LEGS", "Number of legs undefined")
    endcase
endfunction

function bit can_ride(animal a);
    case (a)
        bird, dog: can_ride = 0;
        horse: can_ride = 1;
        default: `uvm_fatal("UNDEFINED_RIDEABILITY", "Undefined rideability")
    endcase
endfunction

function void explain_all_animals();
    animal a;
    a = a.first();
    repeat (a.num()) begin
        explain_animal(a);
        a = a.next();
    end
endfunction

function void explain_animal(animal a);
    int legs;
    string ride;
    legs = get_num_legs(a);
    ride = can_ride(a) ? "may" : "may not";
    $display("The %0s has %0d legs and you %0s ride it.",
        a.name(), legs, ride);
endfunction
```
write
```
`UVM_ENUM_OBJ_DECL(animal, logic [3:0],
    pure virtual function int get_num_legs();
    pure virtual function bit can_ride();
    ,
    // Implement pass-through methods for the wrapper class.
    virtual function int get_num_legs();
        return get_enum().get_num_legs();
    endfunction
    virtual function bit can_ride();
        return get_enum().can_ride();
    endfunction
    ,
    // Implement the pure virtual methods for the unimplemented_animal object.
    virtual function int get_num_legs();
        `uvm_fatal("UNDEFINED_LEGS", "Number of legs undefined")
    endfunction
    virtual function bit can_ride();
        `uvm_fatal("UNDEFINED_RIDEABILITY", "Undefined rideability")
    endfunction
)

`UVM_ENUM_OBJ_VALUE_DECL(animal, bird, 0,
    virtual function int get_num_legs();
        return 2;
    endfunction
    virtual function bit can_ride();
        return 0;
    endfunction
)

`UVM_ENUM_OBJ_VALUE_DECL(animal, horse, 1,
    virtual function int get_num_legs();
        return 4;
    endfunction
    virtual function bit can_ride();
        return 1;
    endfunction
)

`UVM_ENUM_OBJ_VALUE_DECL(animal, dog, 2,
    virtual function int get_num_legs();
        return 4;
    endfunction
    virtual function bit can_ride();
        return 0;
    endfunction
)

function void explain_all_animals();
    animal a;
    a = animal::type_id::create("a");
    a.first();
    repeat (a.num()) begin
        explain_animal(a);
        a.next();
    end
endfunction

function void explain_animal(animal a);
    int legs;
    string ride;
    legs = a.get_num_legs();
    ride = a.can_ride() ? "may" : "may not";
    $display("The %0s has %0d legs and you %0s ride it.",
        a.name(), legs, ride);
endfunction
```
To illustrate how extendable the class-based solution is, more animals can be added simply by declaring them. The original code need not be touched.  It just works.
```
`UVM_ENUM_OBJ_VALUE_DECL(animal, deer, 3,
    virtual function int get_num_legs();
        return 4;
    endfunction
    virtual function bit can_ride();
        return 0;
    endfunction
)

`UVM_ENUM_OBJ_VALUE_DECL(animal, elephant, 4,
    virtual function int get_num_legs();
        return 4;
    endfunction
    virtual function bit can_ride();
        return 1;
    endfunction
)
```
Even existing enum objects can be overridden with polymorphism and the UVM Factory:
```
`UVM_ENUM_OBJ_VALUE_OVERRIDE(dog, maimed_dog,
    virtual function int get_num_legs();
        return 3;
    endfunction
)

...

    set_type_override_by_type(dog::get_type(),
                              maimed_dog::get_type());
```