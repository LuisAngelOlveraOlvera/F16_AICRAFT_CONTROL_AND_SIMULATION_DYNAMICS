function[y]=hu(t,X,U,theta)
% U2 = [de,da,dr,qbar];
VT = X(1); alfa = X(2); beta = X(3); p = X(4); q = X(5); r = X(6);
de = U(1); da = U(2); dr = U(3); qbar = U(4); dlef = U(5);
[m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng]=parametros(theta);
        Xint  = Xbar(alfa,beta,de,dlef,q,cbar,VT,S,qbar);
        Yint  = Ybar(alfa,beta,dlef,da,dr,r,b,VT,p,S,qbar,de);
        Zint  = Zbar(alfa,beta,de,dlef,q,cbar,VT,S,qbar);
        Nint  = Nbar(alfa,beta,de,dlef,Xcgr,Xcg,cbar,b,da,dr,r,VT,p,qbar,S);
        Lint  = Lbar(alfa,beta,dlef,da,dr,r,b,VT,qbar,S,de,p);
        Mint  = Mbar(alfa,beta,de,Xcgr,Xcg,dlef,q,cbar,VT,qbar,S); 
        y=[Xint,Yint,Zint,Nint,Lint,Mint]';
end