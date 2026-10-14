function r=record(cfg,t,X,U,xt,ut,info,control,refs,G)
if nargin<9,refs=repmat([cfg.altitud cfg.VT 0],numel(t),1);end
if nargin<10,G=zeros(numel(t),3);end
r=struct('config',cfg,'theta',f16lab.parameters,'trim',info,'Xtrim',xt,'Utrim',ut,'control',control, ...
 't',t(:),'X',X,'U_comando',U,'U_acotado',min(max(U,[-25 -21.5 -30 0]),[25 21.5 30 1]), ...
 'U_real',U,'referencia',refs,'objetivo',refs,'rafaga_m_s',G);
act=size(X,2)==18;r.U_real=r.U_acotado;if act,r.U_real(:,1:3)=X(:,16:18);end
r=f16lab.observe(r,act,startsWith(cfg.escenario,'dryden'));
end
