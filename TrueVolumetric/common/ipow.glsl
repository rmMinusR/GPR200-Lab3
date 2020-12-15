#ifndef HG_IPOW
#define HG_IPOW

//Integer-power. Significantly faster than pow(float, float)
float ipow(float b, int x) {
	/*
		b^x =
		b^(x_0+x_1+...+x_n) =
		b^x_0 * b^x_1 * ... * b^x_n
		x_k represents a bitmasked x where only the k-th bit is passed through
	*/
    //Acts as a stack representing x, will be interpreted one bit at a time LSB first
    uint powstack = uint(x);
    
    //Will always be b raised to some power that is a power of two
    //(p^q)^2 = p^2q
    float p2 = b;
    
    //The output b^x_0 * ... * b^x_k
    float val = 1.;
    
    //Loop until we've reached the last bit (will always be most-significant)
    while(powstack != uint(0)) {
        //Pop a bit from remaining power stack
        bool poppedBit = (powstack&uint(1)) != uint(0);
        powstack = powstack >> 1;
        
        //Update output value
        if(poppedBit) val *= p2;
        
        //Powers of b raised to a power of two.
        //(p^q)^2 = p^2q
        //(p^2^k)^2 = p^(2*2^k) = p^2^(k+1)
        p2 *= p2;
    }
    
    return val;
}

#endif