% RUN_TESTS  Suite de verificacion del simulador. Ejecutar tras CUALQUIER
%   cambio en la aerodinamica, ecuaciones de movimiento o trim.
%   Cada prueba imprime PASS/FAIL; el resumen final dice si el repo esta sano.
clc; clear;
nfail = 0;

%% Parametros de referencia
g=9.80665; m=9295.44; S=27.87; b=9.144; cbar=3.45;
Xcgr=0.35; Xcg=0.30;
Ix=12874.8; Iy=75673.6; Iz=85552.1; Ixz=1331.4;
gama=Ix*Iz-Ixz^2;
c1=((Iy-Iz)*Iz-Ixz^2)/gama; c2=((Ix-Iy+Iz)*Ixz)/gama; c3=Iz/gama;
c4=Ixz/gama; c5=(Iz-Ix)/Iy; c6=Ixz/Iy; c7=1/Iy;
c8=(Ix*(Ix-Iy)+Ixz^2)/gama; c9=Ix/gama; Heng=216.9;
theta=[m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng,0,0]';

%% T1: trim nivelado converge y en valores conocidos
%   (rho ISA=0.909 a 3000 m -> CL=0.25 -> alfa=2.88 deg, de=-1.89 deg)
[Xt,Ut,info] = trim_crucero(170,3000,theta);
ok = info.converge && abs(info.alfa_deg-2.884)<0.05 && abs(info.de_deg+1.885)<0.05;
nfail = nfail + reporte('T1 trim nivelado (alfa~2.88, de~-1.89)', ok);

%% T2: trim general = trim nivelado cuando gamma=psidot=0
[X2,U2,i2] = trim_vuelo(170,3000,0,0,theta);
ok = i2.converge && abs(i2.alfa_deg-info.alfa_deg)<0.02 && abs(i2.fi_deg)<0.1;
nfail = nfail + reporte('T2 trim_vuelo(0,0) == trim_crucero', ok);

%% T3: viraje coordinado: banco = atan(psidot*V/g)
[X3,U3,i3] = trim_vuelo(170,3000,0,3,theta);
fi_teo = atan2(3*pi/180*170, g)*180/pi;
ok = i3.converge && abs(i3.fi_deg-fi_teo)<1.0;
nfail = nfail + reporte(sprintf('T3 viraje coordinado (fi=%.1f, teorico %.1f)',i3.fi_deg,fi_teo), ok);

%% T4: simetria lateral exacta en condicion simetrica
X=Xt; X(5)=0; X(6)=0; X(8)=0; U=Ut; U(2)=0; U(3)=0;
dX = funciones(0,X,U,theta);
ok = all(abs(dX([5 6 8]))<1e-10);
nfail = nfail + reporte('T4 simetria lateral (beta_dot=p_dot=r_dot=0)', ok);

%% T5: linealizacion coincide con jacobiano numerico (via validar_A)
salida = evalc('validar_A');
ok = contains(salida,'COINCIDE');
nfail = nfail + reporte('T5 matriz A analitica vs jacobiano numerico', ok);

%% T6: equivalencia cuaterniones vs Euler (2 s de vuelo perturbado)
theta=[m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng,0,0]'; %#ok<NASGU>
[Xt,Ut,info] = trim_crucero(170,3000,theta);
teta_tr = 2*asin(Xt(11));
Xq=Xt; Xq(4)=Xq(4)+3*pi/180;
Xe=[Xt(1);Xt(2);Xt(3);Xt(4)+3*pi/180;0;0;0;0;0;teta_tr;0;0;0;Xt(15)];
to=0; ho=0.002; Xoq=Xq; Xoe=Xe;
for k=1:1000
    [~,~,Xoq]=rkfv03(@funciones,to,ho,Xoq,Ut,theta);
    [~,~,Xoe]=rkfv03(@funciones_euler,to,ho,Xoe,Ut,theta);
    to=to+ho;
end
ok = abs(Xoq(4)-Xoe(4))<1e-10 && abs(Xoq(3)-Xoe(3))<1e-8;
nfail = nfail + reporte('T6 equivalencia cuaterniones vs Euler', ok);

%% T7: modos longitudinales y laterales en valores de libro
[A15,B15] = linmod_fd(0,Xt,Ut,theta);
dq_dteta=[-0.5*sin(teta_tr/2);0;0.5*cos(teta_tr/2);0]; colTeta=A15(:,9:12)*dq_dteta;
mapLon=[3 4 7 0 1 2]; Alon=zeros(6,6);
for i=1:6
    fr=mapLon(i);
    if fr==0, Alon(i,:)=[0 0 1 0 0 0];
    else
        for j=1:6, fj=mapLon(j);
            if fj==0, Alon(i,j)=colTeta(fr); else, Alon(i,j)=A15(fr,fj); end
        end
    end
end
ev = eig(Alon);
% periodo corto ~ -1.22 +- 1.54i  ;  fugoide ~ -0.006 +- 0.076i
sp = ev(abs(imag(ev))>1 & real(ev)<-0.5);
fu = ev(abs(imag(ev))<0.2 & abs(imag(ev))>0.01);
ok = ~isempty(sp) && abs(real(sp(1))+1.22)<0.3 && ...
     ~isempty(fu) && abs(abs(imag(fu(1)))-0.076)<0.02;
nfail = nfail + reporte('T7 modos longitudinales (periodo corto y fugoide)', ok);

%% T8: el trim se sostiene 10 s en lazo abierto sin deriva
Xo=Xt; to=0;
for k=1:5000, [~,~,Xo]=rkfv03(@funciones,to,ho,Xo,Ut,theta); to=to+ho; end
ok = abs(Xo(3)-170)<0.5 && abs(Xo(4)-Xt(4))*180/pi<0.1 && abs(Xo(6))*180/pi<0.05;
nfail = nfail + reporte('T8 trim sostenido 10 s en lazo abierto', ok);

%% T9: fisica de atmosfera y motor
[~,~,rho3k,~] = atmosfera(3000);
FT_bajo = FT(50,0.5,0); FT_alto = FT(50,0.5,-10000);      % zE NED
ok = abs(rho3k-0.9093)<0.005 && FT_bajo>FT_alto && FT_alto>0;
nfail = nfail + reporte('T9 atmosfera ISA y empuje decreciente con altitud', ok);

%% Resumen
fprintf('=====================================================\n');
if nfail==0
    fprintf(' TODAS LAS PRUEBAS PASAN: el simulador esta sano.\n');
else
    fprintf(' %d PRUEBA(S) FALLARON: revisa antes de usar resultados.\n', nfail);
end
fprintf('=====================================================\n');

function f = reporte(nombre, ok)
    if ok, fprintf('[PASS] %s\n', nombre); f=0;
    else,  fprintf('[FAIL] %s\n', nombre); f=1;
    end
end
