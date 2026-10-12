function plot_trayectoria3d(xE,yE,zE,titulo)
% PLOT_TRAYECTORIA3D  Trayectoria 3D en marco NED (altitud h = -zE).
%   plot_trayectoria3d(xE, yE, zE, 'titulo')
%   Colorea la trayectoria por tiempo, marca inicio (o verde) y fin (x roja)
%   y proyecta la sombra sobre el suelo para dar referencia de altura.
    h = -zE(:);
    x = xE(:); y = yE(:);
    n = numel(x);
    c = linspace(0,1,n)';
    % Trayectoria coloreada por tiempo (surface trick para linea con color)
    surface([x x],[y y],[h h],[c c], ...
            'FaceColor','none','EdgeColor','interp','LineWidth',1.8);
    hold on; grid on;
    % Sombra en el suelo (altura minima del tramo)
    h0 = min(h)-0.05*max(1,range(h));
    plot3(x,y,h0*ones(n,1),'Color',[.7 .7 .7],'LineWidth',0.8);
    plot3(x(1),y(1),h(1),'og','MarkerFaceColor','g','MarkerSize',8);
    plot3(x(end),y(end),h(end),'xr','LineWidth',2,'MarkerSize',10);
    xlabel('x_E [m]'); ylabel('y_E [m]'); zlabel('h [m]');
    if nargin>3, title(titulo); end
    view(-35,25); axis tight;
    cb=colorbar; ylabel(cb,'tiempo normalizado');
end
