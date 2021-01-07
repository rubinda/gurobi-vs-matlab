## Rezultati zagonov

V tej mapi se nahajajo rezultati testiranja: časi potrebni za rešitev problema.
Strukturirani so kot `.csv` datoteke, ki imajo sledeče stolpce
```
mps  ...  ime problema (oz. datoteke v kateri se nahaja)
run  ...  zaporedna stevilka zagona
time ...  pretekli cas resevanja zaokrozen na 4 decimalna mesta
fail ...  ali je bil presezen nastavljen timeout (0/1)
threads ... koliko niti je bilo uporabljenih (Gurobi only, MATLAB je vedno 1)
```
