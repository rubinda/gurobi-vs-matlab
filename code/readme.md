## Izvorna koda

V tej mapi se nahaja izvorna koda, ki je bila uporabljena pri izdelavi [poročila](../solver-compare.pdf) v tem repozitoriju.

+ [`bench_gurobi.m`](bench_gurobi.m)
    >MATLAB skripta, ki opravi celoten proces spodaj omenjenih preostalih skript (prenese podatke, opravi testiranje nad `MATLAB` in `gurobi_cl`)
+ [`bench_gurobi.sh`](bench_gurobi.sh)
    >Skripta, ki generira rezultate za performanso `gurobi_cl` (deprecated, glej [`bench_gurobi.m`](bench_gurobi.m))
+ [`bench_matlab.m`](bench_matlab.m)
    >Koda, ki generira rezultate za performanso `intlinprog` (deprecated, glej [`bench_gurobi.m`](bench_gurobi.m))
+ [`coins.lp`](coins.lp)
    >Primer problema formatiranega v LP datoteko
+ [`coins.sol`](coins.sol)
    >Primer datoteke z rezultati ob uporabi `gurobi_cl`
+ [`gurobi_demo_file.m`](gurobi_demo_file.m)
    >MATLAB primer uporabe Gurobi z MPS/LP datoteko
+ [`gurobi_demo.lp`](gurobi_demo.lp)
    >MATLAB rezultat shranjevanja modela v LP datoteko
+ [`gurobi_demo.m`](gurobi_demo.m)
    >MATLAB primer uporabe Gurobi z matrikami/vektorji
+ [`Gurobi-demo.ipynb`](Gurobi-demo.ipynb)
    >Python primer uporabe Gurobi (Jupyter notebook)
+ [`mps-problmes.txt`](mps-problmes.txt)
    >Imena MIP problemov iz MIPLIB2017 zbirke
+ [`prepare_data.sh`](prepare_data.sh)
    >Skripta, ki prenese in ekstrahira MIPLIB2017 zbirko (deprecated, glej [`bench_gurobi.m`](bench_gurobi.m))