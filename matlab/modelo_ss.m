function [A,B,C,D,info] = modelo_ss(tipo, VT, h, theta)
% MODELO_SS  Cuadruple (A,B,C,D) del F-16 linealizado en trim nivelado,
%   con polos y ceros de transmision por canal (solo MATLAB base).
%
%   [A,B,C,D,info] = modelo_ss('longitudinal', 170, 3000, theta)
%   [A,B,C,D,info] = modelo_ss('lateral',      170, 3000, theta)
%   [A,B,C,D,info] = modelo_ss('completo',     170, 3000, theta)
%
%   longitudinal: x=[dVT dalfa dq dteta dP3 dalfaf]  u=[de dth]
%                 y=[dVT dalfa dq dteta]
%   lateral     : x=[beta p r fi]                    u=[da dr]
%                 y=x
%   completo    : x=15 estados de funciones.m        u=[de da dr dth]
%                 y=x  (C=I, D=0)
%
%   info.polos           : autovalores de A
%   info.ceros{i,j}      : ceros de transmision del canal u_j -> y_i
%   info.Xtrim/Utrim     : punto de trim usado
%   Sin argumento de salida, imprime el resumen polo-cero por canal.
%
%   Los ceros salen del haz generalizado (pencil de Rosenbrock):
%       z tal que  det([zI-A  -b; c  d]) = 0
%   equivalente a lo que reporta el simulador de Russell via tzero().

    [Xtrim,Utrim,tinfo] = trim_vuelo(VT,h,0,0,theta);
    [A15,B15] = linmod_fd(0,Xtrim,Utrim,theta);
    teta_tr = 2*asin(Xtrim(11));

    switch lower(tipo)
        case 'longitudinal'
            dq_dteta=[-0.5*sin(teta_tr/2);0;0.5*cos(teta_tr/2);0];
            colTeta=A15(:,9:12)*dq_dteta;
            mapa=[3 4 7 0 1 2];
            A=zeros(6,6); B=zeros(6,2);
            for i=1:6
                fr=mapa(i);
                if fr==0, A(i,:)=[0 0 1 0 0 0];
                else
                    for j=1:6, fj=mapa(j);
                        if fj==0, A(i,j)=colTeta(fr); else, A(i,j)=A15(fr,fj); end
                    end
                    B(i,:)=B15(fr,[1 4]);
                end
            end
            C=[eye(4) zeros(4,2)]; D=zeros(4,2);
            info.estados={'dVT','dalfa','dq','dteta','dP3','dalfaf'};
            info.entradas={'de','dth'}; info.salidas={'dVT','dalfa','dq','dteta'};
        case 'lateral'
            dq_dfi=[0;0.5*cos(teta_tr/2);0;-0.5*sin(teta_tr/2)];
            colFi=A15(:,9:12)*dq_dfi;
            mapa=[5 6 8 0];
            A=zeros(4,4); B=zeros(4,2);
            for i=1:4
                fr=mapa(i);
                if fr==0, A(i,:)=[0 1 tan(teta_tr) 0];
                else
                    for j=1:4, fj=mapa(j);
                        if fj==0, A(i,j)=colFi(fr); else, A(i,j)=A15(fr,fj); end
                    end
                    B(i,:)=B15(fr,[2 3]);
                end
            end
            C=eye(4); D=zeros(4,2);
            info.estados={'beta','p','r','fi'};
            info.entradas={'da','dr'}; info.salidas=info.estados;
        case 'completo'
            A=A15; B=B15; C=eye(15); D=zeros(15,4);
            info.estados={'P3','alfaf','VT','alfa','beta','p','q','r', ...
                          'q0','q1','q2','q3','xE','yE','zE'};
            info.entradas={'de','da','dr','dth'}; info.salidas=info.estados;
        otherwise
            error('modelo_ss: tipo debe ser longitudinal | lateral | completo');
    end

    info.polos = eig(A);
    info.Xtrim = Xtrim; info.Utrim = Utrim; info.trim = tinfo;
    [ny,nu] = size(D);
    info.ceros = cell(ny,nu);
    for i=1:ny
        for j=1:nu
            info.ceros{i,j} = ceros_tx(A,B(:,j),C(i,:),D(i,j));
        end
    end

    if nargout==0
        fprintf('=== modelo_ss (%s) @ VT=%g m/s, h=%g m ===\n',tipo,VT,h);
        fprintf('Trim: alfa=%.3f deg, de=%.3f deg, dth=%.4f\n', ...
                tinfo.alfa_deg, tinfo.de_deg, tinfo.dth);
        fprintf('POLOS:\n'); disp(sort(info.polos));
        for i=1:ny
            for j=1:nu
                z=info.ceros{i,j};
                fprintf('CEROS  %s -> %s : ', info.entradas{j}, info.salidas{i});
                if isempty(z), fprintf('(ninguno finito)\n');
                else, fprintf('%s\n', strtrim(sprintf('%.4g%+.4gi  ',[real(z) imag(z)].')));
                end
                if any(real(z)>1e-6)
                    fprintf('        ^ FASE NO MINIMA (cero en semiplano derecho)\n');
                end
            end
        end
    end
end

function z = ceros_tx(A,b,c,d)
% Ceros de transmision SISO via haz generalizado de Rosenbrock.
    n = size(A,1);
    M = [A b; c d];
    N = blkdiag(eye(n),0);
    z = eig(M,N);
    z = z(isfinite(z) & abs(z)<1e7);   % descarta ceros en el infinito
end
