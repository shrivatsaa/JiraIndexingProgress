#!/bin/sh

Red=$'\e[1;31m'
white=$'\e[0m'

if ! which gnuplot >/dev/null; then echo $red'You do not have gnuplot installed (or not found in PATH). Plese run "brew install gnuplot"'$white;
    exit;
fi

awk '/Re-indexing is .* complete/{if($(NF-4)~/[0-9]%/){split($2,a,",");sub(/%/,"",$(NF-4));print $1,a[1],$3,$(NF-4)}}' atlassian-jira.log*| sort -nk4 | awk '{split($1,a,"-");split($2,b,":");timedate=sprintf("%s%s%s%s%s%s",a[1]" ",a[2]" ",a[3]" ",b[1]" ",b[2]" ",b[3])}{epoch=mktime(timedate);print $1,$2,$3,$4,epoch}' | awk '{(NR>1) ? diff=$5-prev : diff=0 ;prev=$5}{print $5,$1,$2,$3,$4,diff/60}'  > PlotIndex;
Average=$(awk '{Tot=i++;sum+=$6}END{print sum/Tot}' PlotIndex);
MaxYRange=$(awk '{if($6>max){max = $6}}END{print max}' PlotIndex);
TotalIndexingTime=$(awk 'NR==1{BeginTime=$1}END{EndTime=$1}END{print (EndTime-BeginTime)/60/60"hours"}' PlotIndex)

for FILE in $(ls PlotIndex); do
    Header="IndexProgress";
    gnuplot -persist <<- EOF
        set term qt font "Arial,12"
        set xlabel "Perentage"
        set ylabel "Elapsed Minutes"
        set yrange [0:${MaxYRange}]
        set title "Indexing Progress(Total Indexing Time=${TotalIndexingTime})"
        set grid
        plot ${Average} title "Average Indexing Time = ${Average}min","${FILE}" using 5:6 title "${Header}" with lines 
EOF
done

rm PlotIndex  > /dev/null



