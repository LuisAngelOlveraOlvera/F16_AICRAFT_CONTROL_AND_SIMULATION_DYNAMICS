function c=setfield(c,key,value)
parts=strsplit(key,'.');assert(isfield(c,parts{1}),'lab:Campo','Campo desconocido.');
if numel(parts)==1,c.(parts{1})=value;
else,assert(numel(parts)==2&&isstruct(c.(parts{1}))&&isfield(c.(parts{1}),parts{2}),'lab:Campo','Campo desconocido.');c.(parts{1}).(parts{2})=value;end
end
