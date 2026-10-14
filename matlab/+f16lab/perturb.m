function x=perturb(x,z)
a=f16lab.angles(x(9:12));x(4:5)=x(4:5)+[z.alpha_deg;z.beta_deg]*pi/180;
x(6:8)=x(6:8)+[z.p_deg_s;z.q_deg_s;z.r_deg_s]*pi/180;
a=a+[z.phi_deg;z.theta_deg;z.psi_deg]*pi/180;x(9:12)=f16lab.quaternion(a(1),a(2),a(3));
end
