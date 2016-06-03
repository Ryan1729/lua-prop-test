#lua-prop-test

A property-based testing library for lua

Use has been tested with [Busted]([https://github.com/Olivine-Labs/busted](https://github.com/Olivine-Labs/busted)) but using it with another testing framework should not be difficult. 

# Basic Usage

##minimal example

In this example we will test the following function: 

```lua
function square(x)
    return x * x
end
```


```lua

   local propTest = require("propTest")

    --write a function that checks your desired property
    local function squaredNumbersAreNonNegative (x)
    	return square(x) >= 0
    end

   --check the property with a built-in generator
   local result = propTest.check(squaredNumbersAreNonNegative, propTest.nonNegativeInteger)

    --assert that result.success == true using busted and print out the error if it is not
    assert.equals(true, result.success or result)

```

##generator creation

A common use case is generating multiple values so that the function under test can take them as arguments.

```lua

    --make a generator that returns multiple values
    local nonNegativePair = propTest.makeArrayGenerator(propTest.nonNegativeInteger, {length = 2}))

    -- write a function that uses the pair
    local function sumOfTwoNonNegativeNumbersIsNonNegative (value)
       return (value[1] + value[2]) >= 0
    end
    
    --check the property with your pair generator
   local result = propTest.check(squaredNumbersAreNonNegative, propTest.nonNegativeInteger)

    assert.equals(true, result.success or result)
```
You can also make generators that create new types of values, starting from the built-in generators

```lua
    --make a generator
	
	local evenNonNegativeInteger = propTest.makeGenerator(function(size) 
	    local value = propTest.nonNegativeInteger.generate(size)
	    if value % 2 == 0 then
	      return value
	    else
	      return value * 2
	    end
	  end,
	  propTest.nonNegativeInteger.shrink)
	  
  ```
  
  If you want to generate a type of value that is not easily made from combining the built-in generators, (a particular type of string for example,) you can write your own generator function. You will need to provide your own shrinking function in that case. If in doubt or if shrinking doesn't make sense for your type of value you can use the following function: 
  
  ```lua
  
      local function identity (...)
          return ...
      end
  
  ```
  although if you do, (as should be obvious), your values won't be shrunk.
  
#TODO
  
  * Document all built-in generators
  
  * Add string generator
  
  * Document all functions with options reference

  * Give brief definition of property based testing
