function[y]=Nbar(alfa,beta,de,dlef,Xcgr,Xcg,cbar,b,da,dr,r,VT,p,qbar,S)
    if VT==0
        y=0;
    else
    y=S*b*qbar*Cnt(alfa,beta,de,dlef,Xcgr,Xcg,cbar,b,da,dr,r,VT,p);
    end
end