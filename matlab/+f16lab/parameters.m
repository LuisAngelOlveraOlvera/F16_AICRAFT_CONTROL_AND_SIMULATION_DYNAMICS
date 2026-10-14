function p=parameters
persistent stored
if isempty(stored),r=validar_lewis(struct('mostrar',false));stored=r.theta;end
p=stored;
end
