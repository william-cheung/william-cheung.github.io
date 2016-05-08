---
layout: post
title: "offsetof 和 container_of"
categories: c code 
---

offsetof 和 container_of 是两个常见的与结构或类相关的宏， 其定义有一定的技巧性，这里总结一下. 

## 1. offsetof

offsetof 是定义在头文件 stddef.h (cstddef in C++) 中的一个宏， 用于计算结构体(struct)或联合体(union) 成员的地址偏移.

一种常见的存在移植问题的实现(GCC 标准库实现):

```c
#define offsetof(type, member) ((size_t)(&((type *)0)->member))
```

这一实现的原理是如果一个对象的地址为0的话，那么它的数据成员的地址就是数据成员在该对象的内存布局中相对于对象地址的偏移值. 虽然这一实现在许多编译器上可以通过编译，但更据 C 标准或 C++ 标准，对 NULL 指针解引用 (dereference) 属于未定义行为. 一些编译器会对这个宏定义给出警告. 我的 gcc 4.8.3 就给出如下警告：

```c
invalid access to non-static data member ... of NULL object
(perhaps the `offsetof' macro was used incorrectly)
```

一种可行的消除警告的方法是利用 1 作为对象地址， 而不是 0. 宏定义如下:

```c
#define offsetof(type, member) ((size_t)((char*)(&((type*)1)->member) - 1))
```

一些现代编译器内建offsetof功能， 在定义 offsetof 时使用如下形式:

```c
#define offsetof(type, member) __builtin_offsetof(type, member)
```

在 C 中 offsetof 可应用于 struct 或 union.
在 C++ 中， 可以将 offsetof 应用于 class， 但是标准对其给出了一些限制, 可参考：  
[http://en.cppreference.com/w/cpp/types/offsetof](http://en.cppreference.com/w/cpp/types/offsetof)  
[http://en.cppreference.com/w/cpp/language/data_members#Standard_layout](http://en.cppreference.com/w/cpp/language/data_members#Standard_layout)


下面是一段 C++ 示例代码：

```c
#include <iostream>
#include <cstddef>
using namespace std;

//#define offsetof(type, member) ((size_t)((char*)(&((type*)1)->member) - 1))

struct Base {
    int     _m1;
    double  _m2;
private:
    char    _m3;
};

struct Derived : public Base {
    int     _m4;
    virtual void vfunc() {}
};

int main() {
    // we are using standard offsetof
    // the behaviors below is undefined because Base and Derived are not
    // standard layout types according to the C++ standard
    cout << offsetof(Base, _m1) << endl; 
    cout << offsetof(Base, _m2) << endl;
    // cout << offsetof(Base, _m3) << endl;
    // error : char Base::_m3 is private
    cout << offsetof(Derived, _m2) << endl;
    cout << offsetof(Derived, _m4) << endl;
    return 0;
}
```

利用 g++ 编译时， 可使用 -Winvalid-offsetof 选项来关闭“访问 NULL 对象的非静态成员”等警告. 在 64 位机器上
编译执行， 输出为：

```sh
0
8
16
28
``` 

## 2. container_of

container_of 的定义见于 Linux 内核源码（C语言）kernel.h  它的功能是利用成员(或字段)的地址计算出包含它的结构对象的地址.

```c
#define container_of(ptr, type, member) ({ \
                const typeof( ((type *)0)->member ) *__mptr = (ptr); \
                (type *)( (char *)__mptr - offsetof(type,member) );})
```

首先将 ptr 赋值给 \_\_mptr, 不太清楚这里为什么要声明\_\_mptr 而不是利用 ptr 直接运算. typeof 是 GNU C 扩展，用于获取变量的类型。\_\_mptr 的值减去地址偏移就是对象的地址.

下面是 container_of 的使用示例:

```c
struct my_struct {
    const char *name;
    struct list_node list;
};

extern struct list_node * list_next(struct list_node *);

struct list_node *current = /* ... */
while(current != NULL){
    struct my_struct *element = container_of(current, struct my_struct, list);
    printf("%s\n", element->name);
    current = list_next(&element->list);
}
```
