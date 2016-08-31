# We should first reverse the order of the transformation, then convert them intelligently!
# The nnet has to be in ascii form

awk 'BEGIN{
   ntrans = 0;
}
($1 ~ /^</){
   ntrans++; dimIn[ntrans] = $3; dimOut[ntrans] = $2; w = 1;
   if ($1 ~ /<Splice>/){mode[ntrans] = 1;}
   else if ($1 ~ /<Nnet>/){ntrans--; w = 0}
   else if ($1 ~ "</Nnet>"){ntrans--; w = 0}
   else if ($1 ~ "<!EndOfComponent>"){ntrans--; w = 0}
   else if ($1 ~ "<LearnRateCoef>"){ntrans--; w = 1}
   else if ($1 ~ /<AddShift>/){mode[ntrans] = 2;}
   else if ($1 ~ /<Rescale>/){mode[ntrans] = 3;}
   else { print "Unsuported transform: "$1; exit(-2) }
}
{  if (w)
     data[ntrans] = $0;
}
END{
printf "<Nnet>\n";
for (i = ntrans; i >= 1; i--) {
   l = split(data[i], v)
   if (mode[i] == 1) {
      printf "<Copy> %d %d\n", dimIn[i], dimOut[i];
      iStart =  dimIn[i] * ((l - 3) / 2) + 1;
      iEnd = iStart + dimIn[i] - 1;
      printf "[";
      for (j = iStart; j <= iEnd; j++) printf " %d", j;
      printf " ]\n";
   }
   else if (mode[i] == 2) {
      printf "<AddShift> %d %d\n", dimOut[i], dimIn[i];
      printf "<LearnRateCoef> 0 [";
      for (j = 4; j <= l - 1; j++) printf " %f", 0.0 - v[j];
      printf " ]\n";
      printf "<!EndOfComponent>\n";
   }
   else if (mode[i] == 3) {
      printf "<Rescale> %d %d\n", dimOut[i], dimIn[i];
      printf "<LearnRateCoef> 0 [";
      for (j = 4; j <= l - 1; j++) printf " %f", 1.0 / v[j];
      printf " ]\n";
      printf "<!EndOfComponent>\n";
   }
}
printf "</Nnet>\n"
}'
