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


// Base class for object representation of enumerated types.
virtual class uvm_enum#(type SCALAR_TYPE=int, type ENUM_ABC=uvm_object) extends uvm_object;

    function new(string name="uvm_enum");
        super.new(name);
    endfunction

    // Returns the scalar value associated with the enumerated type represented by the
    // object instance. This mimics getting the value of an enum by static type casing.
    // For example, with a standard SystemVerilog enum, you could do:
    //      int value = int'(my_enum);
    // but with enum objects, you can do:
    //      int value = my_enum_obj.get_value();
    pure virtual function SCALAR_TYPE get_value();

    // Returns this value's index into the list of enumerated type object declarations.
    // For example, if 3 enum objects are declared, A, B, and C in that order, then A
    // would have index 0, B would have index 1, and C would have index 2.
    pure virtual function int get_enum_index();

    // Returns the entire set of scalar values registered for the enumerations of the
    // type.
    typedef SCALAR_TYPE _scalar_value_q[$];
    pure virtual function _scalar_value_q get_all_values();

    // Returns the entire set of enum names registered for the enumerations of the
    // type.
    typedef string _enum_name_q[$];
    pure virtual function _enum_name_q get_all_names();

    // Use the enum object factory to create a new enum object for the associated value
    pure virtual function ENUM_ABC create_enum(SCALAR_TYPE value);

    // The object is not the unimplemented_thing null object.
    pure virtual function bit is_valid();

    virtual function bit is_inside(ENUM_ABC set[]);
        ENUM_ABC q[$] = set.find_first() with (this.compare(item));
        foreach (q[i]) return 1;
        return 0;
    endfunction

    virtual function bit is_inside_values(SCALAR_TYPE set[]);
        SCALAR_TYPE v = get_value();
        SCALAR_TYPE q[$] = set.find_first() with (v === item);
        foreach (q[i]) return 1;
        return 0;
    endfunction



    // The following methods mimic SystemVerilog's built-in enum methods of the same
    // name.

    virtual function ENUM_ABC first();
        SCALAR_TYPE vq[$] = get_all_values();
        if (vq.size() > 0) return create_enum(vq[0]);
        `uvm_fatal("EMPTY_ENUM_SET", {"There are no enum objects defined of type `",
            get_type_name(), "`, therefore one cannot be returned"})
        return null;
    endfunction

    virtual function ENUM_ABC last();
        SCALAR_TYPE vq[$] = get_all_values();
        int sz = vq.size();
        if (sz > 0) return create_enum(vq[sz - 1]);
        `uvm_fatal("EMPTY_ENUM_SET", {"There are no enum objects defined of type `",
            get_type_name(), "`, therefore one cannot be returned"})
        return null;
    endfunction

    virtual function ENUM_ABC next(int unsigned N=1);
        SCALAR_TYPE vq[$] = get_all_values();
        int sz = vq.size();
        int next_index = (get_enum_index() + N) % sz;
        if (sz > 0) return create_enum(vq[next_index]);
        `uvm_fatal("EMPTY_ENUM_SET", {"There are no enum objects defined of type `",
            get_type_name(), "`, therefore one cannot be returned"})
        return null;
    endfunction

    virtual function ENUM_ABC prev(int unsigned N=1);
        SCALAR_TYPE vq[$] = get_all_values();
        int sz = vq.size();
        int next_index = (get_enum_index() - N) % sz;
        if (sz > 0) return create_enum(vq[next_index]);
        `uvm_fatal("EMPTY_ENUM_SET", {"There are no enum objects defined of type `",
            get_type_name(), "`, therefore one cannot be returned"})
        return null;
    endfunction

    virtual function int num();
        return get_all_values().size();
    endfunction

    virtual function string name();
        return get_type_name();
    endfunction

endclass


// Declare a dummy version of the virtual base class
// for use as a default type in parameter lists.
class _uvm_enum_dummy extends uvm_enum#(bit, uvm_object);
    static function _scalar_value_q DEFINED_VALUES(); return {}; endfunction
    static function _scalar_value_q DEFINED_NAMES(); return {}; endfunction
    static function SCALAR_TYPE VALUE(); return '0; endfunction
    static function _uvm_enum_dummy make(SCALAR_TYPE value, string name=""); return null; endfunction
    `uvm_object_utils(_uvm_enum_dummy)
    function new(string name="_uvm_enum_dummy"); super.new(name); endfunction
    virtual function SCALAR_TYPE get_value(); return '0; endfunction
    virtual function int get_enum_index(); return 0; endfunction
    virtual function _scalar_value_q get_all_values(); return {}; endfunction
    virtual function _enum_name_q get_all_names(); return {}; endfunction
    virtual function ENUM_ABC create_enum(SCALAR_TYPE value); return null; endfunction
    virtual function bit is_valid(); return 0; endfunction
endclass
