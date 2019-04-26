#!/bin/bash

path="$1"
DIR="$( cd "$(dirname "$0")" ; pwd -P )"
dtset="$2"
#echo $path
echo $DIR

for K in {1..22};
do
rm $path/temp2_chr${K}.txt
echo 'removed'
touch $path/temp2_chr${K}.txt
chmod 777 $path/temp2_chr${K}.txt
#bsub -M 20240 -o ${DIR}/logs/logmaster -e ${DIR}/logs/logmaster 
bash ${DIR}/bcf_commands.sh $K ${path}/temp_chr${K}.txt ${path} ${dtset}
sleep 20
echo $K  ' done'
done
