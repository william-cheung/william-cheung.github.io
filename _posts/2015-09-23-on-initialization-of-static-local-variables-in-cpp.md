---
layout: post
title: "关于 C++ 中局部静态变量初始化"
categories: cpp
---

函数内部的静态局部变量的初始化是在函数第一次调用时执行；在之后的调用中不会对其初始化，保留上次退出函数时的值。 在多线程环境下，编译器能够保证静态局部变量被安全地初始化。下面通过代码来分析初始化过程中的一些具体细节：

```c
void foo() {
    static Bar bar;
    // ...
}
```

通过观察 g++ 4.8.3 为上述代码生成的汇编代码， 我们可以看到编译器生成了具有如下语义的代码：

```c
void foo() {
    if ((guard_for_bar & 0xff) == 0) {
        if (__cxa_guard_acquire(&guard_for_bar)) {
            try {
                Bar::Bar(&bar);
            } catch (...) {
                __cxa_guard_abort(&guard_for_bar);
                throw;
            }
            __cxa_guard_release(&guard_for_bar);
            __cxa_atexit(Bar::~Bar, &bar, &__dso_handle);
        }
    }
    // ...
}
``` 

虽然 bar 是局部变量， 但是编译器在处理上与全局静态变量类似， 均存储在 bss 段 (section)，只是 bar 在汇编语言层面上的符号名称是对 foo()::bar 的编码，具体细节这里不做过多讨论。 guard\_for\_bar 是一个用来保证线程安全和一次性初始化的整型变量，是编译器生成的，存储在 bss 段。它的最低的一个字节被用作相应静态变量是否已被初始化的标志， 若为 0 表示还未被初始化，否则表示已被初始化。\_\_cxa\_guard\_acquire 实际上是一个加锁的过程， 相应的 \_\_cxa\_guard\_abort 和 \_\_cxa\_guard\_release 释放锁。\_\_cxa\_atexit 注册在调用 exit 时或动态链接库(或共享库) 被卸载时执行的函数， 这里注册的是 Bar 的析构函数。

值得一提的是\_\_cxa\_atexit 可被用来实现atexit， atexit(func) 等价于 \_\_cxa\_atexit(func, NULL, NULL) 
\_\_cxa\_atexit 函数原型：  

```c
int __cxa_atexit(void (*func) (void *), void * arg, void * dso_handle))
```

下面列出 \_\_cxa\_guard\_acquire、 \_\_cxa\_guard\_abort 和 \_\_cxa\_guard\_release 这三个二进制标准接口(Itanium C++ ABI) 的一种具体实现的[源代码](http://www.opensource.apple.com/source/libcppabi/libcppabi-14/src/cxa_guard.cxx):

```c
// 我们省略头文件引用

// 这里不使用函数局部静态变量可以避免使用cxa 函数
static pthread_mutex_t __guard_mutex;
static pthread_once_t __once_control = PTHREAD_ONCE_INIT;

// 将 __guard_mutex 初始化为递归锁
static void makeRecusiveMutex()
{
    pthread_mutexattr_t recursiveMutexAttr;
    pthread_mutexattr_init(&recursiveMutexAttr);
    pthread_mutexattr_settype(&recursiveMutexAttr, 
	                          PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&__guard_mutex, &recursiveMutexAttr);
}

// 保证 __guard_mutex 只被初始化一次
__attribute__((noinline))
static pthread_mutex_t* guard_mutex()
{
    pthread_once(&__once_control, &makeRecusiveMutex);
    return &__guard_mutex;
}

// 判断静态局部变量是否已被初始化
static bool initializerHasRun(uint64_t* guard_object)
{
    return ( *((uint8_t*)guard_object) != 0 );
}

// 标记静态局部变量已被初始化
static void setInitializerHasRun(uint64_t* guard_object)
{
    *((uint8_t*)guard_object)  = 1;
}

// 判断 guard_object 是否已被某个线程所使用
static bool inUse(uint64_t* guard_object)
{
    // 取次低字节作为 guard_object 是否正在被某线程使用的标志
    return ( ((uint8_t*)guard_object)[1] != 0 );
}

// 标记 guard_object 为正在被使用
static void setInUse(uint64_t* guard_object)
{
    ((uint8_t*)guard_object)[1] = 1;
}

// 释放 guard_object
static void setNotInUse(uint64_t* guard_object)
{
    ((uint8_t*)guard_object)[1] = 0;
}

// 
// 若返回1 说明静态局部对象需要被初始化
// 若返回0 则说明初始化正在进行或已完成
// 若有其他线程正在执行初始化，该函数会阻塞
//
int __cxxabiv1::__cxa_guard_acquire(uint64_t* guard_object)
{
    // 再次检测是否已开始初始化或初始化已完成
    if ( initializerHasRun(guard_object) ) // 如果对象已被初始化
        return 0;

    // 现在获取锁来保证只有一个线程执行初始化
    // 如果有其他线程调用 __cxa_guard_acquire()，它将会被阻塞直
    // 到当前线程完成初始化并调用 __cxa_guard_release()

    // 如果同一个线程在调用 __cxa_guard_release() 或 
    // __cxa_guard_abort() 之前用同一个guard_object 再次调用 
    // __cxa_guard_acquire() 我们终止程序执行 (abort)
	
    // 在这一实现中，所有静态局部对象的初始化使用同一个锁，所以同
    // 时只有一个对象被初始化  

    int result = ::pthread_mutex_lock(guard_mutex());
    if ( result != 0 ) {
        abort_message("__cxa_guard_acquire(): pthread_mutex_lock "
                      "failed with %d\n", result);
    }

    // 至此，所有尝试调用 __cxa_guard_acquire() 的线程都将被阻塞
    
    // 判断对象是否已经被其他线程初始化
    if ( initializerHasRun(guard_object) ) { 
        int result = ::pthread_mutex_unlock(guard_mutex());
        if ( result != 0 ) {
            abort_message("__cxa_guard_acquire(): pthread_mutex_unlock "
                          "failed with %d\n", result);
        }
        return 0;
    }
    
    // 将这个锁设置为recursive 是为了在当前局部对象被初始化时，
    // 其他对象也可以被初始化(这里尚不知道在什么条件下会出现这
    // 种情形)
    // 但如果在同一个guard_object 再次调用 __cxa_guard_acquire，
    // 我们调用abort() 终止程序执行
    if ( inUse(guard_object) ) { // 防止同一线程对对象多次初始化
        abort_message("__cxa_guard_acquire(): initializer for function "
                      "local static variable called enclosing function\n");
    }
    
    // 将guard_object 标记为正在使用
    setInUse(guard_object);

    return 1;
}


//
// 标记局部静态对象已被初始，并释放锁
//
void __cxxabiv1::__cxa_guard_release(uint64_t* guard_object)
{
    setInitializerHasRun(guard_object);

    int result = ::pthread_mutex_unlock(guard_mutex());
    if ( result != 0 ) {
        abort_message("__cxa_guard_acquire(): pthread_mutex_unlock "
                      "failed with %d\n", result);
    }
}



//
// 出现异常，释放锁
// 
void __cxxabiv1::__cxa_guard_abort(uint64_t* guard_object){
    int result = ::pthread_mutex_unlock(guard_mutex());
    if ( result != 0 ) {
        abort_message("__cxa_guard_abort(): pthread_mutex_unlock "
                      "failed with %d\n", result);
    }
    // 允许静态局部对象再次被初始化
    setNotInUse(guard_object);
}
```

最后提供一个很有价值的参考： [http://wiki.osdev.org/C%2B%2B](http://wiki.osdev.org/C%2B%2B)
