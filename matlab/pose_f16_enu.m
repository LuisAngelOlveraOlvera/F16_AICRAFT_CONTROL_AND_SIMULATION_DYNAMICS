function T = pose_f16_enu(q,posicion_ned)
% POSE_F16_ENU  Pose cuerpo->Este,Norte,Arriba (escena derecha).
% q escalar primero; geometria cuerpo x adelante,y derecha,z abajo.
validateattributes(q,{'numeric'},{'real','finite','vector','numel',4});
validateattributes(posicion_ned,{'numeric'},{'real','finite','vector','numel',3});
assert(norm(q)>0,'pose_f16:Cuaternion','Cuaternion de norma cero.');
q=q(:)/norm(q); a=q(1);b=q(2);c=q(3);d=q(4);
R=[a*a+b*b-c*c-d*d,2*(b*c-a*d),2*(b*d+a*c); ...
   2*(b*c+a*d),a*a-b*b+c*c-d*d,2*(c*d-a*b); ...
   2*(b*d-a*c),2*(c*d+a*b),a*a-b*b-c*c+d*d];
P=[0 1 0;1 0 0;0 0 -1];
T=[P*R P*posicion_ned(:);0 0 0 1];
end
