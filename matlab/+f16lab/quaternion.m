function q=quaternion(phi,theta,psi)
c=cos([phi theta psi]/2);s=sin([phi theta psi]/2);
q=[c(1)*c(2)*c(3)+s(1)*s(2)*s(3);s(1)*c(2)*c(3)-c(1)*s(2)*s(3); ...
 c(1)*s(2)*c(3)+s(1)*c(2)*s(3);c(1)*c(2)*s(3)-s(1)*s(2)*c(3)];
end
