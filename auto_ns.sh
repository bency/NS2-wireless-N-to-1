#!/bin/bash
clear

# set tcp version

TCP_VERSION_ARR[0]='TCP';
TCP_VERSION_ARR[1]='Tahoe';
TCP_VERSION_ARR[2]='Reno';
TCP_VERSION_ARR[3]='Newreno';
TCP_VERSION_ARR[4]='Vegas';

# set num_node itv_node

num_node=300;

itv_node=10;

for (( j=0 ; j<5 ; j+=1 )); do

    echo -e "\e[1;31mCreate\e[0m [${TCP_VERSION_ARR[$j]}]";

    if [ ! -d ${TCP_VERSION_ARR[$j]} ]; then

        mkdir ${TCP_VERSION_ARR[$j]};

    fi

    pkg_file=${TCP_VERSION_ARR[$j]}"/total_pkg.dat";

    pkg_jpg_file=${TCP_VERSION_ARR[$j]}"/total_pkg.jpg";

    if [ -s $pkg_file ]; then

        rm $pkg_file;
    fi

    for (( i=$itv_node ; i<=$num_node ; i+=$itv_node ));do

        tcl_file=${TCP_VERSION_ARR[$j]}"/"$i".tcl";

        tr_file=${TCP_VERSION_ARR[$j]}"/"$i".tr";

        dat_file=${TCP_VERSION_ARR[$j]}"/"$i"_result.dat";

        jpg_file=${TCP_VERSION_ARR[$j]}"/"$i".jpg";

        ./gen_tcl.sh $i $j;

        ns=$(which ns);

        if [ $ns ];then
            
            echo "";

            echo -e "\033[31;1mStart simulation procudure\033[37;0m: \033[34;1mns \033[31;1m$tcl_file\033[0m;";

            echo -e "\033[33;1m";

            ns $tcl_file;
            
            echo -e "\033[0m";

            echo "Create $dat_file";

            echo "";

            awk -f data_rate.awk $tr_file > $dat_file;

            total_byte=$(awk -f total_pkg.awk $dat_file);
            
            echo $total_byte >> $pkg_file;
            
            echo "";

            echo "Create $pkg_file";

            echo "";

            gp=$(which gnuplot)

#            if [ $gp ];then

#                echo "plot $dat_file into $jpg_file";

#                gnuplot -e "set term jpeg;set output '$jpg_file';plot '$dat_file' with line";

#                rm $tcl_file;

#                rm $dat_file;

#            fi

            echo "Remove tcl tr dat files in ${TCP_VERSION_ARR[$j]}";

#            rm $tr_file;

        fi

    done

    if [ $ns ] && [ $gp ];then
        
        gnuplot -e "set term jpeg; set output '$pkg_jpg_file'; plot '$pkg_file' with line"

        #rm $pkg_file;

    fi

done
