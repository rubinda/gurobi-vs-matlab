#!/usr/bin/env bash
#
# Izvede testiranje nad izbranimi primeri iz MIPLIB2017 benchmark zbirke
#
# @author David Rubin
usage="usage: $(basename "$0") [-h] [-p <problem_file>] <data_source> <log_dir>

Skripta, ki shrani podatke resevanja MPS problemov s pomocjo Gurobi. Namenjena performancnenu
testiranju pri porocilu primerjave MATLAB z Gurobi.

where:
    -h                  pokazi ta help text
    -p <problem_file>   datoteka z imeni MPS problemov (default 'mps-problems.txt')
    <data_source>       mapa, kjer se nahajajo MPS problemi
    <log_dir>           mapa, kamor se shranijo podatki o zagonih 
"
mps_files='mps-problems.txt'
# Uproabi izpis pomoci in parametrov
# hvala @glenn_jackaman, https://stackoverflow.com/a/5476278
while getopts ':hp:' option; do
    case "$option" in
        h)  echo "$usage"
            exit
            ;;
        p)  mps_files=$OPTARG
            ;;
        :)  printf "Napaka: manjkajoc podatek za -%s! Uporaba:\n\n" "$OPTARG" >&2
            echo "$usage" >&2
            exit 1
            ;;
        \?) printf "Napaka: neveljavna opcija: -%s!\n\n" "$OPTARG" >&2
            echo "$usage" >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

[ "$#" -eq 2 ] || printf "Napaka: manjkajoci parametri!\n\n$usage"; exit 1



