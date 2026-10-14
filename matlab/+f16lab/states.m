function cursors=states(axes,r)
ix=unique(round(linspace(1,numel(r.t),min(2500,numel(r.t)))));t=r.t(ix);deg=180/pi;
data={r.altitud_m,r.X(:,3),r.X(:,4:5)*deg,r.angulos_rad(:,1:2)*deg,unwrap(r.angulos_rad(:,3))*deg,r.X(:,6:8)*deg,r.X(:,1),[r.X(:,2),r.LEF_deg],r.X(:,13:14)};
names={'Altitud','Velocidad','Ángulos aerodinámicos','Actitud','Rumbo','Tasas de giro','Potencia del motor','Filtro y deflexión LEF','Posición horizontal'};
units={'h [m]','VT [m/s]','[°]','[°]','ψ [°]','[°/s]','P3 [%]','[°]','[m]'};
labels={{'Real'},{'Real'},{'α','β'},{'φ','θ'},{'Real'},{'p','q','r'},{'P3'},{'α filtro','LEF'},{'Norte','Este'}};
cursors=gobjects(9,1);
for k=1:9
    ax=axes(k);cla(ax);hold(ax,'on');plot(ax,t,data{k}(ix,:),'LineWidth',1.15);legendText=labels{k};
    if any(k==[1 2 5])
        col=find([1 2 5]==k);ref=r.referencia(:,col);if k==5,ref=unwrap(ref)*deg;end
        plot(ax,t,ref(ix),':','Color',[.35 .4 .45]);legendText{end+1}='Referencia';
    elseif k==3&&isfield(r,'referencia_alfa_deg')
        plot(ax,t,r.referencia_alfa_deg(ix),':','Color',[.35 .4 .45]);legendText{end+1}='Referencia';
    end
    cursors(k)=xline(ax,r.t(1),'Color',[.35 .4 .45]);title(ax,names{k});ylabel(ax,units{k});grid(ax,'on');ax.FontSize=10;ax.YAxis.Exponent=0;
    if k>=7,xlabel(ax,'Tiempo [s]');end
    if numel(legendText)>1,legend(ax,legendText,'FontSize',8,'Location','best');end
    hold(ax,'off');
    children=findall(ax,'Type','line');set(children,'HitTest','off','PickableParts','none');
end
end
