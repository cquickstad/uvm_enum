`include "uvm_unit.svh" // See https://github.com/cquickstad/uvm_unit
`include "uvm_enum_pkg.sv"


package cplx_pkg;
    import uvm_pkg::*;
    import uvm_enum_pkg::*;

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


    class item extends uvm_object;
        `uvm_object_utils(item)
        rand animal a;
        rand int payload;
        constraint payload_c {
            // The LRM says "functions that appear in constraint expressions
            // shall be automatic (or preserve no state information) and have
            // no side effects."
            //
            // Also, the LRM says "Function calls in active constraints are
            // executed an unspecified number of times (at least once) in an
            // unspecified order."
            //
            // Therefore, you cannot create the correct animal/animal_enum instance
            // for 'a' in the constraint expression.  A way around this is to use
            // a helper function to call the virtual method.  This is not performant.
            //
            if (_can_ride(a.value)) {
                payload == _get_num_legs(a.value) * 100;
            } else {
                payload == 10;
            }
        }
        function new(string name="");
            super.new(name);
            a = animal::type_id::create("a");
        endfunction

        // These helper functions use local variables and have no side effects.
        protected virtual function int _can_ride(logic [3:0] value);
            const animal_enum tmp = animal_enum::make(value);
            return tmp.can_ride();
        endfunction
        protected virtual function int _get_num_legs(logic [3:0] value);
            const animal_enum tmp = animal_enum::make(value);
            return tmp.get_num_legs();
        endfunction
    endclass

endpackage


`RUN_PHASE_TEST(complex_constraints_test)
    cplx_pkg::item i = cplx_pkg::item::type_id::create("i", this);
    `ASSERT_TRUE(i.randomize() with {a.value == cplx_pkg::horse::value();})
    `ASSERT_EQ(i.payload, 400)
    `ASSERT_TRUE(i.randomize() with {a.value == cplx_pkg::bird::value();})
    `ASSERT_EQ(i.payload, 10)
`END_RUN_PHASE_TEST
