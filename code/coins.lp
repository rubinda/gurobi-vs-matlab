\ Priloga k 'Primerjava resevanja ILP v Matlab in Gurobi'
\ Prirejeno po Gurobi Quickstart: uporaba vseh 6 kovancev in bolj natancnih vrednosti
\ @author David Rubin
\ @date   2020
Maximize
  .01 Pennies + .05 Nickels + .1 Dimes + .25 Quarters + .5 Halves + 1 Dollars
Subject To
  Copper: .0625 Pennies + 3.75 Nickels + 2.0791 Dimes + 5.1977 Quarters + 10.3954 Halves + 7.1685 Dollars - Cu = 0
  Nickel: 1.25 Nickels + .1889 Dimes + .4723 Quarters + .9446 Halves + .162 Dollars - Ni = 0
  Zinc: 2.4375 Pennies + .486 Dollars - Zn = 0
  Manganese: .2835 Dollars - Mn = 0
Bounds
  Cu <= 1000
  Ni <= 50
  Zn <= 50
  Mn <= 50
Integers
  Pennies Nickels Dimes Quarters Halves Dollars
End
