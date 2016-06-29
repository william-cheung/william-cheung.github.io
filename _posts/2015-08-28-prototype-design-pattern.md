---
layout: post
title: "Prototype 模式"
categories: oop cpp
---

在某公司使用的框架源代码里看到了 Prototype 模式， 这里把代码提炼总结一下：

```cpp
// ---------------------------------------------------------------------
/** Abstract.h **/

class Abstract { // prototype manager
private:
    typedef map<type_t, Abstract*> RegMap;
    static RegMap& getRegistry() { 
        static RegMap registry; // a static-local  
        return registry;
    }
public:
    Abstract(const type_t& type) {
        if (lookup(type) != NULL)
            getRegistry.insert(type, this);
    }

    virtual ~Abstract() { }

    virtual Abstract* clone() = 0;  

    static Abstract* create(const type_t& type) { 
        Abstract* stub = lookup(type);
        return stub != NULL : stub->clone() : NULL; 
    }

    virtual void destroy() { delete this; }

    static const Abstract* lookup(const type_t& type) {
        if (getRegistry().find(type) != getRegistry().end())
            return getRegistry()[type];
        return NULL;
    }
};

// ---------------------------------------------------------------------
/** ConcreteA.h **/

class ConcreteA : public Abstract {
    // ... data members
    ConcreteA* clone() { return new ConcreteA(*this); }
public:
    ConcreteA() : Abstract(CONC_TYPE_A) { } // CONC_TYPE_A : constant
    // ... other members
};

// ---------------------------------------------------------------------
/** ConcreteA.cpp **/

    static ConcreteA __concrete_a_stub/*(...)*/; // static initialized

// ---------------------------------------------------------------------
/** ConcreteB.h **/

class ConcreteB : public Abstract {
    // ... data members
    ConcreteB* clone() { return new ConcreteB(*this); }
public:
    ConcreteB() : Abstract(CONC_TYPE_B) { } // CONC_TYPE_B : constant
    // ... other members
};

// ---------------------------------------------------------------------
/** ConcreteB.cpp **/

    static ConcreteB __concrete_b_stub/*(...)*/; 

// ---------------------------------------------------------------------
/** Client **/

Abstract* p_abstract = Abstract::create(CONC_TYPE_A /* or CONC_TYPE_B */);
// ... some code
p_abstract->destroy();

// ---------------------------------------------------------------------
```

### 使用 Prototype 模式的好处 :

1. 对客户端隐藏具体的产品类 (product classes)，这样就能够减少客户端可见的类的数目，降低系统的复杂性；

2. 很容易添加或者类的原型；

3. 可以动态配置一个应用所能使用的类。在上面代码中，所有的原型是在 main 函数执行之前注册到 prototype manager 持有的注册表中的（静态初始化过程）。 实际上， 注册表项的加载可以推迟到 main 函数执行后， 即动态地加载到注册表中。

4. 简化了继承体系结构；利用下面摘自 GoF Design Patterns 的代码来说明这一点 

```cpp
class MazePrototypeFactory : public MazeFactory {
public: 
	MazePrototypeFactory(Maze*, Wall*, Room*, Door*);

 	virtual Maze* MakeMaze() const;
	virtual Room* MakeRoom(int) const;
	virtual Wall* MakeWall() const;
	virtual Door* MakeDoor(Room*, Room*) const;

private:
	Maze* _prototypeMaze;
	Room* _prototypeRoom;
	Wall* _prototypeWall;
	Door* _prototypeDoor;
};


MazePrototypeFactory::MazePrototypeFactory (
	Maze* m, Wall* w, Room* r, Door* d
) {
	_prototypeMaze = m;
	_prototypeWall = w;
	_prototypeRoom = r;
	_prototypeDoor = d;
}
```

MakeWall 和 MakeDoor 的定义:

```cpp
Wall* MazePrototypeFactory::MakeWall () const {
	return _prototypeWall->Clone();
}

Door* MazePrototypeFactory::MakeDoor (Room* r1, Room *r2) const {
	Door* door = _prototypeDoor->Clone();
	door->Initialize(r1, r2);
	return door;
}
```
我们可以看到这两个方法只是获得原型的拷贝并返回

```cpp
MazeGame game;

MazePrototypeFactory simpleMazeFactory(
	new Maze, new Wall, new Room, new Door
);

Maze* maze = game.CreateMaze(simpleMazeFactory);
```

这里创建了一个默认的 MazeFactory。


我们可以使用另一组原型来初始化 MazePrototypeFactory，以获得新的 Maze 类型。

```cpp 
MazePrototypeFactory bombedMazeFactory(
	new Maze, new BombedWall,
	new RoomWithABomb, new Door
);
```

我们只需要 BombedWall 和 RoomWithABomb 分别继承 Wall 和 Room 并实现相应接口 (如 Clone() 等)。这样就不用继承 MazeFactory 就可以获得定制的 Maze， 以优雅的方式实现了所需要的功能。

