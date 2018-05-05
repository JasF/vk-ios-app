//
//  PythonBridgeExtensionImpl.m
//  vk
//
//  Created by Jasf on 05.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PythonBridgeExtensionImpl.h"
#import "Python.h"

@interface PythonBridgeExtensionImpl () <PythonManagerExtension, PythonBridgeExtension>
@property (nonatomic) id<PythonBridge> pythonBridge;
- (NSDictionary *)incomingDictionary:(NSDictionary *)dictionary;
@end

struct module_state {
    PyObject *error;
};

static PythonBridgeExtensionImpl *g_extension = nil;


#define GETSTATE(m) ((struct module_state*)PyModule_GetState(m))

static PyObject *
error_out(PyObject *m) {
    struct module_state *st = GETSTATE(m);
    PyErr_SetString(st->error, "om");
    return NULL;
}
char * hello(char * what);
static PyObject * post_wrapper(PyObject * self, PyObject * args)
{
    char * input;
    char * result;
    PyObject * ret;
    
    // parse arguments
    if (!PyArg_ParseTuple(args, "s", &input)) {
        return NULL;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:input length:strlen(input)]
                                                         options:0 error:nil];
    NSDictionary *response = [g_extension incomingDictionary:dict];
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
    // run the actual function
    //result = hello(input);
    
    // build the resulting string into a Python object.
    ret = PyUnicode_FromStringAndSize(responseData.bytes, responseData.length);
    
    return ret;
}

static PyMethodDef pythonbridgeextension_methods[] = {
    {"error_out", (PyCFunction)error_out, METH_NOARGS, NULL},
    { "post", post_wrapper, METH_VARARGS, "s" },
    {NULL, NULL}
};

static int pythonbridgeextension_traverse(PyObject *m, visitproc visit, void *arg) {
    Py_VISIT(GETSTATE(m)->error);
    return 0;
}

static int pythonbridgeextension_clear(PyObject *m) {
    Py_CLEAR(GETSTATE(m)->error);
    return 0;
}


static struct PyModuleDef moduledef = {
    PyModuleDef_HEAD_INIT,
    "pythonbridgeextension",
    NULL,
    sizeof(struct module_state),
    pythonbridgeextension_methods,
    NULL,
    pythonbridgeextension_traverse,
    pythonbridgeextension_clear,
    NULL
};

#define INITERROR return NULL

PyMODINIT_FUNC PyInit_pythonbridgeextension(void);
PyMODINIT_FUNC
PyInit_pythonbridgeextension(void)
{
    PyObject *module = PyModule_Create(&moduledef);
    
    if (module == NULL)
        INITERROR;
    struct module_state *st = GETSTATE(module);
    
    st->error = PyErr_NewException("pythonbridgeextension.Error", NULL, NULL);
    if (st->error == NULL) {
        Py_DECREF(module);
        INITERROR;
    }
    
    return module;
}




@implementation PythonBridgeExtensionImpl {
    PyObject* _objcbridgeModule;
    PyObject* _handleincomingdataFunction;
}

- (id)initWithPythonBridge:(id<PythonBridge>)pythonBridge {
    if (self = [super init]) {
        _pythonBridge = pythonBridge;
        _pythonBridge.bridgeExtension = self;
        g_extension = self;
    }
    return self;
}

#pragma mark - PythonManagerExtension
- (void)initializeSystem {
    PyImport_AppendInittab("pythonbridgeextension", PyInit_pythonbridgeextension);
}

- (void)initializeUser {
}

#pragma mark - Private Methods
- (NSDictionary *)incomingDictionary:(NSDictionary *)dictionary {
    return [_pythonBridge incomingDictionary:dictionary];
}

#pragma mark - PythonBridgeExtension
- (NSDictionary *)sendToPython:(NSDictionary *)object {
    // здесь нужно спускаться на уровень до main.py, в том же потоке, в котором крутится главный питон.
    _objcbridgeModule = PyImport_Import(PyUnicode_FromString("objcbridge"));
    _handleincomingdataFunction = PyObject_GetAttrString(_objcbridgeModule,"handleincomingdata");
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    PyObject *stringData = PyUnicode_FromStringAndSize(data.bytes, data.length);
    PyObject *args = PyTuple_Pack(1,stringData);
    PyObject *argsZero = PyTuple_Pack(0);
    PyObject* resultString = PyObject_CallObject(_handleincomingdataFunction, argsZero);
    Py_ssize_t size=0;
    Py_DECREF(args);
    Py_DECREF(resultString);
    char *utf8string = _PyUnicode_AsStringAndSize(resultString, &size);
    NSData *resultData = [NSData dataWithBytes:(const void *)utf8string length:size];
    NSDictionary *resultObject = [NSJSONSerialization JSONObjectWithData:resultData
                                                                 options:0
                                                                   error:nil];
    return resultObject;
}

@end
