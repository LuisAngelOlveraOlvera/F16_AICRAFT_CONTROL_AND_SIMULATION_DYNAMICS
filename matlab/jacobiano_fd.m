function J = jacobiano_fd(fun, X)
% JACOBIANO_FD  Jacobiano numerico por diferencias finitas centradas.
%   fun : handle a una funcion f(X) que regresa un vector columna.
%   X   : punto de evaluacion (vector columna).
%   J(i,j) = d f_i / d X_j   (mismo convenio que matriz_A).
%
%   Error O(h^2); con h relativo da ~8-9 digitos de exactitud, suficiente
%   para validar derivadas analiticas.

    X  = X(:);
    n  = numel(X);
    f0 = fun(X);
    m  = numel(f0);
    J  = zeros(m,n);
    for j = 1:n
        h  = 1e-6 * max(1, abs(X(j)));
        Xp = X; Xp(j) = Xp(j) + h;
        Xm = X; Xm(j) = Xm(j) - h;
        J(:,j) = (fun(Xp) - fun(Xm)) / (2*h);
    end
end
