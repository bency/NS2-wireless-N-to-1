#!/bin/bash
TCP_VERSION_ARR[0]='TCP';
TCP_VERSION_ARR[1]='Tahoe';
TCP_VERSION_ARR[2]='Reno';
TCP_VERSION_ARR[3]='Newreno';
TCP_VERSION_ARR[4]='Vegas';
for (( j=0 ; j<5 ; j+=1 )); do

    echo "Create [${TCP_VERSION_ARR[$j]}]";

    mkdir ${TCP_VERSION_ARR[$j]};

    for (( i=1 ; i<200 ; i+=1 ));do

    tcl_file=${TCP_VERSION_ARR[$j]}"/"$i".tcl";

    tr_file=${TCP_VERSION_ARR[$j]}"/"$i".tr";

    dat_file=${TCP_VERSION_ARR[$j]}"/"$i"_result.dat";

    jpg_file=${TCP_VERSION_ARR[$j]}"/"$i".jpg";

    ./gen_tcl.sh $i $j;

    ns=$(which ns);

    if [ $ns ];then

        ns $tcl_file;

        awk -f data_rate.awk $tr_file >> $dat_file;

        gp=$(which gnuplot)

        if [ $gp ];then

			gnuplot -e "set term jpeg;set output '$jpg_file';plot '$dat_file' with line";

			rm $tcl_file;

			rm $dat_file;

        fi

        echo "Remove tcl tr dat files in ${TCP_VERSION_ARR[$j]}";

        rm $tr_file;

    fi

    done

done
