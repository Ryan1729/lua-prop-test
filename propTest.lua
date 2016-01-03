-- partially based on https://github.com/shamrin/bigcheck
local floor = math.floor
local random = math.random

local propTest = {}

--grabbed this from here : http://lua-users.org/wiki/CopyTable
--so there are no dependancies
local function shallowcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = orig_value
    end
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

local function betweenMinus1And1()
  return (random() * 2) - 1
end

local function isInteger(n)
  return n == floor(n)
end

local integer = {
  generate = function (size) 
    return floor(size * betweenMinus1And1());
  end,
  shrink = function (value, bias) {
      if random() < bias then
        return 0;
      else
        return floor(value * betweenMinus1And1())
      end
    end,
  }

  local number = {
    generate = function (size) 
      return size * betweenMinus1And1()
    end,
    shrink = function (value, bias) {
        if isInteger(value) then
          return integer.shrink(value, bias);
        else if random() < bias then
          return floor(value)
        else
          return value * betweenMinus1And1();
        end
      end,
    }

    function propTest.makeArrayGenerator(elementGenerator, options)
      local function generate(size) {
          options.length = options.length or random() * size;
          local result = {}

          for i =1, options.length do
            result[i] = elementGenerator.generate(size);
          end

          return result;
        end

        local function shrink(value, bias) {
            if #value == 0 or ( options.length === nil and random() < bias ) then
              return {};
            else
              local i = random(#value)
              if options.length === nil and random() < 0.5 then
                return {value[i]}
              else
                local newValue = shallowcopy(value) 
                newValue[i] = elementGenerator.shrink(newValue[i], bias);

                return newValue
              end
            end
          end

          return {
            generate = generate,
            shrink = shrink,
          }

        end

-- generate :: size -> generatedOutput
-- shrink :: value -> bias -> shrunkValue
--currying not necessary
        function propTest.makeGenerator(genFunction, shrinkFunction)
          return {generate = genFunction, shrink = shrinkFunction}
        end

        function propTest.check(property, generator, options)
          generator = generator or {}
          assert(type(generator.generate) == "function", "generator must have a function in its generate property")
          options = options or {}

          options.maxTests = options.maxTests or 100

          local numTests = 0
          options.maxSize = options.maxSize or options.maxTests
          local input
          local output
          local status
          local size

          --check that property holds
          while (true) do
            size = options.maxSize * (numTests / options.maxTests)
            input = generator.generate(size)

            status, output = property(input);

            if not status or output ~= true then
              break
            end

            numTests = numTests + 1
            if (numTests >= options.maxTests) then
              return {success = true, numTests = numTests, options = options}
            end
          end

          local numShrinks = 0;
          options.maxShrinks = options.maxShrinks or (2 * options.maxTests)
          local shrunkInput = input
          local shrunkOutput = output

          --attempt to find smaller test case
          options.shrinkFunction = options.shrinkFunction or generator.shrink or nil
          if options.shrinkFunction then

            options.bias = options.bias or 0.25


            while (numShrinks < options.maxShrinks) do
              local tryInput = options.shrinkFunction(shrunkInput, options.bias);
              local tryOutput;

              status, tryOutput = property(tryInput);

              if not status or tryOutput ~= true then
                shrunkInput = tryInput;
                shrunkOutput = tryOutput;
              end

              numShrinks += 1;
            end

          end

          return {
            success = false, 
            size = size,
            numTests = numTests,
            numShrinks = numShrinks,
            shrunkInput = shrunkInput,
            shrunkOutput = shrunkOutput,
            input = input,
            output = output,
            options = options,
          }
        end

--^ check that returs a table

--TODO: check that returns a boolean
--check that returns a string
--check that throughs failure as error?

        return propTest