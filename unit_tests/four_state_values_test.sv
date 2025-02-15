`include "uvm_unit.svh" // See https://github.com/cquickstad/uvm_unit
`include "uvm_enum_pkg.sv"


package four_state_pkg;
    import uvm_pkg::*;
    import uvm_enum_pkg::*;

    // We will declare an object-based enumeration that would
    // be analogous to the following SystemVerilog enum:
    //
    // typedef enum logic {
    //     zero = 1'b0,
    //     one = 1'b1,
    //     ex = 1'bX,
    //     zee = 1'bZ
    // } four_state;
    //
    // (By the way, you cannot randomize the above enumerated type.  The simulator will throw
    //  a run-time error.)

    `UVM_ENUM_OBJ_DECL(four_state, logic, ,
        function void post_randomize();
            value = _DEFINED_VALUES[$urandom_range(_DEFINED_VALUES.size() - 1, 0)];
            object = ENUM_OBJ_TYPE::make(value);
        endfunction
    )
    `UVM_ENUM_OBJ_VALUE_DECL(four_state, zero, 1'b0) // get_enum_index() -> 0
    `UVM_ENUM_OBJ_VALUE_DECL(four_state, one, 1'b1) // get_enum_index() -> 1
    `UVM_ENUM_OBJ_VALUE_DECL(four_state, ex, 1'bX) // get_enum_index() -> 2
    `UVM_ENUM_OBJ_VALUE_DECL(four_state, zee, 1'bZ) // get_enum_index() -> 3
endpackage



`RUN_PHASE_TEST(set_four_state_test)
    four_state_pkg::four_state f = four_state_pkg::four_state::type_id::create("f", this);
    f.set(1'b0); `ASSERT_STR_EQ(f.name(), "zero")
    f.set(1'b1); `ASSERT_STR_EQ(f.name(), "one")
    f.set(1'bX); `ASSERT_STR_EQ(f.name(), "ex")
    f.set(1'bZ); `ASSERT_STR_EQ(f.name(), "zee")
`END_RUN_PHASE_TEST

`RUN_PHASE_TEST(randomize_four_state_test)
    int index_count[4];
    four_state_pkg::four_state f = four_state_pkg::four_state::type_id::create("f", this);

    // Prevent an error from X/Z being referenced by defined_values_constraint.
    f.defined_values_constraint.constraint_mode(0);

    repeat (100) begin
        int i;
        `ASSERT_TRUE(f.randomize())
        i = f.get_enum_index();
        index_count[i]++;
    end
    `ASSERT_TRUE(index_count[0] inside {[10:90]})
    `ASSERT_TRUE(index_count[1] inside {[10:90]})
    `ASSERT_TRUE(index_count[2] inside {[10:90]})
    `ASSERT_TRUE(index_count[3] inside {[10:90]})
    $display("index_count:%p", index_count);
`END_RUN_PHASE_TEST



`RUN_PHASE_TEST(compare_four_state_test)
    four_state_pkg::four_state x = four_state_pkg::four_state::type_id::create("x", this);
    four_state_pkg::four_state x2 = four_state_pkg::four_state::type_id::create("x2", this);
    four_state_pkg::four_state z = four_state_pkg::four_state::type_id::create("z", this);
    uvm_pkg::uvm_comparer p = uvm_pkg::uvm_comparer::init();
    p.show_max = 0; // Turn off that aggravating 'reporter [MISCMP] Miscompare ...' message from UVM.
    x.set(1'bX);
    x2.set(1'bX);
    z.set(1'bZ);
    `ASSERT_TRUE(x.compare(x2))
    `ASSERT_FALSE(x.compare(z))
`END_RUN_PHASE_TEST



`RUN_PHASE_TEST(set_membership_four_state_test)
    four_state_pkg::four_state_enum e;
    four_state_pkg::four_state_enum x = four_state_pkg::ex::type_id::create("x", this);
    four_state_pkg::four_state_enum z = four_state_pkg::zee::type_id::create("z", this);
    four_state_pkg::four_state_enum o = four_state_pkg::one::type_id::create("o", this);
    four_state_pkg::four_state_enum set[] = {z, o};
    logic values_set[] = {1'bZ, 1'b1};

    uvm_pkg::uvm_comparer p = uvm_pkg::uvm_comparer::init();
    p.show_max = 0; // Turn off that aggravating 'reporter [MISCMP] Miscompare ...' message from UVM.

    `ASSERT_FALSE(four_state_pkg::ex::INSIDE(set))
    `ASSERT_TRUE(four_state_pkg::zee::INSIDE(set))
    `ASSERT_TRUE(four_state_pkg::one::INSIDE(set))

    `ASSERT_FALSE(four_state_pkg::ex::INSIDE_VALUES(values_set))
    `ASSERT_TRUE(four_state_pkg::zee::INSIDE_VALUES(values_set))
    `ASSERT_TRUE(four_state_pkg::one::INSIDE_VALUES(values_set))

    e = four_state_pkg::ex::type_id::create("e", this);
    `ASSERT_FALSE(e.is_inside(set))
    e = four_state_pkg::zee::type_id::create("e", this);
    `ASSERT_TRUE(e.is_inside(set))
    e = four_state_pkg::one::type_id::create("e", this);
    `ASSERT_TRUE(e.is_inside(set))

    e = four_state_pkg::ex::type_id::create("e", this);
    `ASSERT_FALSE(e.is_inside_values(values_set))
    e = four_state_pkg::zee::type_id::create("e", this);
    `ASSERT_TRUE(e.is_inside_values(values_set))
    e = four_state_pkg::one::type_id::create("e", this);
    `ASSERT_TRUE(e.is_inside_values(values_set))
`END_RUN_PHASE_TEST
