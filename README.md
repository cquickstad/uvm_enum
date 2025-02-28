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
Upon encountering an enum in another package such as a Verification IP (VIP), one finds that they are stuck with that definition. This is because enum definitions are fixed and cannot be changed or expanded. For example, if someone used a software package with `typedef enum {red, green, blue} color;` defined it would be impossible for them to add `purple` or override `red` to `crimson`.  This is violates the 'O' in the SOLID design principles -- the Open-closed principle, which states that _"software entities should be open for extension, but closed for modification."_  This is a major hurdle to reuse. It is not uncommon for a project to need to tweak a behavior or add an opcode to a field that was left with "reserved" space.

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
- allows methods to be added to the objects so that all of those switch/case statements can be solved with polymorphism. All of that code scattered around the codebase can be consolidated into an object that encapsulates the concept being abstracted.
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
The line `` `UVM_ENUM_OBJ_DECL(color)`` will declare the following classes:
- `virtual class color_enum extends uvm_enum#(int, color_enum);` - The abstract base class for the enumerated type. (Defaults to scalar type `int` when left unspecified.)
- `class unimplemented_color extends color_enum;` - Implements the 'null object design pattern' for the error case where the user attempts to set an undeclared value. This object will return `0` (false) when the `is_valid()` method is called. Calls to `next()` and `prev()` will result in a fatal error.
- `class color extends uvm_rand_enum#(int, color_enum);` - Implements a randomization wrapper class containing both the scalar value (as `rand`) and a handle to the matching instance of `color_enum`. This class is needed because SystemVerilog's randomization engine only works on built-in types and it cannot create or choose a class instance, nor can constraints be written to do so.  By the way, never set this object's value member directly (it was left public only for random constraint access compatibility). Only change the value member using `.randomize()` or `.set()`.

The line `` `UVM_ENUM_OBJ_VALUE_DECL(color, blue)`` will declare the following class:
- `class blue extends color_enum;` - Represents the `blue` enumeration and has a scalar value of `2` that can be retrieved with the `get_value()` method or the `blue::value()` static method.

The `color_enum` abstract base class and `red`, `green`, and `blue` enumeration implementation classes may be used directly. However, where randomization is required, the `color` container class should be used.

---
### Randomization
Instead of
```
color c;
bit success = std::randomize(c) with {c != green;};
```
write
```
color c = color::type_id::create("c", this);
bit success = c.randomize() with {value != green::value();};
```
---
### Randomization/Constraints in an Object
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
    constraint color_c {c.value != green::value();}
    ...
    function new(string name="item");
        super.new(name);
        ...
        c = color::type_id::create("c");
    endfunction
    ...
endclass
```
_(Remember that if a class handle members are declared as `rand`, and are not `null` when `.randomize()` is called on the class, SystemVerilog will follow the handles and also call `.randomize()` on those classes.  In other words, calling `item.randomize()` in the above example, will also cause `item.c.randomize()` to be called.)_

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
c.set(blue::value());
int i = c.get_value();
```
or
```
blue b = blue::type_id::create("b");
int i = b.get_value();
```
or simply
```
int i = blue::value();
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
### Converting a String to the Enumeration
Instead of
```
color c;
bit success = uvm_enum_wrapper#(color)::from_name("blue", c);
```
write
```
color c = color::type_id::create("c");
bit success;
c.set_from_name("blue");
success = c.is_valid();
```
or
```
color_enum c = color_enum::make_from_name("blue");
bit success = c.is_valid();
```
---
### Comparing enums
Instead of
```
color a = green;
color b = green;
color c = blue;

assert(a == b);
assert(a != c);
```
write
```
color a = color::type_id::create("a");
color b = color::type_id::create("b");
color c = color::type_id::create("c");

a.set(green::value());
b.set(green::value());
c.set(blue::value());

assert(a.compare(b));
assert(!a.compare(c));
```
or
```
color_enum a = color_enum::make(green::value(), "a");
color_enum b = color_enum::make(green::value(), "b");
color_enum c = color_enum::make(blue::value(), "c");

assert(a.compare(b));
assert(!a.compare(c));
```
---
### Testing Set Membership
Instead of
```
color a = green;
assert(a inside {green, blue});

a = red;
assert(!(a inside {green, blue}));
```
write
```
color a = color::type_id::create("a");
color b = color::type_id::create("b");
color c = color::type_id::create("c");

b.set(green::value());
c.set(blue::value());

a.set(green::value());
assert(a.is_inside({b, c}));

a.set(red::value());
assert(!a.is_inside({b, c}));
```
or
```
color a = color::type_id::create("a");

a.set(green::value());
assert(a.is_inside_values({green::value(), blue::value()}));

a.set(red::value());
assert(!a.is_inside_values({green::value(), blue::value()}));
```
or
```
assert(green::inside_objects({green::type_id::create(), blue::type_id::create()}))
assert(green::inside_values({green::value(), blue::value()}))
```
or
```
color_enum a = color_enum::make(green::value(), "a");
assert(a.is_inside({green::type_id::create(), blue::type_id::create()}))
assert(a.is_inside_values({green::value(), blue::value()}))
```
---
### Testing Range
Instead of
```
color a = green;
assert(a inside {[red:blue]});
```
write
```
color a = color::type_id::create("a");
a.set(green::value());
assert(a.is_inside_value_range(red::value(), blue::value()));
```
or
```
color_enum a = color_enum::make(green::value(), "a");
assert(a.is_inside_value_range(red::value(), blue::value()));
```
or
```
assert(green::inside_value_range(red::value(), blue::value()));
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
c.set(green::value());
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
    bird = 4'b0000,
    horse = 4'b0001,
    dog = 4'b0010
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
typedef logic [3:0] animal_scalar_t;
`UVM_ENUM_OBJ_DECL(animal, animal_scalar_t,
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

`UVM_ENUM_OBJ_VALUE_DECL(animal, bird, 4'b0000,
    virtual function int get_num_legs();
        return 2;
    endfunction
    virtual function bit can_ride();
        return 0;
    endfunction
)

`UVM_ENUM_OBJ_VALUE_DECL(animal, horse, 4'b0001,
    virtual function int get_num_legs();
        return 4;
    endfunction
    virtual function bit can_ride();
        return 1;
    endfunction
)

`UVM_ENUM_OBJ_VALUE_DECL(animal, dog, 4'b0010,
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

This illustrates the _dependency inversion principle_ (the D in SOLID). Both `explain_animal()` and the individual animals depend on the `animal_enum` abstract base class.
```
`UVM_ENUM_OBJ_VALUE_DECL(animal, deer, 4'b0011,
    virtual function int get_num_legs();
        return 4;
    endfunction
    virtual function bit can_ride();
        return 0;
    endfunction
)

`UVM_ENUM_OBJ_VALUE_DECL(animal, elephant, 4'b0100,
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
---
### Indexing Into an Associative Array
Instead of
```
int aa[animal];
aa[dog] = 123;
assert(aa.exists(dog));
foreach (aa[a]) begin
    $display("Animal %0s has value %0d", a.name(), aa[a]);
end
```
write
```
int aa[animal_scalar_t];
aa[animal::dog::value()] = 123;
assert(aa.exists(animal::dog::value()));
foreach (aa[i]) begin
    $display("Animal %0s has value %0d", animal_enum::name_lookup(i), aa[i]);
end
```

---
### Complex Constraints
You may find that you want to write a constraint that references the methods of the enumerated type object.  Unfortunately the SystemVerilog LRM has the following restrictions:
* "Functions that appear in constraint expressions shall be automatic (or preserve no state information) and have no side effects."
* "Function calls in passive constraints are executed an unspecified number of times (at least once) in an unspecified order."

Therefore, you cannot write a constraint that creates the correct child type of the enumerated object, then references the methods of the enumerated type object.
For example, you might want to write a constraint like this:
```
class item extends uvm_object;
    rand animal a;
    rand int payload;
    constraint c {
        // ERROR: a.object is not created with the correct
        //        type until post_randomize(). The methods
        //        simply don't work until then.
        if (a.can_ride()) {
            payload == a.get_num_legs() * 100;
        } else {
            payload == 5;
        }
    }
    `uvm_object_utils(item)
    function new(string name="item");
        super.new(name);
    endfunction
endclass
```
Instead, because of the quoted SystemVerilog limitations, you must write write helper functions that have no side effects:
```
class item extends uvm_object;
    rand animal a;
    rand int payload;
    constraint c {
        // ERROR: a.object is not created with the correct
        //        type until post_randomize(). The methods
        //        simply don't work until then.
        if (can_ride_rand_helper(a.value)) {
            payload == get_num_legs_rand_helper(a.value) * 100;
        } else {
            payload == 5;
        }
    }
    `uvm_object_utils(item)
    function new(string name="item");
        super.new(name);
    endfunction
    virtual function int can_ride_rand_helper(animal_scalar_t value);
        // Local variable preserves no state information
        // and has no side effects.
        const animal_enum tmp = animal_enum::make(value);
        return tmp.can_ride();
    endfunction
    virtual function int get_num_legs_rand_helper(animal_scalar_t value);
        const animal_enum tmp = animal_enum::make(value);
        return tmp.get_num_legs();
    endfunction
endclass
```
This is annoying and not performant, but it works around a major and obvious limitation of SystemVerilog: randomization does not support creating objects. It's almost like SystemVerilog is trying to prevent you from doing the right thing and force you into primitive obsessions.