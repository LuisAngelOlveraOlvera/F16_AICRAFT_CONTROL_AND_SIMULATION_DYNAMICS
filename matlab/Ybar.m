function[y]=Ybar(alfa,beta,dlef,da,dr,r,b,VT,p,S,qbar,de)
if VT==0
    y=0;
else 
    y=S*qbar*Cyt(alfa,beta,dlef,da,dr,r,b,VT,p,de);
end
end