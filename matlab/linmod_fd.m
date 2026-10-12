function [A,B] = linmod_fd(t,X,U,theta)
% LINMOD_FD  Linealizacion completa del modelo NO lineal de 15 estados.
%   x_dot = funciones(t,X,U,theta)
%   A = df/dX (15x15),  B = df/dU (15x4, columnas: de, da, dr, dth)
%   por diferencias finitas centradas alrededor del punto (X,U), tipicamente
%   un punto de trim de trim_crucero.
%
%   Estados: [P3, alfaf, VT, alfa, beta, p, q, r, q0, q1, q2, q3, xE, yE, zE]

    A = jacobiano_fd(@(x) funciones(t,x,U,theta), X);

    U = U(:);
    n = numel(X); mU = numel(U);
    B = zeros(n,mU);
    for j = 1:mU
        h  = 1e-6 * max(1, abs(U(j)));
        Up = U; Up(j) = Up(j) + h;
        Um = U; Um(j) = Um(j) - h;
        B(:,j) = (funciones(t,X,Up,theta) - funciones(t,X,Um,theta)) / (2*h);
    end
end
