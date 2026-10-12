function[y]=Lbar(alfa,beta,dlef,da,dr,r,b,VT,qbar,S,de,p)
if VT==0
    y=0;
else
    y = qbar*S*b*Clt(alfa,beta,dlef,da,dr,r,b,VT,de,p);
end
end