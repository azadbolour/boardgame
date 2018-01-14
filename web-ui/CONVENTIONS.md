
- TODO. Needs update and revision for version 0.5.

- Do not use var. Use let or const.

- Use the so-called _liberal let_ when choosing between const and let.
  Unless there is an overriding reason to use const, use let.

  See https://madhatted.com/2016/1/25/let-it-be.

  Following are good reasons to use const:

  - Use const for values that are conceptually immutable even 
  though const does not mean immutabilty but only non-reassignability.

  - Use const in cases where you wish to _insist_ that the 
  variable not be re-assigned.

  If the value can potentially be re-assigned in a future refactoring, 
  use let.

  If you are neutral about whether the variable can be re-assigned,
  use let.

- OK to use const in block scope as long as it is semantically 
  immutable.

- Use lower case names for both let and const variables.
  Not sure if the de-facto standard of upper case underscore-separated
  variable names for constants is yet adopted by the javascript
  community. Also upper case names are generally used in other languages
  for module level constants. But we allow block-level constants.
  Finally const is used for function definition, for which upper case 
  names would be weird.

  Should a widey adopted naming standard be adopted for Javascript, 
  this convention would of course change.

## Module Pattern

By default we use the module pattern rather than classes for creating
objects. In the module pattern, a factory method creates objects of 
a given type. Variables used in the body of the function are accessible
to the object created but not to users of that object. This is the simplest
way I know of implementing privacy in Javascript. And it easily allows
the use of Javascript's prototypical inheritance.

## Javascript Terminology

- destructuring

- arrow function

## Useful Links

- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference

- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals
