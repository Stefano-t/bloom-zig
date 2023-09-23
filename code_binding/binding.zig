const bloom = @import("bloom");
const mem = @import("std").mem;
const log = @import("std").log;

const py = @cImport({
    @cDefine("PY_SSIZE_T_CLEAN", {});
    @cInclude("Python.h");
    @cInclude("structmember.h"); // we need this import because 'PyMemberDef' is an opaque struct inside the Python.h file.
});

const PyMethodDef = py.PyMethodDef;
const PyModuleDef_Base = py.PyModuleDef_Base;
const PyModuleDef = py.PyModuleDef;
const PyObject = py.PyObject;
const PyArg_ParseTuple = py.PyArg_ParseTuple;
const PyLong_FromLong = py.PyLong_FromLong;

// ---------- Define object ----------
const BloomFilter = struct {
    ob_base: PyObject,
    forward: bloom.BloomFilter,
};

// __del__
fn BloomFilter_dealloc(self: [*c]PyObject) callconv(.C) void {
    var obj: *BloomFilter = @ptrCast(self);
    obj.forward.deinit();
    py.Py_TYPE(obj).*.tp_free.?(self);
}

// __init__
fn BloomFilter_init(self: [*c]PyObject, args: [*c]PyObject, _: [*c]PyObject) callconv(.C) c_int {
    var obj: *BloomFilter = @ptrCast(self); // consider also std.zig.c_translate.cast
    var size: c_ulong = undefined;
    var n_hash: c_ulong = undefined;

    if (PyArg_ParseTuple(args, "kk", &size, &n_hash) == 0) return -1;

    var bf = bloom.BloomFilter.init(@as(usize, size), @as(usize, n_hash)) catch unreachable;
    obj.forward = bf;
    return 0;
}

// add
fn BloomFilter_add(self: [*c]PyObject, hash: [*c]PyObject) callconv(.C) [*c]PyObject {
    var c_hash: c_ulonglong = undefined;
    if (PyArg_ParseTuple(hash, "K", &c_hash) == 0) return null;
    var obj: *BloomFilter = @ptrCast(self);
    obj.forward.add(@intCast(c_hash));
    // @NOTE: not sure why, but doing this removes a runtime error where None is deallocated.
    // Refer to this thread for further info: https://stackoverflow.com/questions/15287590/why-should-py-increfpy-none-be-required-before-returning-py-none-in-c/15288194#15288194
    var none: [*c]PyObject = py.Py_None;
    py.Py_INCREF(none);
    return none;
}

// present
fn BloomFilter_present(self: [*c]PyObject, hash: [*c]PyObject) callconv(.C) [*c]PyObject {
    var c_hash: c_ulonglong = undefined;
    if (PyArg_ParseTuple(hash, "K", &c_hash) == 0) return null;
    var obj: *BloomFilter = @ptrCast(self);
    if (obj.forward.present(@intCast(c_hash))) {
        return py.Py_True;
    } else {
        return py.Py_False;
    }
}

// count
fn BloomFilter_count(self: [*c]PyObject, _: [*c]PyObject) callconv(.C) [*c]PyObject {
    var obj: *BloomFilter = @ptrCast(self);
    return py.PyLong_FromUnsignedLongLong(obj.forward.count());
}

// Define members of object
const Custom_members = [_]py.PyMemberDef{
    py.PyMemberDef{
        .name = "forward",
        .type = py.T_OBJECT_EX,
        .offset = @offsetOf(BloomFilter, "forward"),
        .flags = 0,
        .doc = "forwarded object",
    },
    mem.zeroInit(py.PyMemberDef, .{}),
};

// Define members
const BloomFilter_methods = [_]py.PyMethodDef{
    py.PyMethodDef{
        .ml_name = "add",
        .ml_meth = @as(py.PyCFunction, BloomFilter_add),
        .ml_flags = py.METH_VARARGS,
        .ml_doc = "Add hash to the filter",
    },
    py.PyMethodDef{
        .ml_name = "present",
        .ml_meth = @as(py.PyCFunction, BloomFilter_present),
        .ml_flags = py.METH_VARARGS,
        .ml_doc = "Check if hash is present",
    },
    py.PyMethodDef{
        .ml_name = "count",
        .ml_meth = @as(py.PyCFunction, BloomFilter_count),
        .ml_flags = py.METH_NOARGS,
        .ml_doc = "Returns the number of bits set in the filter",
    },
    mem.zeroInit(py.PyMethodDef, .{}),
};

const BloomFilterType = mem.zeroInit(py.PyTypeObject, .{
    .tp_name = "bloom.BloomFilter",
    .tp_doc = py.PyDoc_STR("BloomFilter"),
    .tp_basicsize = @sizeOf(BloomFilter),
    .tp_itemsize = 0,
    .tp_flags = py.Py_TPFLAGS_DEFAULT,
    .tp_new = py.PyType_GenericNew,
    .tp_dealloc = @as(py.destructor, BloomFilter_dealloc),
    .tp_init = @as(py.initproc, BloomFilter_init),
    .tp_members = @constCast(&Custom_members),
    .tp_methods = @constCast(&BloomFilter_methods),
});

// Non cryptographic hashing function
fn fnv_1(_: [*c]PyObject, args: [*c]PyObject) callconv(.C) [*c]PyObject {
    var s: [*:0]u8 = undefined;
    if (PyArg_ParseTuple(args, "s", &s) == 0) return null;
    return py.PyLong_FromUnsignedLongLong(@intCast(bloom.fnv_1(mem.span(s))));
}

const methods = [_]PyMethodDef{
    PyMethodDef{
        .ml_name = "fnv_1",
        .ml_meth = fnv_1,
        .ml_flags = py.METH_VARARGS,
        .ml_doc = "Hash the input string using the FNV 64bit algorithm.",
    },
    mem.zeroInit(PyMethodDef, .{}),
};

const module = PyModuleDef{
    .m_base = PyModuleDef_Base{
        .ob_base = PyObject{
            .ob_refcnt = 1,
            .ob_type = null,
        },
        .m_init = null,
        .m_index = 0,
        .m_copy = null,
    },
    .m_name = "bloom",
    .m_doc = null,
    .m_size = -1,
    .m_methods = @constCast(&methods),
    .m_slots = null,
    .m_traverse = null,
    .m_clear = null,
    .m_free = null,
};

export fn PyInit_bloom() ?*PyObject {
    var m: ?*PyObject = undefined;
    if (py.PyType_Ready(@ptrCast(@constCast(&BloomFilterType))) < 0) return null;
    m = py.PyModule_Create(@as([*c]py.struct_PyModuleDef, @constCast(&module))) orelse return null;

    py.Py_INCREF(&BloomFilterType);
    if (py.PyModule_AddObject(m, "BloomFilter", @ptrCast(@constCast(&BloomFilterType))) < 0) {
        py.Py_DECREF(&BloomFilterType);
        py.Py_DECREF(m);
        return null;
    }
    return m;
}

test {
    const testing = @import("std").testing;
    testing.refAllDeclsRecursive(bloom);
}
