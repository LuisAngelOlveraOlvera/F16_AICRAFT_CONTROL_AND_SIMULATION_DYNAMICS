function c=design(x,u,w,act,legacy)
p=f16lab.parameters;a=f16lab.angles(x(9:12));
if legacy
    [A,B]=linmod_fd(0,x,u,p);pitch=2*asin(x(11));
    dt=[-.5*sin(pitch/2);0;.5*cos(pitch/2);0];df=[0;.5*cos(pitch/2);0;-.5*sin(pitch/2)];
    ml=[3 4 7 0 1 2];mt=[5 6 8 0];Al=zeros(6);Bl=zeros(6,2);At=zeros(4);Bt=zeros(4,2);
    for i=1:6
        fr=ml(i);if fr==0,Al(i,:)=[0 0 1 0 0 0];continue;end
        for j=1:6,fj=ml(j);if fj==0,z=A(:,9:12)*dt;Al(i,j)=z(fr);else,Al(i,j)=A(fr,fj);end,end
        Bl(i,:)=B(fr,[1 4]);
    end
    for i=1:4
        fr=mt(i);if fr==0,At(i,:)=[0 1 tan(pitch) 0];continue;end
        for j=1:4,fj=mt(j);if fj==0,z=A(:,9:12)*df;At(i,j)=z(fr);else,At(i,j)=A(fr,fj);end,end
        Bt(i,:)=B(fr,[2 3]);
    end
else
    e=[x(1:8);a;x(13:15)];A=jacobiano_fd(@(z)funciones_euler(0,z,u,p),e);B=jacobiano_fd(@(z)funciones_euler(0,e,z,p),u);
    il=[3 4 7 10 1 2];ia=[5 6 8 9];Al=A(il,il);Bl=B(il,[1 4]);At=A(ia,ia);Bt=B(ia,[2 3]);
end
c=struct('Alon',Al,'Blon',Bl,'Alat',At,'Blat',Bt,'polos_lon',eig(Al),'polos_lat',eig(At));
if act
    Aa=zeros(9);Ba=zeros(9,2);Aa(1:6,1:6)=Al;Ba(1:6,:)=Bl;Aa(7,2)=-x(3);Aa(7,4)=x(3);Aa(8,7)=1;Aa(9,1)=1;
    Q=diag([1,1/(2*pi/180)^2,1/(10*pi/180)^2,1/(5*pi/180)^2,1e-6,1e-6,1/5^2,1/50^2,1/30^2]);
    c.Klon=lqr_gain(Aa,Ba,w.q_lon*Q,w.r_lon*diag([1/5^2,1/.3^2]));
    Aa=zeros(6);Ba=zeros(6,2);Aa(1:4,1:4)=At;Ba(1:4,:)=Bt;Aa(5,3)=1/cos(a(2));Aa(6,5)=1;
    Q=diag([1/(pi/180)^2,1/(20*pi/180)^2,1/(10*pi/180)^2,1/(15*pi/180)^2,1/(5*pi/180)^2,1/(40*pi/180)^2]);
    c.Klat=lqr_gain(Aa,Ba,w.q_lat*Q,w.r_lat*diag([1/15^2,1/15^2]));
else
    c.Klon=lqr_gain(Al,Bl,w.q_lon*diag([1/2^2,1/(pi/180)^2,1/(5*pi/180)^2,1/(2*pi/180)^2,1e-6,1e-6]),w.r_lon*diag([1/5^2,1/.2^2]));
    c.Klat=lqr_gain(At,Bt,w.q_lat*diag([1/(.5*pi/180)^2,1/(10*pi/180)^2,1/(5*pi/180)^2,1/(5*pi/180)^2]),w.r_lat*diag([1/10^2,1/10^2]));
end
end
