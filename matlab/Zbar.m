function[y]=Zbar(alfa,beta,de,dlef,q,cbar,VT,S,qbar)
 if VT==0
     y=0;
 else  
    y = S*qbar*Czt(alfa,beta,de,dlef,q,cbar,VT);
 end
end