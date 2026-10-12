function[y]=Xbar(alfa,beta,de,dlef,q,cbar,VT,S,qbar)
   if VT==0;
       y=0;
   else
    y=S*qbar*Cxt(alfa,beta,de,dlef,q,cbar,VT);
   end
end