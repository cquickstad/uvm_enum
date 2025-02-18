`include "uvm_unit.svh" // See https://github.com/cquickstad/uvm_unit
`include "uvm_enum_pkg.sv"


package animal_pkg;
    import uvm_pkg::*;
    import uvm_enum_pkg::*;

    // We will declare an object-based solution that would
    // be analogous to the following SystemVerilog code:
    //
    // typedef enum logic [3:0] {
    //     bird = 0,
    //     horse = 1,
    //     dog = 2
    // } animal;
    //
    // function int get_num_legs(animal a);
    //     case (a)
    //         bird: get_num_legs = 2;
    //         horse, dog: get_num_legs = 4;
    //         default: `uvm_fatal("UNDEFINED_LEGS", "Number of legs undefined")
    //     endcase
    // endfunction
    //
    // function bit can_ride(animal a);
    //     case (a)
    //         bird, dog: can_ride = 0;
    //         horse: can_ride = 1;
    //         default: `uvm_fatal("UNDEFINED_RIDEABILITY", "Undefined rideability")
    //     endcase
    // endfunction


    `UVM_ENUM_OBJ_DECL(animal, logic [3:0],
        // Implement these pure virtual methods in the animal_enum abstract base class
        pure virtual function int get_num_legs();
        pure virtual function bit can_ride();
        ,
        // To make it easier to use the uvm_rand_enum wrapper around the enum,
        // implement pass-through methods.
        virtual function int get_num_legs(); return get_enum().get_num_legs(); endfunction
        virtual function bit can_ride(); return get_enum().can_ride(); endfunction
        ,
        // The unimplemented_animal for the null object pattern must implement the
        // pure virtual methods
        virtual function int get_num_legs(); `uvm_fatal("UNDEFINED_LEGS", "Number of legs undefined") endfunction
        virtual function bit can_ride(); `uvm_fatal("UNDEFINED_RIDEABILITY", "Undefined rideability") endfunction
    )

    `UVM_ENUM_OBJ_VALUE_DECL(animal, bird, 4'h8,
        virtual function int get_num_legs();
            return 2;
        endfunction
        virtual function bit can_ride();
            return 0;
        endfunction
    )

    `UVM_ENUM_OBJ_VALUE_DECL(animal, horse, 4'hF,
        virtual function int get_num_legs();
            return 4;
        endfunction
        virtual function bit can_ride();
            return 1;
        endfunction
    )

    `UVM_ENUM_OBJ_VALUE_DECL(animal, dog, 4'h3,
        virtual function int get_num_legs();
            return 4;
        endfunction
        virtual function bit can_ride();
            return 0;
        endfunction
    )


    // Because these are objects, and not actually enums, the UVM Factory
    // can be used to override an existing type.
    `UVM_ENUM_OBJ_VALUE_OVERRIDE(dog, maimed_dog,
        virtual function int get_num_legs();
            return 3;
        endfunction
    )
endpackage


`RUN_PHASE_TEST(animal_name_lengths_test)
    // Knowing the longest and shortest name string lengths is useful for output formatting, such as tables.
    `ASSERT_STR_EQ(animal_pkg::animal_enum::get_longest_name(), "maimed_dog")
    `ASSERT_STR_EQ(animal_pkg::animal_enum::get_shortest_name(), "dog")
`END_RUN_PHASE_TEST

`RUN_PHASE_TEST(animal_max_min_value_test)
    animal_pkg::animal_enum max, min;
    // Knowing the largest and smallest values might have general usefulness.
    `ASSERT_EQ(animal_pkg::animal_enum::get_max_value(), 4'hF)
    `ASSERT_EQ(animal_pkg::animal_enum::get_min_value(), 4'h3)
    max = animal_pkg::animal_enum::make_max_value();
    min = animal_pkg::animal_enum::make_min_value();
    `ASSERT_STR_EQ(max.name(), "horse")
    `ASSERT_STR_EQ(min.name(), "dog")
`END_RUN_PHASE_TEST



`RUN_PHASE_TEST(animal_test)
    animal_pkg::animal a = animal_pkg::animal::type_id::create("a", this);

    repeat (10) begin
        `ASSERT_TRUE(a.randomize() with {a.value != animal_pkg::dog::value();})
        `ASSERT_NE(a.get_value(), animal_pkg::dog::value())
    end

    a.set(animal_pkg::bird::value());
    `ASSERT_STR_EQ(a.name(), "bird")
    `ASSERT_STR_EQ(a.get_value(), animal_pkg::bird::value())
    `ASSERT_EQ(a.get_num_legs(), 2)
    `ASSERT_FALSE(a.can_ride())

    a.set(animal_pkg::dog::value());
    `ASSERT_STR_EQ(a.name(), "dog")
    `ASSERT_STR_EQ(a.get_value(), animal_pkg::dog::value())
    `ASSERT_EQ(a.get_num_legs(), 4)
    `ASSERT_FALSE(a.can_ride())

    a.set(animal_pkg::horse::value());
    `ASSERT_STR_EQ(a.name(), "horse")
    `ASSERT_STR_EQ(a.get_value(), animal_pkg::horse::value())
    `ASSERT_EQ(a.get_num_legs(), 4)
    `ASSERT_TRUE(a.can_ride())
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(animal_override_test)
    animal_pkg::animal a = animal_pkg::animal::type_id::create("a", this);
    set_type_override_by_type(animal_pkg::dog::get_type(), animal_pkg::maimed_dog::get_type());
    a.set(animal_pkg::dog::value());
    `ASSERT_STR_EQ(a.name(), "maimed_dog")
    `ASSERT_STR_EQ(a.get_value(), animal_pkg::maimed_dog::value())
    `ASSERT_STR_EQ(a.get_value(), animal_pkg::dog::value())
    `ASSERT_EQ(a.get_num_legs(), 3)
    `ASSERT_FALSE(a.can_ride())
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(animal_name_lookup_after_override_test)
    `ASSERT_STR_EQ(animal_pkg::animal_enum::name_lookup(animal_pkg::dog::value()), "dog")
    set_type_override_by_type(animal_pkg::dog::get_type(), animal_pkg::maimed_dog::get_type());
    `ASSERT_STR_EQ(animal_pkg::animal_enum::name_lookup(animal_pkg::dog::value()), "maimed_dog")
`END_RUN_PHASE_TEST
