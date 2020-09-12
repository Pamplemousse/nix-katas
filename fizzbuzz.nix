{ max }:

let
  /*
  Return `true` if n is a multiple of m, `false` otherwise.
  Use an unefficient "trick" because `nix` does not have function for computing modulus,
  but only integer division.
  Examples:
    7 / 2 * 2 != 7 -> false
    6 / 2 * 2 == 6 -> true
  */
  _divides = n: m:
    if n == 0 then false else n / m * m == n;

  _applyFizzBuzz = n:
    if _divides n 15 then "fizzbuzz" else (
      if _divides n 3 then "fizz" else (
        if _divides n 5 then "buzz" else (builtins.toString n)
      )
    );

  generate = { max, n ? 0 }:
    if n == max then _applyFizzBuzz n
    else
      let
        next_value = generate { inherit max; n = (n + 1); };
      in
        "${_applyFizzBuzz n}, ${next_value}";
in
  # Tests
  assert _applyFizzBuzz 3 == "fizz";
  assert _applyFizzBuzz 6 == "fizz";
  assert _applyFizzBuzz 5 == "buzz";
  assert _applyFizzBuzz 10 == "buzz";
  assert _applyFizzBuzz 15 == "fizzbuzz";
  assert _applyFizzBuzz 30 == "fizzbuzz";

  assert generate { max = 5; } == "0, 1, 2, fizz, 4, buzz";
  assert generate { max = 16; } == "0, 1, 2, fizz, 4, buzz, fizz, 7, 8, fizz, buzz, 11, fizz, 13, 14, fizzbuzz, 16";

  generate { inherit max; }
