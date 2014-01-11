# Lua 5.1 / LuaJIT Quick Tutorial

Commonly compared to: JavaScript, Ruby, Python, Scheme. Notable characteristics:

- Fast (used widely for game engines). [LuaJIT](www.luajit.org) can approach and sometimes exceed C. 
- Clean & powerful array/dictionary data structure (table)
- Proper lexical scoping
- First-class functions
- Coroutines 
- Garbage collected
- Prototype inheritance (similar to [Self](http://en.wikipedia.org/wiki/Self_(programming_language))
- Small, portable & easy to embed with C
- [MIT license](http://www.opensource.org/licenses/mit-license.php)

## Syntax

```lua
-- Two dashes create a comment that ends at the line break
print("hello world")
-- Note: no need for semicolons to terminate statements.
```


### Simple types

```lua
-- Unlike C, the type information is stored with the value, not the variable; 
-- this means that the type of a variable can change dynamically.
x = 1 			-- x now refers to a number
x = "foo" 		-- x now refers to a string

-- check types like this:
if type(x) == "number" then 
	-- do stuff
end

-- these lines are all equivalent
-- they assign the number value 1 to the variable name x:
x = 1
x = 1.0
x = 100e-2  -- e base10 format
x = 0x1 --hexadecimal format
-- Note: all numbers in Lua are 64-bit doubles

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

### Structured data

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
```

It’s important to remember that a Lua table has two parts; an array-portion and a hash-table portion. The array portion is indexed with integer keys, starting from 1 upwards. All other keys are stored in the hash (or record) portion.

The array portion gives Lua tables the capability to act as ordered lists, and can grow/shrink as needed (similar to C++ vectors). Sometimes the array portion is called the list portion, because it is useful for creating lists similarly to LISP. In particular, the table constructor will insert numeric keys in order for any values that are not explicitly keyed:

```lua
-- these two lines are equivalent
local mylist = { [1]="foo", [2]="bar", [3]="baz" }:
local mylist = { "foo", "bar", "baz" }

print(mylist[2]) 			--> bar
		
print(unpack(mylist)) 		--> foo bar baz 
```

Remember that Lua expects most tables to count from 1, not from 0.

### Iterating a table

To visit **all** key-value pairs of a table, use a for loop like the following. Note that the order of traversal is undefined; it may be different each time.

```lua
for key, value in pairs(mytable) do
	-- do things with the key and value
end
```

To visit **only** array-portion of a table, use one of these forms:

```lua
for i = 1, #mytable do
	local value = mytable[i]
	-- do things with the key and value
end

for key, value in ipairs(mytable) do
	-- do things with the key and value
end
```

### Functions

Unlike C, functions are first-class values, just like numbers, strings and tables. That means that functions can take functions as arguments, functions can return other functions as return values, functions can be keys and values in tables. It also means that functions can be created and garbage collected dynamically.

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

Functions can zero or more arguments. In Lua, they can also have more than one return vaue:

```lua
function minmax(a, b)
  return math.min(a, b), math.max(a, b)
end
print(minmax(42, 13)) -- prints: 13 42
```

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
if x > 0 and x < 1 then print("between 0 and 1") end
```

### Lexical scoping

If a variable is declared `local`, it exists for any code that follows it, until the `end` of that block. If a variable is not declared local, it becomes a global variable, belonging to the entire script. Use local variables as much as possible, as they are faster, and reduce bugs.

```lua
function foo(x)
  -- a function body is a new block
  local y = "mylocal"
  if x == y then
    -- this is a sub-block of the function
    -- y is still visible here
    print(y)  -- prints: mylocal
  end
end
-- y is not visible here:
print(y)    -- prints: nil
```

Assigning to a variable that has not been declared locally within the current block will search for that name in parent blocks, recursively, up to the top-level. If the name is found, the assignment is made to that variable. If the name is not found, the assignment becomes a global (either creating a new variable, or replacing an existing global). 

```lua
-- an outer variable:
local x = "outside"
print(x) -- prints: outside

-- sub-block uses a local, which does not affect the outer variable:
function safe()
  local x = "inside"
end
safe()
print(x) -- prints: outside

-- sub-block does not use a local, and overwrites the outer variable:
function unsafe()
  x = "inside"
end
unsafe()
print(x) -- prints: inside
```

### Method syntax

Objects in Lua that have functions as members can invoke these functions using a special colon syntax:

```lua
-- create an object:
myobject = { value = 10 }

-- add a function:
myobject.printvalue = function(self)
	print(self.value)
end

-- test it:
myobject.printvalue(myobject)	--> 10

-- use the colon syntax instead passes the 'self' argument implicitly:
function myobject:printvalue()
	print(self.value)
end

myobject:printvalue()			--> 10
```

### Closures

Closures arise from the mixed use of lexically scoped local variables, and higher order functions. Any function that makes use of non-local variables effectively keeps those variable references alive within it. An example explains this better:

```lua
function make_counter()
  local count = 0
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

## Modules

A module is (usually) just a table of functions, stored in a separate file. Modules act like external libraries: re-usable, encapsulated, *modular*. Load modules using *require*:

```
-- load the foo module (foo.lua):
local foo = require "foo"

-- use a module function:
foo.this()
foo.that()
```

To create a module, simply create a Lua script whose last action is to return a table. This table will typically have functions inside. Modules should not create any global variables, only locals. Modules can be placed next to the script, or in any of the locations specified by the *package.path* string. The name of the module file should match the module name.

```
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

Lua guarantees a given module is only executed once. Additional calls to *require "foo"* will always return the same table.

## LuaJIT FFI

The [Foreign-Function Interface (FFI)](http://luajit.org/ext_ffi.html) allows LuaJIT to work with C language data types and functions, and even load and use pre-compiled C libraries. Working with FFI types is usually more difficult (and dangerous!) than plain Lua, but in certain cases it can run a lot faster. To use the ffi, first:

```
local ffi = require "ffi"
```

To create a new C-type object ("cdata"), use **ffi.new()**. For example, to create C-style arrays of 64-bit floating point numbers (C-type *double*):

```
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

```
arr[2] = 4.2
print(arr[2]) 	--> prints 4.2
```

The **ffi.cdef** function is used to define new aggregate C types (structs):

```
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

The **ffi.load** function is used to load a precompiled library of C code. It is usually coupled with a **ffi.cdef** to declare the functions and types the library contains:

```
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

Note that the special symbol **ffi.C** is a namespace for all the symbols exported by the application itself, including the basic C math library.

We can get the type of a cdata with **ffi.typeof**, check it with **ffi.istype**, get the size of a type with **ffi.sizeof** and **ffi.offsetof**, cast cdata between types (e.g. pointer casts) using **ffi.cast**, copy or set memory (akin to memcpy and memset) with **ffi.copy** and **ffi.fill**, all basically following the usual rules in C. We can get platform information using **ffi.os**, **ffi.arch** and **ffi.abi**. We can attach special behavior to a cdata *type* using **ffi.metatype**, similar to metatables for Lua types. We can add a callback to a cdata *object* when it is garbage collected using **ffi.gc**. [See the FFI API here](http://luajit.org/ext_ffi_api.html)

With these features, we can interoperate with most C libraries directly from within Lua, without unduly compromising efficiency.


## Help

[Reference manual](http://www.lua.org/manual/5.1); bookmark the [contents](http://www.lua.org/manual/5.1/index.html#index).

*Excellent* text-book: [Programming in Lua (second edition)](http://www.lua.org/docs.html#books)
![PIL](http://www.lua.org/images/pil2.jpg)