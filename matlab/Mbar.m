function[y]=Mbar(alfa,beta,de,Xcgr,Xcg,dlef,q,cbar,VT,qbar,S)
   if VT==0
       y=0;
   else
    y = S*qbar*cbar*Cmt(alfa,beta,de,Xcgr,Xcg,dlef,q,cbar,VT);
   end
end