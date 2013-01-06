BEGIN{
start = 0;
}
{
if($2 > start){
		
		print start,package[start]/1024;
		start += 1;
	}
if($7 == "tcp" && $1 == "r" && $3 == "_0_")
	package[start] += $8;
}
END{}
