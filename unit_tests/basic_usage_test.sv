`include "uvm_unit.svh" // See https://github.com/cquickstad/uvm_unit
`include "uvm_enum_pkg.sv"


package color_pkg;
    import uvm_pkg::*;
    import uvm_enum_pkg::*;


    // We will declare an object-based enumeration that would
    // be analogous to the following SystemVerilog enum:
    //
    // typedef enum int {
    //     red = 0,
    //     green = 1,
    //     blue = 2,
    //     yellow = 3
    // } color;


    // This declares the following classes:
    //  * virtual class color_enum extends uvm_enum(int, color_enum);
    //  * class unimplemented_color extends color_enum;
    //  * class color extends uvm_rand_enum#(int, color_enum)
    `UVM_ENUM_OBJ_DECL(color)

    // This declares the following class for the color enumeration:
    //      class red extends color_enum;
    // A static VALUE member is declared and set to 0
    `UVM_ENUM_OBJ_VALUE_DECL(color, red)

    // This declares the following class for the color enumeration:
    //      class green extends color_enum;
    // A static VALUE member is declared and set to 1
    `UVM_ENUM_OBJ_VALUE_DECL(color, green)

    `UVM_ENUM_OBJ_VALUE_DECL(color, blue)
    `UVM_ENUM_OBJ_VALUE_DECL(color, yellow)

    // Because these are objects, and not actually enums, the UVM Factory
    // can be used to override an existing type.
    //
    // This declares the following class:
    //      class crimson extends red;
    // The static VALUE member for red is retained with its value.
    `UVM_ENUM_OBJ_VALUE_OVERRIDE(red, crimson)
endpackage


`RUN_PHASE_TEST(all_colors_test)
    color_pkg::color_enum ce = color_pkg::color_enum::make(0);
    `ASSERT_AP_EQ(ce.get_all_values(), "'{0, 1, 2, 3}")
    `ASSERT_AP_EQ(ce.get_all_names(), "'{\"red\", \"green\", \"blue\", \"yellow\", \"crimson\"}")
`END_RUN_PHASE_TEST



`RUN_PHASE_TEST(random_color_test)
    int color_count[int];
    color_pkg::color c; // `color` is the wrapper around `color_enum` that allows for .randomize() to select the type

    color_count[color_pkg::red::VALUE()] = 0;
    color_count[color_pkg::green::VALUE()] = 0;
    color_count[color_pkg::blue::VALUE()] = 0;
    color_count[color_pkg::yellow::VALUE()] = 0;

    c = color_pkg::color::type_id::create("c", this);
    repeat (100) begin
        `ASSERT_TRUE(c.randomize() with {c.value != color_pkg::yellow::VALUE();})
        `ASSERT_NE(c.get_value(), color_pkg::yellow::VALUE())
        color_count[c.get_value()] = color_count[c.get_value()] + 1;
    end

    `ASSERT_GT(color_count[color_pkg::red::VALUE()], 0);
    `ASSERT_GT(color_count[color_pkg::green::VALUE()], 0);
    `ASSERT_GT(color_count[color_pkg::blue::VALUE()], 0);

    `ASSERT_EQ(color_count[color_pkg::yellow::VALUE()], 0);
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(set_color_test)
    color_pkg::color c = color_pkg::color::type_id::create("c", this);
    c.set(color_pkg::red::VALUE());
    `ASSERT_EQ(c.get_value(), color_pkg::red::VALUE())
    `ASSERT_STR_EQ(c.name(), "red")
    c.set(color_pkg::yellow::VALUE());
    `ASSERT_EQ(c.get_value(), color_pkg::yellow::VALUE())
    `ASSERT_STR_EQ(c.name(), "yellow")
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(standard_methods_color_test)
    color_pkg::color c = color_pkg::color::type_id::create("c", this);

    c.last(); `ASSERT_EQ(c.get_value(), color_pkg::yellow::VALUE())
    c.first(); `ASSERT_EQ(c.get_value(), color_pkg::red::VALUE())

    c.next(); `ASSERT_EQ(c.get_value(), color_pkg::green::VALUE())
    c.next(); `ASSERT_EQ(c.get_value(), color_pkg::blue::VALUE())
    c.next(); `ASSERT_EQ(c.get_value(), color_pkg::yellow::VALUE())
    c.next(); `ASSERT_EQ(c.get_value(), color_pkg::red::VALUE()) // Wrap
    c.prev(); `ASSERT_STR_EQ(c.name(), "yellow") // Wrap
    c.prev(); `ASSERT_STR_EQ(c.name(), "blue")
    c.prev(); `ASSERT_STR_EQ(c.name(), "green")
    c.prev(); `ASSERT_STR_EQ(c.name(), "red")

    // Wrap with multiple increment/decrement
    c.next(7); `ASSERT_STR_EQ(c.name(), "yellow")
    c.prev(9); `ASSERT_STR_EQ(c.name(), "blue")

    `ASSERT_EQ(c.num(), 4);
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(color_set_from_string_test)
    color_pkg::color c = color_pkg::color::type_id::create("c", this);

    c.set_from_string("yellow");
    `ASSERT_EQ(c.get_value(), color_pkg::yellow::VALUE())
    `ASSERT_TRUE(c.is_valid())

    c.set_from_string("green");
    `ASSERT_EQ(c.get_value(), color_pkg::green::VALUE())
    `ASSERT_TRUE(c.is_valid())

    c.set_from_string("FOO BAR");
    `ASSERT_FALSE(c.is_valid())
    `ASSERT_STR_EQ(c.name(), "unimplemented_color")
    `ASSERT_EQ(c.get_value(), 4)
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(color_enum_make_by_name_test)
    color_pkg::color_enum c;

    c = color_pkg::color_enum::make_from_name("blue");
    `ASSERT_EQ(c.get_value(), color_pkg::blue::VALUE())
    `ASSERT_TRUE(c.is_valid())

    c = color_pkg::color_enum::make_from_name("FOO BAR");
    `ASSERT_FALSE(c.is_valid())
    `ASSERT_STR_EQ(c.name(), "unimplemented_color")
    `ASSERT_EQ(c.get_value(), 4)
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(override_color_test)
    color_pkg::color c;
    color_pkg::color_enum ce;
    color_pkg::red my_red;

    // The standard UVM Factory is used to override an enum value
    set_type_override_by_type(color_pkg::red::get_type(), color_pkg::crimson::get_type());

    c = color_pkg::color::type_id::create("c", this);
    c.set(color_pkg::red::VALUE());
    `ASSERT_STR_EQ(c.name(), "crimson")
    c.set_from_string("red");
    `ASSERT_STR_EQ(c.name(), "crimson")

    my_red = color_pkg::red::type_id::create("my_red", this);
    `ASSERT_STR_EQ(my_red.name(), "crimson")

    ce = color_pkg::color_enum::make_from_name("red");
    `ASSERT_STR_EQ(ce.name(), "crimson")
    `ASSERT_TRUE(ce.is_valid())

    ce = color_pkg::color_enum::make_from_name("crimson");
    `ASSERT_STR_EQ(ce.name(), "crimson")
    `ASSERT_TRUE(ce.is_valid())
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(unimplemented_color_test)
    // The null object pattern is used to handle the error case

    color_pkg::color_enum c = color_pkg::color_enum::make(42); // There is no color 42
    `ASSERT_FALSE(c.is_valid())
    `ASSERT_STR_EQ(c.name(), "unimplemented_color")
    `ASSERT_EQ(c.get_value(), 42)

    `EXPECT_FATAL_ID("UNIMPLEMENTED_ENUM")
    `ASSERT_EQ(c.get_enum_index(), -1)
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(directly_assigning_value_results_in_fatal)
    color_pkg::color c;

    // Directly assigning value means the object is out of sync.

    c = color_pkg::color::type_id::create("c", this);
    c.value = color_pkg::blue::VALUE();
    `EXPECT_FATAL_ID("ENUM_OBJECT_MISUSED")
    void'(c.get_value());

    c = color_pkg::color::type_id::create("c", this);
    c.value = color_pkg::blue::VALUE();
    `EXPECT_FATAL_ID("ENUM_OBJECT_MISUSED")
    void'(c.get_enum_index());

    c = color_pkg::color::type_id::create("c", this);
    c.value = color_pkg::blue::VALUE();
    `EXPECT_FATAL_ID("ENUM_OBJECT_MISUSED")
    void'(c.first());

    c = color_pkg::color::type_id::create("c", this);
    c.value = color_pkg::blue::VALUE();
    `EXPECT_FATAL_ID("ENUM_OBJECT_MISUSED")
    void'(c.last());

    c = color_pkg::color::type_id::create("c", this);
    c.value = color_pkg::blue::VALUE();
    `EXPECT_FATAL_ID("ENUM_OBJECT_MISUSED")
    c.next();

    c = color_pkg::color::type_id::create("c", this);
    c.value = color_pkg::blue::VALUE();
    `EXPECT_FATAL_ID("ENUM_OBJECT_MISUSED")
    c.prev();

    c = color_pkg::color::type_id::create("c", this);
    c.value = color_pkg::blue::VALUE();
    `EXPECT_FATAL_ID("ENUM_OBJECT_MISUSED")
    void'(c.num());

    c = color_pkg::color::type_id::create("c", this);
    c.value = color_pkg::blue::VALUE();
    `EXPECT_FATAL_ID("ENUM_OBJECT_MISUSED")
    void'(c.name());

    c = color_pkg::color::type_id::create("c", this);
    c.value = color_pkg::blue::VALUE();
    `EXPECT_FATAL_ID("ENUM_OBJECT_MISUSED")
    void'(c.get_enum());
`END_RUN_PHASE_TEST
