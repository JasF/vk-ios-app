//
//  PythonManagerImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PythonManagerImpl.h"
#include "Python.h"
#include <dlfcn.h>

@import SSZipArchive;

@implementation PythonManagerImpl

void ASDisableLogging(); // Look inside
    
- (void)startupPython {
    //ASDisableLogging();
    __block int ret = 0;
    dispatch_queue_t queue = dispatch_queue_create("queue.async.main", DISPATCH_QUEUE_SERIAL);
    __block int argc = 1;
    dispatch_async(queue, ^{
        char *argv[1];
        ret = initializePython(argc, argv);
        exit(ret);
    });
}

int initializePython(int argc, char *argv[]);

void extractResourcesIfNeeded() {
    NSString *documentsDirectory = getDocumentsDirectory();
    NSLog(@"%@", documentsDirectory);
    documentsDirectory = [documentsDirectory stringByAppendingString:@"/Library"];
    
    [[NSFileManager defaultManager] removeItemAtPath:documentsDirectory error:nil];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory isDirectory:nil]) {
        return;
    }
    
    NSError *error = nil;
    NSString *destination = documentsDirectory;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:destination
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error]) {
        NSLog(@"create directory error is: %@", error);
        return;
    }
    
    NSString *packagesDestinationPath = [documentsDirectory stringByAppendingString:@"/sources"];
    [[NSFileManager defaultManager] createDirectoryAtPath:[documentsDirectory stringByAppendingString:@"/tmp"]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    [[NSFileManager defaultManager] createDirectoryAtPath:[documentsDirectory stringByAppendingString:@"/sources/app"]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    [[NSFileManager defaultManager] createDirectoryAtPath:packagesDestinationPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    
    NSString * frameworkZipPath = [[NSBundle mainBundle] pathForResource:@"PythonFramework"
                                                                  ofType:@"zip"];
    
    if (![SSZipArchive unzipFileAtPath:frameworkZipPath toDestination:destination]) {
        NSLog(@"unarchive python failed");
        return;
    }
    NSString *sourcesZipPath = [[NSBundle mainBundle] pathForResource:@"app_packages"
                                                               ofType:@"zip"];
    if (![SSZipArchive unzipFileAtPath:sourcesZipPath toDestination:packagesDestinationPath]) {
        NSLog(@"unarchive sources failed");
        return;
    }
}

int initializePython(int argc, char *argv[]) {
    int ret = 0;
    unsigned int i;
    NSString *tmp_path;
    NSString *python_home;
    NSString *python_path;
    wchar_t *wpython_home;
    const char* main_script;
    wchar_t** python_argv;
    
    @autoreleasepool {
        NSString *pureDocumentsDirectory = getDocumentsDirectory();
        NSString *documentsDirectory = [pureDocumentsDirectory stringByAppendingString:@"/Library"];
        extractResourcesIfNeeded();
        // Special environment to prefer .pyo; also, don't write bytecode
        // because the process will not have write permissions on the device.
        putenv("PYTHONOPTIMIZE=1");
        putenv("PYTHONDONTWRITEBYTECODE=1");
        putenv("PYTHONIOENCODING=utf_8");
        
        // Set the home for the Python interpreter
        python_home = [NSString stringWithFormat:@"%@/Python.framework/Versions/3.6/Resources", documentsDirectory, nil];
        wpython_home = Py_DecodeLocale([python_home UTF8String], NULL);
        Py_SetPythonHome(wpython_home);
        
        // Set the PYTHONPATH
        python_path = [NSString stringWithFormat:@"PYTHONPATH=%@/sources/app:%@/sources/app_packages", documentsDirectory, documentsDirectory, nil];
        putenv((char *)[python_path UTF8String]);
        
        // iOS provides a specific directory for temp files.
        tmp_path = [NSString stringWithFormat:@"TMP=%@/tmp", documentsDirectory, nil];
        putenv((char *)[tmp_path UTF8String]);
        
        NSLog(@"Initializing Python runtime");
        Py_Initialize();
        
        // Set the name of the main script
        main_script = [
                       [[NSBundle mainBundle] pathForResource:@"launcher"
                                                       ofType:@"py"] cStringUsingEncoding:NSUTF8StringEncoding];
        
        if (main_script == NULL) {
            NSLog(@"Unable to locate HelloBee main module file");
            exit(-1);
        }
        
        
        
        
        int addedParamsCount = 1;
        wchar_t *addedParams[1];
        addedParams[0] = Py_DecodeLocale([pureDocumentsDirectory cStringUsingEncoding:NSUTF8StringEncoding], NULL);
        // Construct argv for the interpreter
        python_argv = PyMem_RawMalloc(sizeof(wchar_t*) * (argc + addedParamsCount));
        python_argv[0] = Py_DecodeLocale(main_script, NULL);
        for (i = 1; i < argc; i++) {
            python_argv[i] = Py_DecodeLocale(argv[i], NULL);
        }
        int src=0;
        for (i = argc; i < argc + addedParamsCount; i++) {
            python_argv[i] = addedParams[src];
            ++src;
        }
        
        PySys_SetArgv(argc+addedParamsCount, python_argv);
        
        // If other modules are using threads, we need to initialize them.
        PyEval_InitThreads();
        
        // Start the main.py script
        NSLog(@"Running %s", main_script);
        
        @try {
            FILE* fd = fopen(main_script, "r");
            if (fd == NULL) {
                ret = 1;
                NSLog(@"Unable to open main.py, abort.");
            } else {
                ret = PyRun_SimpleFileEx(fd, main_script, 1);
                if (ret != 0) {
                    NSLog(@"Application quit abnormally!");
                } else {
                    // In a normal iOS application, the following line is what
                    // actually runs the application. It requires that the
                    // Objective-C runtime environment has a class named
                    // "PythonAppDelegate". This project doesn't define
                    // one, because Objective-C bridging isn't something
                    // Python does out of the box. You'll need to use
                    // a library like Rubicon-ObjC [1], Pyobjus [2] or
                    // PyObjC [3] if you want to run an *actual* iOS app.
                    // [1] http://pybee.org/rubicon
                    // [2] http://pyobjus.readthedocs.org/
                    // [3] https://pythonhosted.org/pyobjc/
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Python runtime error: %@", [exception reason]);
        }
        @finally {
            Py_Finalize();
        }
        
        PyMem_RawFree(wpython_home);
        if (python_argv) {
            for (i = 0; i < argc; i++) {
                PyMem_RawFree(python_argv[i]);
            }
            PyMem_RawFree(python_argv);
        }
        NSLog(@"Leaving");
    }
    
    return ret;
}


@end
