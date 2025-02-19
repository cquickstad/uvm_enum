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

`ifndef _uvm_enum_obj_registry
`define _uvm_enum_obj_registry(ENUM_NAME) \
        typedef struct {uvm_object_wrapper ow; SCALAR_TYPE value;} _enum_registry_t; \
        protected static _enum_registry_t _registry[$]; \
        protected static SCALAR_TYPE _defined_values[$]; \
        protected static string _defined_names[$]; \
        protected static function int _register_enum(SCALAR_TYPE value, uvm_object_wrapper ow); \
            _enum_registry_t r = _registry_lookup(value); \
            if (r.ow != null) begin \
                $fatal(1, $sformatf("Cannot create an enum object for value 'b%0b because it already exists for `%0s`!", \
                    value, r.ow.get_type_name())); \
                return 'X; \
            end \
            r.value = value; \
            r.ow = ow; \
            _registry.push_back(r); \
            _register_enum = _defined_values.size(); \
            _defined_values.push_back(value); \
            _defined_names.push_back(ow.get_type_name()) ;\
        endfunction \
        protected static function bit _append_name(string name); \
            _defined_names.push_back(name); \
        endfunction \
        static function ENUM_ABC make(SCALAR_TYPE value, string uvm_object_name=""); \
            uvm_factory f = uvm_factory::get(); \
            _enum_registry_t r = _registry_lookup(value); \
            string n = ((uvm_object_name == "") && (r.ow != null)) ? r.ow.get_type_name() : uvm_object_name; \
            uvm_object o = (r.ow == null) ? null : f.create_object_by_type(r.ow, , n); \
            if (o == null) return _make_unimplemented_value_enum(value); \
            if (!$cast(make, o)) `uvm_fatal({`"ENUM_NAME`", "_CAST"}, $sformatf("Cast failed for object created for value 'b%0b", value)) \
            if (make == null) `uvm_fatal({`"ENUM_NAME`", "_MAKE"}, $sformatf("Failed to make an object for value 'b%0b", value)) \
        endfunction \
        static function ENUM_ABC make_from_name(string name); \
            uvm_factory f = uvm_factory::get(); \
            uvm_object o = (name inside {_defined_names}) ? f.create_object_by_name(name) : null; \
            if (o == null) return _make_unimplemented_value_enum(get_next_unused_value()); \
            if (!$cast(make_from_name, o)) `uvm_fatal({`"ENUM_NAME`", "_CAST"}, $sformatf("Cast failed for object created for name '%0s'", name)) \
            if (make_from_name == null) `uvm_fatal({`"ENUM_NAME`", "_MAKE"}, $sformatf("Failed to make an object for value '%0s'", name)) \
        endfunction \
        protected static function unimplemented_``ENUM_NAME`` _make_unimplemented_value_enum(SCALAR_TYPE value); \
            _make_unimplemented_value_enum = unimplemented_``ENUM_NAME``::type_id::create({"unimplemented_", `"ENUM_NAME`"}); \
            _make_unimplemented_value_enum.value = value; \
        endfunction \
        protected static function _enum_registry_t _registry_lookup(SCALAR_TYPE value); \
            _enum_registry_t q[$] = _registry.find_first() with (item.value === value); \
            foreach (q[i]) return q[i]; \
            _registry_lookup.ow = null; \
        endfunction
`endif


`ifndef _uvm_enum_obj_helpers
`define _uvm_enum_obj_helpers(ENUM_NAME) \
        static function _scalar_value_q defined_values(); \
            return _defined_values; \
        endfunction \
        static function _enum_name_q defined_names(); \
            return _defined_names; \
        endfunction \
        static function string name_lookup(SCALAR_TYPE value); \
            _enum_registry_t rq[$] = _registry.find_first() with (item.value === value); \
            foreach (rq[i]) begin \
                uvm_factory f = uvm_factory::get(); \
                uvm_object_wrapper ow = f.find_override_by_type(rq[i].ow, ""); \
                return ow.get_type_name(); \
            end \
            return {"unimplemented_", `"ENUM_NAME`"}; \
        endfunction \
        virtual function _scalar_value_q get_all_values(); \
            return _defined_values; \
        endfunction \
        virtual function _enum_name_q get_all_names(); \
            return _defined_names; \
        endfunction \
        static function SCALAR_TYPE get_max_value(); \
            SCALAR_TYPE q[$] = _defined_values.max(); \
            foreach (q[i]) return q[i]; \
            $stacktrace; \
            `uvm_fatal({`"ENUM_NAME`", "_MAX_VALUE"}, \
                $sformatf("Failed to find max value for %0s among values %p", \
                    `"ENUM_NAME`", _defined_values)) \
        endfunction \
        static function SCALAR_TYPE get_min_value(); \
            SCALAR_TYPE q[$] = _defined_values.min(); \
            foreach (q[i]) return q[i]; \
            $stacktrace; \
            `uvm_fatal({`"ENUM_NAME`", "_MIN_VALUE"}, \
                $sformatf("Failed to find min value for %0s among values %p", \
                    `"ENUM_NAME`", _defined_values)) \
        endfunction \
        static function ENUM_ABC make_max_value(string uvm_object_name=""); \
            return make(get_max_value(), uvm_object_name); \
        endfunction \
        static function ENUM_ABC make_min_value(string uvm_object_name=""); \
            return make(get_min_value(), uvm_object_name); \
        endfunction \
        static function SCALAR_TYPE get_next_unused_value(); \
            return (_defined_values.size() == 0) ? '0 : get_max_value() + SCALAR_TYPE'(1); \
        endfunction \
        static function string get_longest_name(); \
            string q[$] = _defined_names.max() with (item.len()); \
            foreach (q[i]) return q[i]; \
            return ""; \
        endfunction \
        static function string get_shortest_name(); \
            string q[$] = _defined_names.min() with (item.len()); \
            foreach (q[i]) return q[i]; \
            return ""; \
        endfunction \
        virtual function ENUM_ABC create_enum(SCALAR_TYPE value); \
            return make(value); \
        endfunction
`endif


`ifndef UVM_ENUM_OBJ_DECL
`define UVM_ENUM_OBJ_DECL(ENUM_NAME, ENUM_SCALAR_TYPE=int, ENUM_CLASS_BODY=, ENUM_WRAPPER_BODY=, UNIMPLEMENTED_BODY=) \
    typedef class unimplemented_``ENUM_NAME``; \
    virtual class ``ENUM_NAME``_enum extends uvm_enum#(ENUM_SCALAR_TYPE, ``ENUM_NAME``_enum); \
        `_uvm_enum_obj_registry(ENUM_NAME) \
        `_uvm_enum_obj_helpers(ENUM_NAME) \
        function new(string name={`"ENUM_NAME`", "_enum"}); \
            super.new(name); \
        endfunction \
        ENUM_CLASS_BODY \
    endclass \
    // This object implements the 'null object pattern'. \
    // See https://en.wikipedia.org/wiki/Null_object_pattern \
    class unimplemented_``ENUM_NAME`` extends ``ENUM_NAME``_enum; \
        SCALAR_TYPE value; \
        `uvm_object_utils_begin(unimplemented_``ENUM_NAME``) \
            `uvm_field_int(value, UVM_ALL_ON) \
        `uvm_object_utils_end \
        function new(string name={"unimplemented_", `"ENUM_NAME`"}); \
            super.new(name); \
        endfunction \
        virtual function bit is_valid(); \
            return 0; \
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
    class ENUM_NAME extends uvm_rand_enum#(ENUM_SCALAR_TYPE, ``ENUM_NAME``_enum, ENUM_NAME); \
        `uvm_object_utils(ENUM_NAME) \
        function new(string name=`"ENUM_NAME`"); \
            super.new(name); \
        endfunction \
        ENUM_WRAPPER_BODY \
    endclass
`endif


`ifndef UVM_ENUM_OBJ_VALUE_DECL
`define UVM_ENUM_OBJ_VALUE_DECL(ENUM_TYPE_NAME, ENUM_VALUE_NAME, ENUM_VALUE=get_next_unused_value(), ENUM_CLASS_BODY=) \
    class ENUM_VALUE_NAME extends ``ENUM_TYPE_NAME``_enum; \
        `uvm_object_utils(ENUM_VALUE_NAME) \
        protected static SCALAR_TYPE _value = ENUM_VALUE; \
        protected static int _defined_value_index = _register_enum(.value(ENUM_VALUE),.ow(ENUM_VALUE_NAME::get_type())); \
        static function SCALAR_TYPE value(); \
            return _value; \
        endfunction \
        static function string get_enum_name(); \
            return `"ENUM_VALUE_NAME`"; \
        endfunction \
        static function int defined_value_index(); \
            return _defined_value_index; \
        endfunction \
        static function bit inside_objects(ENUM_ABC set[]); // Capital 'I' because 'inside' is a reserved word` \
            ENUM_ABC q[$] = set.find_first() with (item.get_value() === _value); \
            foreach (q[i]) return 1; \
            return 0; \
        endfunction \
        static function bit inside_values(SCALAR_TYPE set[]); \
            SCALAR_TYPE q[$] = set.find_first() with (item === _value); \
            foreach (q[i]) return 1; \
            return 0; \
        endfunction \
        function new(string name=`"ENUM_VALUE_NAME`"); \
            super.new(name); \
        endfunction \
        virtual function bit is_valid(); \
            return 1; \
        endfunction \
        virtual function SCALAR_TYPE get_value(); \
            return _value; \
        endfunction \
        virtual function int get_enum_index(); \
            return _defined_value_index; \
        endfunction \
        ENUM_CLASS_BODY \
    endclass
`endif


`ifndef UVM_ENUM_OBJ_VALUE_OVERRIDE
`define UVM_ENUM_OBJ_VALUE_OVERRIDE(PARENT_ENUM_VALUE_NAME, CHILD_ENUM_VALUE_NAME, ENUM_CLASS_BODY=) \
    class CHILD_ENUM_VALUE_NAME extends PARENT_ENUM_VALUE_NAME; \
        protected static bit __only_side_effect_needed = _append_name(`"CHILD_ENUM_VALUE_NAME`"); \
        static function string get_enum_name(); \
            return `"CHILD_ENUM_VALUE_NAME`"; \
        endfunction \
        `uvm_object_utils(CHILD_ENUM_VALUE_NAME) \
        function new(string name=`"CHILD_ENUM_VALUE_NAME`"); \
            super.new(name); \
        endfunction \
        ENUM_CLASS_BODY \
    endclass
`endif
