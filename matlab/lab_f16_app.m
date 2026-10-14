function app=lab_f16_app(options)
% Punto de entrada adicional: no cambia los comandos de los README.
if nargin<1,options=struct;end
app=f16lab.App(options);
if nargout==0,clear app;end
end
