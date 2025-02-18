`include "uvm_unit.svh" // See https://github.com/cquickstad/uvm_unit
`include "uvm_enum_pkg.sv"

package empty_enum_pkg;
    import uvm_pkg::*;
    import uvm_enum_pkg::*;
    `UVM_ENUM_OBJ_DECL(empty_type)
endpackage


`RUN_PHASE_TEST(test_that_there_is_nothing_to_make)
    empty_enum_pkg::empty_type_enum e;

    e = empty_enum_pkg::empty_type_enum::make(0);
    `ASSERT_NOT_NULL(e)
    if (e != null) `ASSERT_FALSE(e.is_valid())
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(test_that_the_sets_are_empty)
    empty_enum_pkg::empty_type_enum e = empty_enum_pkg::empty_type_enum::make(0);
    `ASSERT_AP_EQ(empty_enum_pkg::empty_type_enum::defined_values(), "'{}")
    `ASSERT_AP_EQ(empty_enum_pkg::empty_type_enum::defined_names(), "'{}")
    `ASSERT_AP_EQ(e.get_all_values(), "'{}")
    `ASSERT_AP_EQ(e.get_all_names(), "'{}")
    `ASSERT_STR_EQ(empty_enum_pkg::empty_type_enum::get_shortest_name(), "")
    `ASSERT_STR_EQ(empty_enum_pkg::empty_type_enum::get_longest_name(), "")
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(test_empty_error_max)
    `EXPECT_FATAL_ID("empty_type_MAX_VALUE")
    void'(empty_enum_pkg::empty_type_enum::get_max_value());
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(test_empty_error_min)
    `EXPECT_FATAL_ID("empty_type_MIN_VALUE")
    void'(empty_enum_pkg::empty_type_enum::get_min_value());
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(test_empty_error_wrapper_create)
    empty_enum_pkg::empty_type e;
    e = empty_enum_pkg::empty_type::type_id::create("e", this);
    `ASSERT_STR_EQ(e.name(), "unimplemented_empty_type")
`END_RUN_PHASE_TEST


`RUN_PHASE_TEST(test_next_unused_value_is_zero)
    `ASSERT_EQ(empty_enum_pkg::empty_type_enum::get_next_unused_value(), 0);
`END_RUN_PHASE_TEST
