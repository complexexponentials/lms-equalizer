import math
#http://websvn.ukumari/filedetails.php?repname=FF.PROXIMITY-1%2Fwork&path=%2Fcode%2FPython%2Ffpga_com%2Fbranch%2Ffpga_com_tr%2FFpgaCom%2Fconfigs%2FDec2bin.py

def dec2bin(f,nbi,nbf):
    # Convierte el flotante en binario
    if f >= 1:
        g = int(math.log(f, 2))
    else:
        g = -1
    h = g + 1
    ig = math.pow(2, g)
    st = ""    
    while f > 0 or ig >= 1:
        if f < 1 and nbf!=0:
            if len(st[h:]) >= nbf:
                break
        if f >= ig:
            st += "1"
            f -= ig
        else:
            st += "0"
        ig /= 2
       
    # Antes de guardar el resultado
    # de conversion se controla
    # si es posible
    # representar la palabra segun
    # la resolucion
    if len(st[:h])>nbi:
        intbin  = (nbi*'1')
    elif len(st[:h])<nbi:
        intbin = (nbi-len(st[:h]))*'0' + st[:h]
    else:
        intbin = st[:h]

    if nbf==0:
        binvalue = intbin
    else:
        if len(st[:h])>nbi:
            fracbin = (nbf*'1')
        elif len(st[h:])<nbf:
            fracbin = st[h:] + (nbf-len(st[h:]))*'0'
        else:
            fracbin = st[h:]
       
        binvalue = intbin + fracbin
   
    # Se convierte al equivalente
    # decimal mas cercano
    decequivalent = 0.0
    for ptr_int in range(nbi):
        decequivalent += int(intbin[ptr_int])*(2**((nbi-1)-ptr_int))
    for ptr_frac in range(nbf):
        decequivalent += int(fracbin[ptr_frac])*(2**-(ptr_frac+1))

    # Se convierte al entero equivalente
    intvalue = 0
    for ptr_inteq in range(nbi+nbf):
        intvalue += int(int(binvalue[ptr_inteq])*(2**((nbi+nbf-1)-ptr_inteq)))

   
    #st = st[:h] + "." + st[h:]
    return [binvalue,decequivalent,intvalue]

def dec2bins(f,nbi,nbf,sign):
    # Convierte el flotante en binario
    if (f>=0 and sign=='ss'):
        [binout,decout,intout] = dec2bin(f,nbi,nbf)

    elif (f>=0 and sign=='cs'):
        integ = (nbi-1)*'1'
        fract = nbf*'1'

        decequivalent = 0.0
        for ptr_int in range(nbi-1):
            decequivalent += int(integ[ptr_int])*(2**((nbi-2)-ptr_int))
        for ptr_frac in range(nbf):
            decequivalent += int(fract[ptr_frac])*(2**-(ptr_frac+1))

        if (f>decequivalent):
            [binout,decout,intout] = dec2bin(decequivalent,nbi,nbf)
        else:
            [binout,decout,intout] = dec2bin(f,nbi,nbf)

    elif (f<0 and sign=='cs'):
        integ  = '1'+(nbi-1)*'0'
        valint = -(int(integ,2))
        refint = nbi*'1'
        reffrac = nbf*'1'
        ref    = refint + reffrac


        if (f<=valint):
            [binout,decout,intout] = dec2bin(int(integ,2),nbi,nbf)
            decout = -decout

        else:
            [binout,decout,intout] = dec2bin(-f,nbi,nbf)
           
            intvalue = 0
            for ptr_inteq in range(nbi+nbf):
                intvalue += int(int(ref[ptr_inteq])*(2**((nbi+nbf-1)-ptr_inteq)))
           
            binout = bin((int(binout,2)^int(intvalue))+1)
            binout = binout[2:len(binout)]
            decout = -decout

            intvalue = 0
            for ptr_inteq in range(nbi+nbf):
                intvalue += int(int(binout[ptr_inteq])*(2**((nbi+nbf-1)-ptr_inteq)))
            intout = intvalue

    else:
        print "Numero no valido"
        binout = ''
        decout = ''
        intout = ''
   
    return [binout,decout,intout]
