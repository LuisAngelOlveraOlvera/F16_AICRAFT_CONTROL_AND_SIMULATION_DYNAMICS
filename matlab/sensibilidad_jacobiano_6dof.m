function s = sensibilidad_jacobiano_6dof(r)
% SENSIBILIDAD_JACOBIANO_6DOF  Diferencias centradas de orden 2 y 4.
% Interior h=1000 m: evita promediar las ramas de FT en h=0.
% Es un snapshot numerico, no un trim nuevo ni modos de vuelo sostenido.
if nargin<1,r=comparar_f16_estandarizado;end
x=r.propio_trim.Xe; x(14)=-1000;
u=r.propio_trim.U4; theta=r.auditoria_lateral.original.theta;
f=@(z) funciones_euler(0,z,u,theta);
ref=centrada(f,x,1e-5,4);
s=struct('Xe',x,'U4',u,'residuo',f(x),'referencia_numerica',ref, ...
    'etiqueta','Snapshot interior: referencia numerica, no matriz analitica ni modos sostenidos');
for k=1:9
    h=10^(-k-1); A2=centrada(f,x,h,2); A4=centrada(f,x,h,4);
    s.pasos(k)=struct('h_relativo',h,'A2',A2,'A4',A4, ...
        'max_diferencia2',max(abs(A2-ref),[],'all'), ...
        'max_diferencia4',max(abs(A4-ref),[],'all')); %#ok<AGROW>
end
assert(s.pasos(3).max_diferencia4<1e-5,'sensibilidad_f16:Convergencia', ...
    'El Jacobiano de orden 4 no converge en la region interior.');
fprintf('SENSIBILIDAD_6DOF: orden4 h=1e-4 vs 1e-5, max %.3e\n',s.pasos(3).max_diferencia4);
end

function A=centrada(f,x,h,orden)
A=zeros(numel(f(x)),numel(x));
for j=1:numel(x)
    d=zeros(size(x)); d(j)=h*max(1,abs(x(j)));
    if orden==2
        A(:,j)=(f(x+d)-f(x-d))/(2*d(j));
    else
        A(:,j)=(-f(x+2*d)+8*f(x+d)-8*f(x-d)+f(x-2*d))/(12*d(j));
    end
end
end
