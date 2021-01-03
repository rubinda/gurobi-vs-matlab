#!/usr/bin/env bash
#
# Skripta za prenos in pripravo mape, kamor bomo shranili 'benchmark data'
# Uporablja MIPLIB2017 Benchmark Set, ki je dostopen pod http://miplib.zib.de/index.html
# 
# @author David Rubin

MIPLIB_BENCHMARK_URL='http://miplib.zib.de/downloads/benchmark.zip'
DATA_DIR='benchmark_data'
esc="\x1b"
esc_up="${esc}[1A"
esc_erase="${esc}[K"

# Prenesi .zip ki vsebuje benchmark set
printf "Uporabljam '${MIPLIB_BENCHMARK_URL}'\n"
printf "Prenasam benchmark set ...\n"
curl -L -o benchmark_data.zip $MIPLIB_BENCHMARK_URL
printf "${esc_up}${esc_erase}"
printf "${esc_up}${esc_erase}"
printf "${esc_up}${esc_erase}"
printf "${esc_up}${esc_erase}"
printf "Prenasam benchmark set ... koncano. \n"

# Ustvari mapo in ekstrahiraj v njo
printf "Ekstrahiram v mapo '${DATA_DIR}' ..."
mkdir -p $DATA_DIR
unzip -qo -d $DATA_DIR benchmark_data.zip
printf " koncano. \n"

# Pobrisi .zip file 
printf "Brisem ostanke prenosa ..."
rm benchmark_data.zip
printf " koncano. \n"

printf "Podatki bi se morali nahajati v mapi '${DATA_DIR}'\n"