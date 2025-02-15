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


`RUN_PHASE_TEST(color_name_lengths_test)
    // Knowing the longest and shortest name string lengths is useful for output formatting, such as tables.
    `ASSERT_STR_EQ(color_pkg::color_enum::get_longest_name(), "crimson")
    `ASSERT_STR_EQ(color_pkg::color_enum::get_shortest_name(), "red")
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(color_max_min_value_test)
    color_pkg::color_enum max, min;
    // Knowing the largest and smallest values might have general usefulness.
    `ASSERT_EQ(color_pkg::color_enum::get_max_value(), 3)
    `ASSERT_EQ(color_pkg::color_enum::get_min_value(), 0)
    min = color_pkg::color_enum::make_min_value();
    max = color_pkg::color_enum::make_max_value();
    `ASSERT_STR_EQ(min.name(), "red")
    `ASSERT_STR_EQ(max.name(), "yellow")
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


`RUN_PHASE_TEST(comparing_colors_test)
    color_pkg::color_enum a = color_pkg::green::type_id::create("a", this);
    color_pkg::color_enum b = color_pkg::green::type_id::create("b", this);
    color_pkg::color_enum c = color_pkg::blue::type_id::create("c", this);

    color_pkg::color x = color_pkg::color::type_id::create("x", this);
    color_pkg::color y = color_pkg::color::type_id::create("y", this);
    color_pkg::color z = color_pkg::color::type_id::create("z", this);

    uvm_pkg::uvm_comparer p = uvm_pkg::uvm_comparer::init();
    p.show_max = 0; // Turn off that aggravating 'reporter [MISCMP] Miscompare ...' message from UVM.

    // Standard uvm_object calls should work
    `ASSERT_TRUE(a.compare(b))
    `ASSERT_TRUE(b.compare(a))

    `ASSERT_FALSE(b.compare(c))
    `ASSERT_FALSE(c.compare(a))

    x.set(color_pkg::green::VALUE());
    y.set(color_pkg::green::VALUE());
    z.set(color_pkg::blue::VALUE());

    `ASSERT_TRUE(x.compare(y))
    `ASSERT_TRUE(y.compare(x))

    `ASSERT_FALSE(y.compare(z))
    `ASSERT_FALSE(z.compare(x))
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


`RUN_PHASE_TEST(color_set_membership_test)
    color_pkg::color c = color_pkg::color::type_id::create("c", this);
    color_pkg::color r = color_pkg::color::type_id::create("r", this);
    color_pkg::color g = color_pkg::color::type_id::create("g", this);
    color_pkg::color b = color_pkg::color::type_id::create("b", this);
    color_pkg::color rgb[] = {r, g, b};
    int rgb_values[] = {color_pkg::red::VALUE(),
                        color_pkg::green::VALUE(),
                        color_pkg::blue::VALUE()};
    uvm_pkg::uvm_comparer p = uvm_pkg::uvm_comparer::init();
    p.show_max = 0; // Turn off that aggravating 'reporter [MISCMP] Miscompare ...' message from UVM.

    r.set(color_pkg::red::VALUE());
    g.set(color_pkg::green::VALUE());
    b.set(color_pkg::blue::VALUE());

    c.set(color_pkg::red::VALUE());
    `ASSERT_TRUE(c.is_inside(rgb))
    `ASSERT_TRUE(c.is_inside({r, g, b})) // This works too

    c.set(color_pkg::green::VALUE());
    `ASSERT_TRUE(c.is_inside(rgb))

    c.set(color_pkg::blue::VALUE());
    `ASSERT_TRUE(c.is_inside(rgb))

    c.set(color_pkg::yellow::VALUE());
    `ASSERT_FALSE(c.is_inside(rgb))

    c.set(color_pkg::red::VALUE());
    `ASSERT_TRUE(c.is_inside_values(rgb_values))
    `ASSERT_TRUE(c.is_inside_values({color_pkg::red::VALUE(), // This works too
                                    color_pkg::green::VALUE(),
                                    color_pkg::blue::VALUE()}))

    c.set(color_pkg::green::VALUE());
    `ASSERT_TRUE(c.is_inside_values(rgb_values))

    c.set(color_pkg::blue::VALUE());
    `ASSERT_TRUE(c.is_inside_values(rgb_values))

    c.set(color_pkg::yellow::VALUE());
    `ASSERT_FALSE(c.is_inside_values(rgb_values))
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(color_enum_set_membership_test)
    color_pkg::color_enum c;
    color_pkg::color_enum r = color_pkg::red::type_id::create("r", this);
    color_pkg::color_enum g = color_pkg::green::type_id::create("g", this);
    color_pkg::color_enum b = color_pkg::blue::type_id::create("b", this);
    color_pkg::color_enum rgb[] = {r, g, b};
    int rgb_values[] = {color_pkg::red::VALUE(),
                        color_pkg::green::VALUE(),
                        color_pkg::blue::VALUE()};
    uvm_pkg::uvm_comparer p = uvm_pkg::uvm_comparer::init();
    p.show_max = 0; // Turn off that aggravating 'reporter [MISCMP] Miscompare ...' message from UVM.

    `ASSERT_TRUE(color_pkg::red::INSIDE(rgb))
    `ASSERT_TRUE(color_pkg::green::INSIDE(rgb))
    `ASSERT_TRUE(color_pkg::blue::INSIDE(rgb))
    `ASSERT_FALSE(color_pkg::yellow::INSIDE(rgb))

    `ASSERT_TRUE(color_pkg::red::INSIDE_VALUES(rgb_values))
    `ASSERT_TRUE(color_pkg::green::INSIDE_VALUES(rgb_values))
    `ASSERT_TRUE(color_pkg::blue::INSIDE_VALUES(rgb_values))
    `ASSERT_FALSE(color_pkg::yellow::INSIDE_VALUES(rgb_values))

    c = color_pkg::red::type_id::create("c", this);
    `ASSERT_TRUE(c.is_inside(rgb))
    `ASSERT_TRUE(c.is_inside({color_pkg::red::type_id::create(), // This works too
                              color_pkg::green::type_id::create(),
                              color_pkg::blue::type_id::create()}))

    c = color_pkg::green::type_id::create("c", this);
    `ASSERT_TRUE(c.is_inside(rgb))
    c = color_pkg::blue::type_id::create("c", this);
    `ASSERT_TRUE(c.is_inside(rgb))
    c = color_pkg::yellow::type_id::create("c", this);
    `ASSERT_FALSE(c.is_inside(rgb))

    c = color_pkg::red::type_id::create("c", this);
    `ASSERT_TRUE(c.is_inside_values(rgb_values))
    `ASSERT_TRUE(c.is_inside_values({color_pkg::red::VALUE(),
                                     color_pkg::green::VALUE(),
                                     color_pkg::blue::VALUE()}))
    c = color_pkg::green::type_id::create("c", this);
    `ASSERT_TRUE(c.is_inside_values(rgb_values))
    c = color_pkg::blue::type_id::create("c", this);
    `ASSERT_TRUE(c.is_inside_values(rgb_values))
    c = color_pkg::yellow::type_id::create("c", this);
    `ASSERT_FALSE(c.is_inside_values(rgb_values))
`END_RUN_PHASE_TEST
