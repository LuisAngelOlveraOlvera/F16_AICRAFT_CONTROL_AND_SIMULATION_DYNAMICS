function pairs=flat(c)
pairs=cell(0,2);names=fieldnames(c);
for i=1:numel(names)
    key=names{i};v=c.(key);
    if isstruct(v)
        sub=fieldnames(v);for j=1:numel(sub),pairs(end+1,:)={[key '.' sub{j}],v.(sub{j})};end %#ok<AGROW>
    else,pairs(end+1,:)={key,v};end %#ok<AGROW>
end
end
