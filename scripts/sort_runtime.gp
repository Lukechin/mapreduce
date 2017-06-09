reset 
set ylabel 'time(s)'
set xlabel 'sort num n'
set style fill solid 
set key left box
set term png enhanced font 'Mono,10'

set title "total map time on sort"
set output 'sort_bench_map.png'

plot for [i=0:4] 'sort_bench_'.(2**i).'.csv' using 2:3 with linespoint title ''.(2**i).' threads'

set title "total reduce time on sort"
set output 'sort_bench_reduce.png'

plot for [i=0:4] 'sort_bench_'.(2**i).'.csv' using 2:4 with linespoint title ''.(2**i).' threads'
