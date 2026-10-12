function [K,P] = lqr_gain(A,B,Q,R)
% LQR_GAIN  Ganancia LQR de horizonte infinito: u = -K x.
%   Usa lqr() del Control System Toolbox si esta disponible; si no,
%   resuelve la ecuacion algebraica de Riccati con el metodo del
%   Hamiltoniano (eigenvectores estables) usando solo MATLAB base.

    if exist('lqr','file') == 2
        [K,P] = lqr(A,B,Q,R);
        return
    end
    n = size(A,1);
    H = [A, -B*(R\B'); -Q, -A'];
    [V,D] = eig(H);
    lam = diag(D);
    idx = find(real(lam) < 0);
    if numel(idx) ~= n
        error('lqr_gain: el Hamiltoniano no tiene n autovalores estables.');
    end
    V1 = V(1:n, idx);
    V2 = V(n+1:end, idx);
    P  = real(V2/V1);
    P  = (P+P')/2;                      % simetrizar por redondeo
    K  = R\(B'*P);
end
