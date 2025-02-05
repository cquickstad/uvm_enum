// -------------------------------------------------------------
//    Copyright 2025 Chad Quickstad
//    All Rights Reserved Worldwide
//
//    Licensed under the Apache License, Version 2.0 (the
//    "License"); you may not use this file except in
//    compliance with the License.  You may obtain a copy of
//    the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in
//    writing, software distributed under the License is
//    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//    CONDITIONS OF ANY KIND, either express or implied.  See
//    the License for the specific language governing
//    permissions and limitations under the License.
// -------------------------------------------------------------


// The SystemVerilog randomization engine is limited to operating on built-in primitive
// types and cannot call create/new on objects.  To overcome this limitation, uvm_enum_rand
// will wrap the uvm_enum object and pair it with a `rand` scalar type.  The randomization
// engine can then randomly select the scalar value, then the associated uvm_enum can be
// created for that scalar value in post_randomize().
class uvm_rand_enum#(type SCALAR_TYPE=bit, type OBJ_TYPE=_uvm_enum_dummy) extends uvm_object;

    rand SCALAR_TYPE value;
    protected OBJ_TYPE object;

    constraint defined_values_constraint {
        // CAUTION: The SystemVerilog randomization engine will not generate values with
        //          X's or Z's.  If any enum-object value(s) have been defined with X's or
        //          Z's, then this randomization mechanism will not work and must be
        //          supplemented or replaced with some user-provided mechanism.
        value inside {OBJ_TYPE::DEFINED_VALUES};
    }

    `uvm_object_param_utils_begin(uvm_rand_enum#(SCALAR_TYPE, OBJ_TYPE))
        `uvm_field_int(value, UVM_ALL_ON)
        `uvm_field_object(object, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="uvm_rand_enum");
        super.new(name);
        object = OBJ_TYPE::make(value);
    endfunction

    virtual function void set(SCALAR_TYPE value);
        this.value = value;
        object = OBJ_TYPE::make(value);
    endfunction

    virtual function void set_from_string(string name);
        object = OBJ_TYPE::make_from_name(name);
        this.value = object.get_value();
    endfunction

    function void post_randomize();
        object = OBJ_TYPE::make(value);
    endfunction

    virtual function SCALAR_TYPE get_value();
        check_value_object_sync();
        return value;
    endfunction

    virtual function int get_enum_index();
        check_value_object_sync();
        return object.get_enum_index();
    endfunction

    virtual function OBJ_TYPE get_enum();
        check_value_object_sync();
        if (!$cast(get_enum, object.clone())) `uvm_fatal("ENUM_OBJECT_CLONE", "Failed to clone enum object")
    endfunction

    // The object is not the unimplemented_thing null object.
    virtual function bit is_valid();
        check_value_object_sync();
        return object.is_valid();
    endfunction


    // The following are analogous to SystemVerilog's built-in enum methods:

    virtual function void first();
        check_value_object_sync();
        object = object.first();
        value = object.get_value();
    endfunction

    virtual function void last();
        check_value_object_sync();
        object = object.last();
        value = object.get_value();
    endfunction

    virtual function void next(int unsigned N=1);
        check_value_object_sync();
        object = object.next(N);
        value = object.get_value();
    endfunction

    virtual function void prev(int unsigned N=1);
        check_value_object_sync();
        object = object.prev(N);
        value = object.get_value();
    endfunction

    virtual function int num();
        check_value_object_sync();
        return object.num();
    endfunction

    virtual function string name();
        check_value_object_sync();
        return object.get_type_name();
    endfunction



    protected virtual function void check_value_object_sync();
        if ((object != null) && (value === object.get_value())) return;
        $stacktrace;
        `uvm_fatal("ENUM_OBJECT_MISUSED",
            {"The value and the object are out of sync (",
            $sformatf("value:'b%b", value),
            " object.get_value():",
            (object == null) ? "null" : $sformatf("'b%b", object.get_value()),
            "). Although the `value` field is public for the sake",
            " of writing constraints, never assign it directly.",
            " Set it either by calling set() or randomize()."})
    endfunction

endclass
