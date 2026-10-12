function [u,g] = guiar_waypoints_f16(pos_ned,w,tramo,VT,anticipacion,radio)
% GUIAR_WAYPOINTS_F16 Ruta poligonal [N,E,h] m; posicion [N,E,D] m.
% Anticipacion por longitud horizontal. Waypoints de paso, no paradas.
validateattributes(w,{'numeric'},{'2d','ncols',3,'finite','real'});
assert(size(w,1)>=2 && all(vecnorm(diff(w(:,1:2)),2,2)>1),'f16:Ruta','Tramos horizontales degenerados.');
p=pos_ned(:).';p(3)=-p(3);n=size(w,1);
tramo=min(n-1,max(1,tramo));
while tramo<n-1
    v=w(tramo+1,1:2)-w(tramo,1:2);
    s=dot(p(1:2)-w(tramo,1:2),v)/dot(v,v);
    if s>=1 || norm(p(1:2)-w(tramo+1,1:2))<radio,tramo=tramo+1;else,break;end
end
v=w(tramo+1,1:2)-w(tramo,1:2);L=norm(v);
s=max(0,min(1,dot(p(1:2)-w(tramo,1:2),v)/(L*L)));
q=w(tramo,:)+s*(w(tramo+1,:)-w(tramo,:));
remaining=anticipacion;aim=q;j=tramo;
while remaining>0 && j<n
    d=norm(w(j+1,1:2)-aim(1:2));
    if d>=remaining,aim=aim+(remaining/d)*(w(j+1,:)-aim);remaining=0;
    else,remaining=remaining-d;aim=w(j+1,:);j=j+1;end
end
delta=aim(1:2)-p(1:2);
if norm(delta)<1,delta=v;end
u=[aim(3),VT,atan2(delta(2),delta(1))];
% Distancia espacial minima a toda la polilinea, independiente del tramo activo.
err=inf;
for i=1:n-1
    dv=w(i+1,:)-w(i,:);z=max(0,min(1,dot(p-w(i,:),dv)/dot(dv,dv)));
    err=min(err,norm(p-w(i,:)-z*dv));
end
g=struct('tramo',tramo,'error_transversal_m',norm(p(1:2)-q(1:2)), ...
    'error_espacial_m',err,'distancia_final_m',norm(p-w(end,:)), ...
    'finalizado',tramo==n-1 && norm(p-w(end,:))<=radio);
end
