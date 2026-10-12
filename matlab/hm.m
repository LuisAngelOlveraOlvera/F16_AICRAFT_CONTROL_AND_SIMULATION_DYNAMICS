function[y]=hm(t,X,U,teta)
P3 = X;
mach = U(2);
zE = U(3);
FTint = FT(P3,mach,zE);
y = FTint; 
end