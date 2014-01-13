
# Lua 5.1 / LuaJIT Quick Tutorial

[Read about the Lua/LuaJIT language here](about_lua.html).

## Syntax

```lua
-- Two dashes create a comment that ends at the line break
print("hello world")
-- Note: there is no need for semicolons to terminate statements.
```

### Simple types

All values in Lua are one of the following types; however unlike C, the type does not belong to the variable, but to the value itself. That means that a variable can change type (dynamic typing).

```lua
-- Unlike C, the type information is stored with the value, not the variable; 
-- this means that the type of a variable can change dynamically.
x = 1 			-- x now refers to a number
x = "foo" 		-- x now refers to a string

-- check types like this:
if type(x) == "number" then 
	-- do stuff
end
```

#### Numbers

All numbers in Lua are 64-bit floating point type (aka ‘double’ for C programmers). There is no distinction between integers and non-integers. 

```lua
-- these lines are all equivalent
-- they assign the number value 1 to the variable name x:
x = 1
x = 1.0
x = 100e-2  -- e base10 format
x = 0x1 --hexadecimal format
-- Note: all numbers in Lua are 64-bit doubles
```

> The exception is FFI objects, which present any C type to Lua, including number types.


#### Strings

Lua strings are immutable: each string operation creates a new string. 

```lua
-- strings:
print("a simple string")
print('a simple string')

-- embedding special characters and multi-line strings:
x = 'escape the \' character, and write \n a new line'
x = [[
The double square brackets are a simple way to write strings
that span
over several
lines]]
```

> Strings are hashed internally very efficiently, and garbage collected.


#### Booleans and nil

Boolean values are the keywords ```true``` and ```false```. The ```nil``` value indicates the absence of a value, and also counts as false for conditional tests.

```lua
-- Boolean values:
t = true
f = false
if t then print("t!") end -- prints t!
if f then print("f!") end -- prints nothing

-- nil indicates the absence of value. 
-- Assigning nil to a variable marks the variable for garbage collection.
n = nil
-- nil also evaluates to false for a predicate:
if n then print("n!") end -- prints nothing
```

> Assigning ```nil``` to a variable removes a reference to the value; if the value is no longer accessibly referenced by code, it can be garbage collected. Assigning ```nil``` to a table key effectively removes that key from the table.


### Tables (structured data)

Lua provides only one data structure: the *table*. Tables in Lua are associative arrays, mapping **keys** to **values**. Both keys and values can be *any* valid Lua type except nil. However, the implementation makes sure that when used with continuous number keys, the table performs as a fast array. 

```lua
-- creating an array-like table of strings, the quick way:
t = { "one", "two", "three" }

-- creating a dictionary-like table, the quick way:
t = { one = 1, two = 2, three = 3 }

-- creating a table with both array-like and dictionary-like parts:
t = { "one", "two", "three", one = 1, two = 2, three = 3 }

-- create an empty table:
t = {}

-- add or replace key-value pairs in the table:
t[1] = "one"	-- array-like
t["two"] = 2	-- dictionary-like
-- a simpler way of saying that:
t.two = 2

print(t.two, t["two"]) 	--> 2 2

-- special case of nil:
-- remove a key-value pair by assigning the value nil:
t.two = nil
print(t.two)			--> <nil>

-- create a table with a sub-table:
t = {
	numbers = { 1, 2, 3 },
	letters = { "a", "b", "c" },
}

-- any Lua type (except nil) can be used as key or value
-- (including functions, other tables, the table itself, ...)
t[x] = t
t[function() end] = false
t[t] = print
-- and other madness...
```

It’s important to remember that a Lua table has two parts; an array-portion and a hash-table portion. The array portion is indexed with integer keys, starting from 1 upwards. All other keys are stored in the hash (or record) portion.

The **array** portion gives Lua tables the capability to act as ordered lists, and can grow/shrink as needed (similar to C++ vectors). Sometimes the array portion is called the **list** portion, because it is useful for creating lists similarly to LISP. In particular, the table constructor will insert numeric keys in order for any values that are not explicitly keyed:

```lua
-- these two lines are equivalent
local mylist = { [1]="foo", [2]="bar", [3]="baz" }:
local mylist = { "foo", "bar", "baz" }

print(mylist[2]) 			--> bar
		
print(unpack(mylist)) 		--> foo bar baz 
```

*Remember that Lua expects most tables to count from 1, not from 0.*

### Iterating a table

To visit **only** array-portion of a table, use a numeric for loop or ```ipairs```, like the following. The traversal follows the order of the keys, from 1 to the length of the table:

```lua
for i = 1, #mytable do
	local v = mytable[i]
	-- do things with the index (i) and value (v)
	print(i, v)
end

for i, v in ipairs(mytable) do
	-- do things with the index (i) and value (v)
	print(i, v)
end
```

To visit **all** key-value pairs of a table, including the array-portion, use a for loop with ```pairs```. Note that in this case, the order of traversal is undefined; it may be different each time.

```lua
for k, v in pairs(mytable) do
	-- do things with the key (k) and value (v)
	print(k, v)
end
```

### Functions

Functions can be declared in several ways:

```lua
-- these are equivalent:
sayhello = function(message)
  print("hello", message)
end

function sayhello(message)
  print("hello", message)
end

-- using the function:
sayhello("me")  -- prints: hello me
sayhello("you") -- prints: hello you

-- replacing the function
sayhello = function(message)
  print("hi", message)
end

sayhello("me")  -- prints: hi me
```

Functions can zero or more arguments. In Lua, they can also have more than one return value:

```lua
function minmax(a, b)
  return math.min(a, b), math.max(a, b)
end
print(minmax(42, 13)) -- prints: 13 42
```

> In Lua, functions are first-class values, just like numbers, strings and tables. That means that functions can take functions as arguments, functions can return other functions as return values, functions can be keys and values in tables. It also means that functions can be created and garbage collected dynamically.


#### Method-call syntax

A special syntax is available for a table’s member functions that are intended to be used as methods. The use of a colon (```:```) instead of a period (```.```) passes the table itself through as the first implicit argument ```self```. This is called *method-call syntax*:

```lua

-- create a table
local t = { 
	-- with one value being a number:
	num = 10, 
	-- and another value being a function:
	-- (note the use of the keyword "self")
	printvalue = function(self)
  		print(self.num)
	end,
}

-- or declare/modify it like this:
function t:printvalue()
	print(self.num)
end

-- use the method:
t.printvalue(t) -- prints: 10
```

> There's nothing really special here except some fancy syntax for convenience; saying ```t:printvalue()``` is just the same as saying ```t.printvalue(t)```.


### Logic and control flow

```lua
-- if blocks:
if x == 1 then
  print("one")
  -- as many elseifs as desired can be chained
elseif x == 2 then
  print("two")
elseif x == 3 then
  print("three")
else
  print("many")
end

-- while loops:
x = 10
while x > 0 do
  print(x)
  x = x - 1
end

repeat
  print(x)
  x = x + 1
until x == 10

-- numeric for loop:
-- count from 1 to 10
for i = 1, 10 do 
	print(i) 
end		
-- count 1, 3, 5, 7, 9:
for i = 1, 10, 2 do 
	print(i) 
end
-- count down from 10 to 1:
for i = 10, 1, -1 do 
	print(i) 
end

-- logical operators:
if x == y then print("equal") end
if x ~= y then print("not equal") end

-- combinators are "and", "or" and "not":
if x > 12 and not x >= 20 then print("teen") end
```

### Lexical scoping

If a variable is declared ```local```, it exists for any code that follows it, until the ```end``` of that block. (You can tell what a block is by how the code is indented.) Local identifiers are not visible outside the block in which they were declared, but are visible inside sub-blocks. This is called *lexical scoping*.

If a variable is not declared local, it becomes a global variable, belonging to the entire script. **This is a very common cause of bugs**, so it is better to use ```local``` in nearly all cases. (Also, local variables are more efficient).

```lua
function foo(test)
	-- a function body is a new block
	local y = "mylocal"
	if test then
		-- this is a sub-block of the function
		-- so "y" is still visible here
		print(y)  -- prints: mylocal
	end
end

-- this is outside the block in which "local y" occurred,
-- so "y" is not visible here:
print(y)    -- prints: nil
```

Assigning to a variable that has not been declared locally within the current block will search for that name in parent blocks, recursively, up to the top-level. If the name is found, the assignment is made to that variable. But if the name is still not found, Lua creates a new global instead. Mostly this does what you'd expect, so long as you use ```local``` whenever you declare a new variable.

```lua
-- an outer variable:
local x = "outside"
print(x) -- prints: outside

-- sub-block uses "local", which does not affect the variable "x" outside:
function safe()
	local x = "inside"
end
safe()
print(x) -- prints: outside

-- sub-block does not use "local", so this updates the variable "x" outside:
function unsafe()
	x = "inside"
end
unsafe()
print(x) -- prints: inside
```

#### Closures

Closures arise from the mixed use of lexically scoped local variables, and higher order functions. Any function that makes use of non-local variables effectively keeps those variable references alive within it. An example explains this better:

```lua
function make_counter()
	local count = 0
	-- notice that one function returns another
	-- each call to "make_counter()" will allocate and return a newly defined function:
	return function()
		count = count + 1
		print(count)
	end
end

-- call to make_counter() returns a function;
-- and 'captures' the local count as an 'upvalue' specific to it
local c1 = make_counter()
c1()  -- prints: 1
c1()  -- prints: 2
c1()  -- prints: 3

-- another call to make_counter() creates a new function,
-- with a new count upvalue
local c2 = make_counter()
c2()  -- prints: 1
c2()  -- prints: 2

-- the two function's upvalues are independent of each other:
c1()  -- prints: 4
```

#### Garbage collection

Objects are never explicitly deleted in Lua (though sometimes resources such as files might have explicit close() methods). When Lua gets to the end of a block, normally it can release any ```local``` variables created with it. 

However they might still be referenced (e.g. by tables or closures), in which case Lua won't release the memory until those values are no longer accessible. Most of the time we don't even need to think about it.

> Lua uses an fast incremental garbage collector that runs in the background, which silently recycles the memory for any values to which no more references remain. 


## Advanced topics

### Modules

A module is (usually) just a table of functions, stored in a separate file. Modules act like external libraries: re-usable, encapsulated, *modular*. Load modules using ```require```:

```lua
-- load the foo module (foo.lua):
local foo = require "foo"

-- use a module function:
foo.this()
foo.that()
```

To create a module, simply create a Lua script whose last action is to return a table. This table will typically have functions inside. Modules should not create any global variables, only locals. Modules can be placed next to the script, or in any of the locations specified by the ```package.path``` string. The name of the module file should match the module name.

```lua
-- this is the foo module, i.e. foo.lua

-- create the module table
local foo = {}

-- add some functions to the module:
foo.this = function()
	print('this')
end
foo.that = function()
	print('that')
end

-- return the module table
return foo
```

Lua guarantees a given module is only executed once. Additional calls to ```require "foo"``` will always return the same table.

### Coroutines

Coroutines are a form of collaborative multi-tasking. You can think of them as functions that can be paused in mid execution, to be resumed at that position at a later time.

> The C programmer can think of them as similar to threads, however they are explicitly paused and resumed from within a script (rather than by the operating system), and do not make use of CPU multithreading capabilities.

A coroutine is created from an existing function using ```coroutine.create()```, and is resumed using ```coroutine.resume()```. It can pause itself with ```coroutine.yield()```. In addition, values can be passed back and forth via the arguments to ```coroutine.resume()``` and ```coroutine.yield()```.

```lua
local resume, yield = coroutine.resume, coroutine.yield

-- this function will be used to create a coroutine:

local function loop()
	print("hello!")
	local x = 0
	while true do
		-- pause function here:
		yield(x)
		-- continues here:
		x = x + 1
		print(x)
	end
end

-- create the coroutine:
local c = coroutine.create(loop)

-- the first resume runs from the start of the loop() function to the first yield():
coroutine.resume(c) -- prints: hello!

-- each subsequent resume runs from the last paused yield() to the next yield():
coroutine.resume(c) -- prints: 1
coroutine.resume(c) -- prints: 2
```

In LuaAV, coroutines are extended for accurate temporal scheduling, using the ```go```, ```wait``` and ```now``` functions.

### Metatables

Lua does not provide a class-based object-oriented system by default; instead it provides the meta-mechanisms with which many different kinds of object-oriented programming styles can be implemented.

There are several special events that can apply to objects (usually tables and userdata); the default behavior for these events can be overridden by means of a *metatable*. A metatable is just an ordinary table with some reserved key names bound to functions (metamethods) to specify this variant behavior. Any table or userdata can have its metatable set; some objects may share a metatable.

For example, the ```__add``` metamethod defines what happens when two objects are added to each other:

```lua
-- a metatable for pairs
local pair_meta = {}

-- a metamethod function for how to add two pairs together:
pair_meta.__add = function(a, b)
local p = {
  a[1]+b[1],
  a[2]+b[2],
}
-- result is also a pair:
setmetatable(p, pair_meta)
  return p
end

-- a constructor for pairs:
function make_pair(x, y)
  local p = { x, y }
  -- tell p to look in pair_meta for how to handle metamethod events:
  setmetatable(p, pair_meta)
  return p
end

-- create two pairs:
local p1 = make_pair(2, 3)
local p2 = make_pair(4, 5)

-- add them (creates a new pair):
local p3 = p1 + p2
print(p3[1], p3[2]) -- prints: 6 8
```

Arithmetic operator metamethods also exist for **__mul**, **__sub**, **__div**, **__mod**, **__pow**, **__unm** (unary negation).

The **__index** metamethod is important: if a key cannot be found in a given table, it will try again in whichever object the **__index** field points to; or call the function if **__index** points to a function. This is the principal way that inheritence (of both class data and methods) is supported:

```lua
local animal = {}

function animal:isalive() print("yes!") end

local dog = {}
function dog:talk() print("bark!") end

-- create metatable for dog, that refers to animal for unknown keys:
local dog_meta = { __index = animal }

-- apply metatable to dog:
setmetatable(dog, dog_meta)

-- test it:
dog:talk()  -- prints: bark!
dog:isalive() -- prints: yes!

animal:talk() -- error!
```

A corresponding ```__newindex``` metamethod exists to handle assignments of new keys to an object.

Other metamethods include **__tostring** to convert an object to a string (in the **print()** and **tostring()** functions), **__eq, __lt** and **__le** for logical comparisons, **__concat for** the **..** operator, **__len** for the **#** operator, and **__call** for the **()** operator.

By combining all of these metamethods, and smart use metatables, various forms of class based inheritance can be designed. Several examples can be found [here](http://loop.luaforge.net/).



### LuaJIT FFI

The [Foreign-Function Interface (FFI)](http://luajit.org/ext_ffi.html) allows LuaJIT to work with C language data types and functions, and even load and use pre-compiled C libraries. Working with FFI types is usually more difficult (and dangerous!) than plain Lua, but in certain cases it can run a lot faster. To use the ffi, first:

```lua
local ffi = require "ffi"
```

To create a new C-type object ("cdata"), use ```ffi.new()```. For example, to create C-style arrays of 64-bit floating point numbers (C-type *double*):

```lua
-- create an array of five numbers (initialized with zeroes by default):
local arr = ffi.new("double[5]")
local arr = ffi.new("double[?]", 5)

-- create an array of five numbers (initialized with 1, 2, 3, 4, 5):
local arr = ffi.new("double[5]", 1, 2, 3, 4, 5)
local arr = ffi.new("double[?]", 5, 1, 2, 3, 4, 5)
local arr = ffi.new("double[5]", {1, 2, 3, 4, 5})
local arr = ffi.new("double[?]", 5, {1, 2, 3, 4, 5})
```

Arrays can be indexed just as in C. That means *it counts from zero*, unlike Lua tables that count from 1:

```lua
arr[2] = 4.2
print(arr[2]) 	--> prints 4.2
```

The ```ffi.cdef``` function is used to define new aggregate C types (structs):

```lua
-- create declarations of C types in a long string:
local cdefs = [[

	typedef struct { 
		int a;
		double b;
	} foo;

	typedef struct {
		foo first;
		foo second;
	} foopair;

]]
-- add these types the the FFI:
ffi.cdef(cdefs)

-- create a new "foo" type with all members set to zero:
local myfoo = ffi.new("foo")

-- create a new "foo" type with specific values:
local myfoo = ffi.new("foo", { 100, 4.2 })

print(myfoo.a)		 --> prints 100
print(myfoo.b) 		--> prints 4.2

-- create a new "foopair":
local myfoopair = ffi.new("foopair", { { 100, 4.2 }, { 200, 3.14 } })

print(myfoo.second.a) 	--> prints 200
```

The ```ffi.load``` function is used to load a precompiled library of C code. It is usually coupled with a ```ffi.cdef``` to declare the functions and types the library contains:

```lua
-- load the "libsndfile" dynamic library:
local lib = ffi.load("libsndfile-1.dll")

-- declare one of the functions exported by the library
-- (usually we would declare them all at once, but here we just declare one for the example)
ffi.cdef [[
	const char * sf_version_string();
]]

-- use this function by indexing the library:
local version = lib.sf_version_string()

-- version is a cdata of type "const char *"
-- (i.e. an immutable array of bytes)
-- we can turn it into a Lua string using ffi.string:
print(ffi.string(version))
```

Note that the special symbol ```ffi.C``` is a namespace for all the symbols exported by the application itself, including the basic C math library.

> We can get the type of a cdata with ```ffi.typeof```, check it with ```ffi.istype```, get the size of a type with ```ffi.sizeof``` and ```ffi.offsetof```, cast cdata between types (e.g. pointer casts) using ```ffi.cast```, copy or set memory (akin to memcpy and memset) with ```ffi.copy``` and ```ffi.fill```, all basically following the usual rules in C. We can get platform information using ```ffi.os```, ```ffi.arch``` and ```ffi.abi```. We can attach special behavior to a cdata *type* using ```ffi.metatype```, similar to metatables for Lua types. We can add a callback to a cdata *object* when it is garbage collected using ```ffi.gc```. [See the FFI API here](http://luajit.org/ext_ffi_api.html)

With these features, we can interoperate with most C libraries directly from within Lua, without unduly compromising efficiency.


## Help

See the [about Lua](about_lua.html#documentation_and_resources) page for documentation and other resource links. 