function Y=gauss01(X,xo,Y,yo,sigma,A)
    Y = A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
end