cp ./libpic/convolution.pic source.pic
cat ./test/conv.pic >> source.pic
./picel.native < source.pic > tmp.ll
llc -filetype=obj tmp.ll 
llvm-g++ tmp.o bitmap/bmplib.o 

