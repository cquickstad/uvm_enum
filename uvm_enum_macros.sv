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

`ifndef uvm_enum_obj_registry
`define uvm_enum_obj_registry(ENUM_NAME) \
        typedef struct {uvm_object_wrapper ow; SCALAR_TYPE value;} _num_obj_registry_t; \
        static _num_obj_registry_t _registry[$]; \
        static SCALAR_TYPE DEFINED_VALUES[$]; \
        virtual function _scalar_value_q get_all_values(); \
            return DEFINED_VALUES; \
        endfunction \
        static function int _register_enum(SCALAR_TYPE value, uvm_object_wrapper ow); \
            _num_obj_registry_t r = _registry_lookup(value); \
            if (r.ow != null) begin \
                $fatal(1, $sformatf("Cannot create an enum object for value 'b%0b because it already exists for `%0s`!", \
                    value, r.ow.get_type_name())); \
                return 'X; \
            end \
            r.value = value; \
            r.ow = ow; \
            _registry.push_back(r); \
            _register_enum = DEFINED_VALUES.size(); \
            DEFINED_VALUES.push_back(value); \
        endfunction \
        static function this_enum_obj_type make(SCALAR_TYPE value, string name=""); \
            uvm_factory f = uvm_factory::get(); \
            _num_obj_registry_t r = _registry_lookup(value); \
            string n = ((name == "") && (r.ow != null)) ? r.ow.get_type_name() : name; \
            uvm_object o = (r.ow == null) ? null : f.create_object_by_type(r.ow, , n); \
            if (o == null) return _make_unimplemented_value_null_obj(value); \
            if (!$cast(make, o)) `uvm_fatal({`"ENUM_NAME`", "_CAST"}, $sformatf("Cast failed for object created for value 'b%0b", value)) \
            if (make == null) `uvm_fatal({`"ENUM_NAME`", "_MAKE"}, $sformatf("Failed to make an object for value 'b%0b", value)) \
        endfunction \
        static function unimplemented_``ENUM_NAME`` _make_unimplemented_value_null_obj(SCALAR_TYPE value); \
            _make_unimplemented_value_null_obj = unimplemented_``ENUM_NAME``::type_id::create({"unimplemented_", `"ENUM_NAME`"}); \
            _make_unimplemented_value_null_obj.value = value; \
        endfunction \
        static function _num_obj_registry_t _registry_lookup(SCALAR_TYPE value); \
            _num_obj_registry_t q[$] = _registry.find_first() with (item.value === value); \
            foreach (q[i]) return q[i]; \
            _registry_lookup.ow = null; \
        endfunction \
        static function SCALAR_TYPE _get_next_unused_value(); \
            SCALAR_TYPE q[$] = DEFINED_VALUES.max(); \
            foreach (q[i]) return q[i] + 1; \
            return '0; \
        endfunction \
        virtual function CHILD_TYPE create_enum(SCALAR_TYPE value); \
            return make(value); \
        endfunction
`endif

`ifndef UVM_ENUM_OBJ_DECL
`define UVM_ENUM_OBJ_DECL(ENUM_NAME, ENUM_SCALAR_TYPE=int, ENUM_CLASS_BODY=, ENUM_WRAPPER_BODY=, UNIMPLEMENTED_BODY=) \
    typedef class unimplemented_``ENUM_NAME``; \
    virtual class ``ENUM_NAME``_enum extends uvm_enum#(ENUM_SCALAR_TYPE, ``ENUM_NAME``_enum); \
        typedef ``ENUM_NAME``_enum this_enum_obj_type; \
        `uvm_enum_obj_registry(ENUM_NAME) \
        function new(string name={`"ENUM_NAME`", "_enum"}); \
            super.new(name); \
        endfunction \
        ENUM_CLASS_BODY \
    endclass \
    class unimplemented_``ENUM_NAME`` extends ``ENUM_NAME``_enum; \
        SCALAR_TYPE value; \
        `uvm_object_utils_begin(unimplemented_``ENUM_NAME``) \
            `uvm_field_int(value, UVM_ALL_ON) \
        `uvm_object_utils_end \
        function new(string name={"unimplemented_", `"ENUM_NAME`"}); \
            super.new(name); \
        endfunction \
        virtual function SCALAR_TYPE get_value(); \
            return value; \
        endfunction \
        virtual function int get_enum_index(); \
            $stacktrace; \
            `uvm_fatal("UNIMPLEMENTED_ENUM", {"`", get_type_name(), \
                "` represents any value that is not part of the enumeration.", \
                $sformatf(" value=%0b", value)}) \
            return -1; \
        endfunction \
        UNIMPLEMENTED_BODY \
    endclass \
    class ENUM_NAME extends uvm_rand_enum#(ENUM_SCALAR_TYPE, ``ENUM_NAME``_enum); \
        `uvm_object_utils(ENUM_NAME) \
        function new(string name=`"ENUM_NAME`"); \
            super.new(name); \
        endfunction \
        ENUM_WRAPPER_BODY \
    endclass
`endif


`ifndef UVM_ENUM_OBJ_VALUE_DECL
`define UVM_ENUM_OBJ_VALUE_DECL(ENUM_TYPE_NAME, ENUM_VALUE_NAME, ENUM_VALUE=_get_next_unused_value(), ENUM_CLASS_BODY=) \
    class ENUM_VALUE_NAME extends ``ENUM_TYPE_NAME``_enum; \
        `uvm_object_utils(ENUM_VALUE_NAME) \
        static SCALAR_TYPE VALUE = ENUM_VALUE; \
        static int DEFINED_VALUE_INDEX = _register_enum(.value(ENUM_VALUE),.ow(ENUM_VALUE_NAME::get_type())); \
        function new(string name=`"ENUM_VALUE_NAME`"); \
            super.new(name); \
        endfunction \
        virtual function SCALAR_TYPE get_value(); \
            return VALUE; \
        endfunction \
        virtual function int get_enum_index(); \
            return DEFINED_VALUE_INDEX; \
        endfunction \
        ENUM_CLASS_BODY \
    endclass
`endif


`ifndef UVM_ENUM_OBJ_VALUE_OVERRIDE
`define UVM_ENUM_OBJ_VALUE_OVERRIDE(PARENT_ENUM_VALUE_NAME, CHILD_ENUM_VALUE_NAME, ENUM_CLASS_BODY=) \
    class CHILD_ENUM_VALUE_NAME extends PARENT_ENUM_VALUE_NAME; \
        `uvm_object_utils(CHILD_ENUM_VALUE_NAME) \
        function new(string name=`"ENUM_VALUE_NAME`"); \
            super.new(name); \
        endfunction \
        ENUM_CLASS_BODY \
    endclass
`endif
